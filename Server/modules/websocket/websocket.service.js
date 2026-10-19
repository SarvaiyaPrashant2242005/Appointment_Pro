const { WebSocketServer, WebSocket } = require('ws');
const url = require('url');

class WebSocketService {
    constructor() {
        this.wss = null;
        this.businessRooms = new Map(); // businessId -> Set of sockets
        this.pingInterval = null;
    }

    /**
     * Initialize WebSocket server on existing HTTP/HTTPS server
     */
    init(server, path = '/ws') {
        if (this.wss) {
            console.log('ℹ️ WebSocket server already initialized.');
            return this.wss;
        }

        this.wss = new WebSocketServer({ server, path });

        console.log(`🔌 WebSocket server initialized on path: ${path}`);

        this.wss.on('connection', (ws, req) => {
            ws.isAlive = true;
            ws.businessId = null;

            // Handle ping/pong for heartbeat
            ws.on('pong', () => {
                ws.isAlive = true;
            });

            // Parse optional query params: e.g. /ws?businessId=...&token=...
            try {
                const parsedUrl = url.parse(req.url, true);
                if (parsedUrl.query && parsedUrl.query.businessId) {
                    this.joinBusiness(ws, parsedUrl.query.businessId);
                }
            } catch (err) {
                // Ignore url parse errors
            }

            ws.on('message', (messageBuffer) => {
                try {
                    const message = JSON.parse(messageBuffer.toString());
                    this.handleClientMessage(ws, message);
                } catch (err) {
                    console.warn('⚠️ WebSocket JSON parse error:', err.message);
                }
            });

            ws.on('close', () => {
                this.leaveBusiness(ws);
            });

            ws.on('error', (err) => {
                console.warn('⚠️ WebSocket client error:', err.message);
                this.leaveBusiness(ws);
            });

            // Send initial connection ack
            this.sendToSocket(ws, {
                event: 'connection:established',
                data: {
                    message: 'Connected to AppointmentPro Live WebSocket',
                    timestamp: new Date().toISOString(),
                },
            });
        });

        // Setup ping/pong heartbeat interval (every 30 seconds)
        this.pingInterval = setInterval(() => {
            if (!this.wss) return;
            this.wss.clients.forEach((ws) => {
                if (ws.isAlive === false) {
                    this.leaveBusiness(ws);
                    return ws.terminate();
                }
                ws.isAlive = false;
                ws.ping();
            });
        }, 30000);

        this.wss.on('close', () => {
            if (this.pingInterval) clearInterval(this.pingInterval);
        });

        return this.wss;
    }

    /**
     * Handle incoming messages from client
     */
    handleClientMessage(ws, message) {
        if (!message || !message.type) return;

        switch (message.type) {
            case 'ping':
                this.sendToSocket(ws, { type: 'pong', timestamp: new Date().toISOString() });
                break;

            case 'join_business':
                if (message.businessId) {
                    this.joinBusiness(ws, message.businessId);
                    this.sendToSocket(ws, {
                        event: 'business:joined',
                        businessId: message.businessId,
                        message: `Subscribed to live booking events for business: ${message.businessId}`,
                    });
                }
                break;

            case 'leave_business':
                this.leaveBusiness(ws);
                break;

            default:
                break;
        }
    }

    /**
     * Associate a socket with a business room
     */
    joinBusiness(ws, businessId) {
        if (!businessId) return;
        const cleanId = String(businessId).trim();

        // If previously in a different business room, leave it first
        if (ws.businessId && ws.businessId !== cleanId) {
            this.leaveBusiness(ws);
        }

        ws.businessId = cleanId;

        if (!this.businessRooms.has(cleanId)) {
            this.businessRooms.set(cleanId, new Set());
        }

        this.businessRooms.get(cleanId).add(ws);
        console.log(`📡 WebSocket client joined business ${cleanId} (Total in room: ${this.businessRooms.get(cleanId).size})`);
    }

    /**
     * Remove socket from business room
     */
    leaveBusiness(ws) {
        if (ws.businessId && this.businessRooms.has(ws.businessId)) {
            const room = this.businessRooms.get(ws.businessId);
            room.delete(ws);
            if (room.size === 0) {
                this.businessRooms.delete(ws.businessId);
            }
            ws.businessId = null;
        }
    }

    /**
     * Send payload to a single socket
     */
    sendToSocket(ws, payload) {
        if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify(payload));
        }
    }

    /**
     * Broadcast to all clients in a specific business room
     */
    broadcastToBusiness(businessId, payload) {
        if (!businessId) return;
        const cleanId = String(businessId).trim();
        const room = this.businessRooms.get(cleanId);

        if (!room || room.size === 0) {
            return;
        }

        const jsonStr = JSON.stringify(payload);
        let deliveredCount = 0;

        room.forEach((ws) => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send(jsonStr);
                deliveredCount++;
            }
        });

        console.log(`📢 [WebSocket] Broadcasted "${payload.event}" to business ${cleanId} (${deliveredCount} client(s))`);
    }

    /**
     * Helper to broadcast booking lifecycle events
     * @param {'booking:created' | 'booking:updated' | 'booking:rescheduled' | 'booking:cancelled' | 'booking:deleted'} event
     * @param {Object} booking Sequelize model or raw object
     * @param {Object} meta Extra metadata (e.g. status, slot info)
     */
    broadcastBookingEvent(event, booking, meta = {}) {
        if (!booking) return;

        const businessId = booking.business_id || booking.businessId || booking.business?.id;
        if (!businessId) return;

        const bookingJson = (typeof booking.toClientJSON === 'function')
            ? booking.toClientJSON()
            : (booking.toJSON ? booking.toJSON() : booking);

        const payload = {
            event,
            businessId: String(businessId),
            data: {
                booking: bookingJson,
                bookingId: bookingJson.id,
                bookingReference: bookingJson.bookingReference || bookingJson.booking_reference,
                status: bookingJson.status,
                slot: {
                    startAt: bookingJson.startAt || bookingJson.start_at,
                    endAt: bookingJson.endAt || bookingJson.end_at,
                    staffId: bookingJson.staffId || bookingJson.staff_id,
                    serviceId: bookingJson.serviceId || bookingJson.service_id,
                },
                ...meta,
            },
            timestamp: new Date().toISOString(),
        };

        this.broadcastToBusiness(businessId, payload);
    }
}

module.exports = new WebSocketService();
