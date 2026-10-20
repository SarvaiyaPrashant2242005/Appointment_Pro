const { WebSocketServer, WebSocket } = require('ws');
const url = require('url');

class WebSocketService {
    constructor() {
        this.wss = null;
        this.businessRooms = new Map(); // businessId/slug -> Set of sockets
        this.idToSlugMap = new Map();   // uuid -> slug
        this.slugToIdMap = new Map();   // slug -> uuid
        this.pingInterval = null;
    }

    /**
     * Map a business UUID to its human-readable slug and vice versa
     */
    registerBusinessMapping(businessId, slug) {
        if (!businessId || !slug) return;
        const cleanId = String(businessId).trim().toLowerCase();
        const cleanSlug = String(slug).trim().toLowerCase();

        this.idToSlugMap.set(cleanId, cleanSlug);
        this.slugToIdMap.set(cleanSlug, cleanId);

        // Sync existing room sockets across both identifiers
        const idSockets = this.businessRooms.get(cleanId);
        const slugSockets = this.businessRooms.get(cleanSlug);

        if (idSockets && idSockets.size > 0) {
            idSockets.forEach((ws) => this.joinBusiness(ws, cleanSlug));
        }
        if (slugSockets && slugSockets.size > 0) {
            slugSockets.forEach((ws) => this.joinBusiness(ws, cleanId));
        }
    }

