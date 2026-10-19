const Joi = require('joi');

const saveFcmTokenSchema = Joi.object({
    fcmToken: Joi.string().trim().optional(),
    fcm_token: Joi.string().trim().optional(),
    deviceType: Joi.string().trim().max(50).allow('', null).optional(),
    device_type: Joi.string().trim().max(50).allow('', null).optional(),
    deviceId: Joi.string().trim().max(100).allow('', null).optional(),
    device_id: Joi.string().trim().max(100).allow('', null).optional(),
}).or('fcmToken', 'fcm_token').messages({
    'object.missing': 'fcmToken is required.',
});

const removeFcmTokenSchema = Joi.object({
    fcmToken: Joi.string().trim().optional(),
    fcm_token: Joi.string().trim().optional(),
}).or('fcmToken', 'fcm_token').messages({
    'object.missing': 'fcmToken is required to unregister device.',
});

const sendTestNotificationSchema = Joi.object({
    title: Joi.string().trim().max(100).allow('', null).optional(),
    body: Joi.string().trim().max(255).allow('', null).optional(),
});

module.exports = {
    saveFcmTokenSchema,
    removeFcmTokenSchema,
    sendTestNotificationSchema,
};
