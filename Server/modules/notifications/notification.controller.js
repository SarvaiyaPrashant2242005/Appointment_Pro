const notificationService = require('./notification.service');
const { sendSuccess } = require('../../utils/response');

class NotificationController {
    /**
     * Store or update an FCM token
     * POST /api/v1/notifications/fcm-token
     */
    async saveToken(req, res, next) {
        try {
            const { fcmToken, fcm_token, deviceType, device_type, deviceId, device_id } = req.body;
            const token = fcmToken || fcm_token;

            const result = await notificationService.saveFcmToken(req.user.id, {
                fcmToken: token,
                deviceType: deviceType || device_type || 'android',
                deviceId: deviceId || device_id || null,
            });

            return sendSuccess(res, {
                statusCode: 200,
                message: 'FCM device token saved successfully.',
                messageToShow: result.messageToShow,
                data: result.token,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Remove an FCM token (e.g. on logout)
     * DELETE /api/v1/notifications/fcm-token
     */
    async removeToken(req, res, next) {
        try {
            const token = req.body.fcmToken || req.body.fcm_token || req.query.fcmToken || req.query.fcm_token;
            const result = await notificationService.removeFcmToken(req.user.id, token);

            return sendSuccess(res, {
                statusCode: 200,
                message: 'FCM device token removed successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Send a test push notification to user's registered devices
     * POST /api/v1/notifications/send-test
     */
    async sendTest(req, res, next) {
        try {
            const { title, body } = req.body;
            const result = await notificationService.sendTestNotification(req.user.id, { title, body });

            return sendSuccess(res, {
                statusCode: 200,
                message: 'Test notification sent.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new NotificationController();