    /**
     * Initialize WebSocket server on existing HTTP/HTTPS server
     */
    init(server, path = '/ws') {
        if (this.wss) {
            console.log('ℹ️ WebSocket server already initialized.');
            return this.wss;
        }

        // Initialize with noServer to allow robust path and query matching behind reverse proxies
        this.wss = new WebSocketServer({ noServer: true });

        console.log(`🔌 WebSocket server initialized on path prefix: ${path}`);

        server.on('upgrade', (request, socket, head) => {
            const pathname = url.parse(request.url).pathname;
            // Match /ws, /ws/, /ws?businessId=..., etc.
            if (pathname === '/ws' || pathname === '/ws/' || (pathname && pathname.startsWith('/ws'))) {
                this.wss.handleUpgrade(request, socket, head, (ws) => {
                    this.wss.emit('connection', ws, request);
                });
            }
        });

        this.wss.on('connection', (ws, req) => {
            ws.isAlive = true;
            ws.missedPings = 0;
            ws.joinedRooms = new Set();

            // Native pong handler
            ws.on('pong', () => {
                ws.isAlive = true;
                ws.missedPings = 0;
            });

            // Parse query params: e.g. /ws?businessId=...&slug=...
            try {
                const parsedUrl = url.parse(req.url, true);
                const queryBizId = parsedUrl.query?.businessId || parsedUrl.query?.business_id || parsedUrl.query?.slug;
                if (queryBizId) {
                    this.joinBusiness(ws, queryBizId);
                }
            } catch (err) {
                // Ignore url parse errors
            }

            ws.on('message', (messageBuffer) => {
                ws.isAlive = true;
                ws.missedPings = 0;
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

        // Setup ping heartbeat (every 20 seconds, well within Cloudflare 100s timeout)
        this.pingInterval = setInterval(() => {
            if (!this.wss) return;
            this.wss.clients.forEach((ws) => {
                if (ws.missedPings >= 3) {
                    this.leaveBusiness(ws);
                    return ws.terminate();
                }
                ws.missedPings = (ws.missedPings || 0) + 1;
                try {
                    ws.ping();
                } catch (_) {}
            });
        }, 20000);

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
        ws.isAlive = true;
        ws.missedPings = 0;

        switch (message.type) {
            case 'ping':
                this.sendToSocket(ws, { type: 'pong', timestamp: new Date().toISOString() });
                break;

            case 'pong':
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
     * Associate a socket with a business room (supports both UUID and slug)
     */
    joinBusiness(ws, businessId) {
        if (!businessId) return;
        const cleanId = String(businessId).trim();
        const lowerId = cleanId.toLowerCase();

        ws.joinedRooms = ws.joinedRooms || new Set();
        ws.joinedRooms.add(cleanId);
        ws.joinedRooms.add(lowerId);

        [cleanId, lowerId].forEach((key) => {
            if (!this.businessRooms.has(key)) {
                this.businessRooms.set(key, new Set());
            }
            this.businessRooms.get(key).add(ws);
        });

        // If mapped to counterpart slug or id, also subscribe automatically
        if (this.idToSlugMap.has(lowerId)) {
            const mappedSlug = this.idToSlugMap.get(lowerId);
            if (!ws.joinedRooms.has(mappedSlug)) {
                ws.joinedRooms.add(mappedSlug);
                if (!this.businessRooms.has(mappedSlug)) {
                    this.businessRooms.set(mappedSlug, new Set());
                }
                this.businessRooms.get(mappedSlug).add(ws);
            }
        } else if (this.slugToIdMap.has(lowerId)) {
            const mappedId = this.slugToIdMap.get(lowerId);
            if (!ws.joinedRooms.has(mappedId)) {
                ws.joinedRooms.add(mappedId);
                if (!this.businessRooms.has(mappedId)) {
                    this.businessRooms.set(mappedId, new Set());
                }
                this.businessRooms.get(mappedId).add(ws);
            }
        }

        console.log(`📡 WebSocket client joined business room: ${cleanId} (Clients in room: ${this.businessRooms.get(cleanId).size})`);
    }

    /**
     * Remove socket from all business rooms
     */
    leaveBusiness(ws) {
        if (ws.joinedRooms && ws.joinedRooms.size > 0) {
            ws.joinedRooms.forEach((roomKey) => {
                if (this.businessRooms.has(roomKey)) {
                    const room = this.businessRooms.get(roomKey);
                    room.delete(ws);
                    if (room.size === 0) {
                        this.businessRooms.delete(roomKey);
                    }
                }
            });
            ws.joinedRooms.clear();
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
        const keys = [String(businessId).trim(), String(businessId).trim().toLowerCase()];
        const targetSockets = new Set();

        keys.forEach((key) => {
            const room = this.businessRooms.get(key);
            if (room && room.size > 0) {
                room.forEach((ws) => targetSockets.add(ws));
            }
        });

        if (targetSockets.size === 0) {
            return;
        }

        const jsonStr = JSON.stringify(payload);
        let deliveredCount = 0;

        targetSockets.forEach((ws) => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send(jsonStr);
                deliveredCount++;
            }
        });

        console.log(`📡 [WebSocket] Broadcasted "${payload.event}" to business ${businessId} (${deliveredCount} client(s))`);
    }

    /**
     * Helper to broadcast booking lifecycle events
     * Broadcasts to both business UUID and slug so mobile app and web clients receive it
     */
    broadcastBookingEvent(event, booking, meta = {}) {
        if (!booking) return;

        let businessId = booking.business_id || booking.businessId || booking.business?.id || meta.businessId;
        let businessSlug = booking.business?.slug || meta.businessSlug || (booking.toClientJSON ? booking.toClientJSON().businessSlug : null);

        // Auto-resolve slug from ID or ID from slug
        if (!businessSlug && businessId && this.idToSlugMap.has(String(businessId).toLowerCase())) {
            businessSlug = this.idToSlugMap.get(String(businessId).toLowerCase());
        }
        if (!businessId && businessSlug && this.slugToIdMap.has(String(businessSlug).toLowerCase())) {
            businessId = this.slugToIdMap.get(String(businessSlug).toLowerCase());
        }

        if (!businessId && !businessSlug) return;

        const bookingJson = (typeof booking.toClientJSON === 'function')
            ? booking.toClientJSON()
            : (booking.toJSON ? booking.toJSON() : booking);

        const payload = {
            event,
            businessId: String(businessId || ''),
            businessSlug: businessSlug ? String(businessSlug) : undefined,
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

        if (businessId) {
            this.broadcastToBusiness(businessId, payload);
        }
        if (businessSlug && String(businessSlug).toLowerCase() !== String(businessId).toLowerCase()) {
            this.broadcastToBusiness(businessSlug, payload);
        }
    }
}

module.exports = new WebSocketService();
