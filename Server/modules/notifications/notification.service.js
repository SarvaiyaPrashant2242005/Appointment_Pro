const { UserFcmToken } = require('../users');
const { sendPushNotification, sendMulticastNotification, isFirebaseInitialized } = require('../../config/firebase');

class NotificationService {
    /**
     * Stores or updates an FCM token for a user.
     * If the token already exists in the database (e.g. from previous login or another account on same device),
     * it reassigns it to the current user and updates last_active_at.
     */
    async saveFcmToken(userId, { fcmToken, deviceType = 'android', deviceId = null }) {
        if (!fcmToken || !fcmToken.trim()) {
            const error = new Error('FCM token is required.');
            error.statusCode = 400;
            throw error;
        }

        const normalizedToken = fcmToken.trim();
        const normalizedDeviceType = (deviceType || 'android').trim().toLowerCase();

        // Check if token already exists
        const existing = await UserFcmToken.findOne({
            where: { fcm_token: normalizedToken },
        });

        if (existing) {
            await existing.update({
                user_id: userId,
                device_type: normalizedDeviceType,
                device_id: deviceId || existing.device_id,
                last_active_at: new Date(),
            });

            return {
                token: existing,
                messageToShow: 'FCM device token updated successfully.',
            };
        }

        const newToken = await UserFcmToken.create({
            user_id: userId,
            fcm_token: normalizedToken,
            device_type: normalizedDeviceType,
            device_id: deviceId,
            last_active_at: new Date(),
        });

        return {
            token: newToken,
            messageToShow: 'FCM device token registered successfully.',
        };
    }

    /**
     * Removes an FCM token when a user logs out or disables notifications.
     */
    async removeFcmToken(userId, fcmToken) {
        if (!fcmToken || !fcmToken.trim()) {
            const error = new Error('FCM token is required to unregister device.');
            error.statusCode = 400;
            throw error;
        }

        const normalizedToken = fcmToken.trim();
        const deletedCount = await UserFcmToken.destroy({
            where: {
                user_id: userId,
                fcm_token: normalizedToken,
            },
        });

        return {
            deletedCount,
            messageToShow: 'FCM device token removed successfully.',
        };
    }

    /**
     * Gets all active FCM tokens for a user.
     */
    async getUserTokens(userId) {
        const records = await UserFcmToken.findAll({
            where: { user_id: userId },
            attributes: ['id', 'fcm_token', 'device_type', 'device_id', 'last_active_at'],
            order: [['last_active_at', 'DESC']],
        });

        return records.map((r) => r.fcm_token);
    }

    /**
     * Sends a test push notification to all active devices of the user.
     */
    async sendTestNotification(userId, { title = 'AppointmentPro Test', body = 'Push notifications are working smoothly!' } = {}) {
        const tokens = await this.getUserTokens(userId);

        if (!tokens.length) {
            const error = new Error('No registered device tokens found for this account.');
            error.statusCode = 404;
            error.messageToShow = 'No registered devices found. Please log in or register your device token first.';
            throw error;
        }

        const result = await sendMulticastNotification({
            tokens,
            title,
            body,
            data: {
                type: 'test_notification',
                timestamp: new Date().toISOString(),
            },
        });

        return {
            deviceCount: tokens.length,
            result,
            messageToShow: `Test notification sent to ${tokens.length} device(s).`,
        };
    }

    /**
     * Sends a push notification to business owner when an appointment is booked, rescheduled, or cancelled.
     */
    async sendBookingNotification(userId, { booking, business, type = 'booking_created' }) {
        try {
            const tokens = await this.getUserTokens(userId);
            if (!tokens || !tokens.length) {
                console.log(`ℹ️ [FCM] No active device tokens found for user ${userId}. Skipping push notification.`);
                return null;
            }

            const raw = booking.toClientJSON ? booking.toClientJSON() : booking;
            const refCode = raw.bookingReference || raw.booking_reference || raw.id;
            const custName = raw.customerName || raw.customer_name || 'A customer';
            const srvName = raw.serviceName || raw.service_name || 'Appointment';

            let title = '📅 New Appointment Booked!';
            if (type === 'booking_rescheduled') title = '🔄 Appointment Rescheduled';
            if (type === 'booking_cancelled') title = '❌ Appointment Cancelled';

            const dateStr = new Date(raw.startAt || raw.start_at).toLocaleString('en-US', {
                weekday: 'short',
                month: 'short',
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
                hour12: true,
            });

            const body = `${custName} booked ${srvName} on ${dateStr}. Ref: ${refCode}`;

            const result = await sendMulticastNotification({
                tokens,
                title,
                body,
                data: {
                    type,
                    bookingId: String(refCode),
                    businessId: String(raw.businessId || raw.business_id || ''),
                    customerName: String(custName),
                    serviceName: String(srvName),
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
            });

            console.log(`✅ [FCM] Sent ${type} notification to user ${userId} on ${tokens.length} device(s)`);
            return result;
        } catch (err) {
            console.error('⚠️ [FCM] Push notification error:', err.message);
            return null;
        }
    }
}

module.exports = new NotificationService();
