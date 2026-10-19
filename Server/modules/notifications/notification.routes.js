const express = require('express');
const router = express.Router();

const notificationController = require('./notification.controller');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const {
    saveFcmTokenSchema,
    removeFcmTokenSchema,
    sendTestNotificationSchema,
} = require('./notification.validator');

// All notification endpoints require user authentication
router.use(authenticate);

// Store or refresh FCM device token
router.post(
    '/fcm-token',
    validate(saveFcmTokenSchema),
    notificationController.saveToken
);

// Unregister FCM device token
router.delete(
    '/fcm-token',
    validate(removeFcmTokenSchema),
    notificationController.removeToken
);

// Send test push notification
router.post(
    '/send-test',
    validate(sendTestNotificationSchema),
    notificationController.sendTest
);

module.exports = router;
