const Joi = require('joi');

const createPaymentSchema = Joi.object({
    bookingId: Joi.string().trim().required().messages({
        'string.empty': 'Booking ID is required to record a payment.',
        'any.required': 'Booking ID is required.',
    }),
    booking_id: Joi.string().trim().optional(),

    amount: Joi.number().min(0).required().messages({
        'number.base': 'Please enter a valid payment amount.',
        'number.min': 'Payment amount cannot be negative.',
        'any.required': 'Payment amount is required.',
    }),

    method: Joi.string().valid('cash', 'upi', 'card', 'online', 'bank_transfer', 'other').default('cash').messages({
        'any.only': 'Payment method must be one of: cash, upi, card, online, bank_transfer, other.',
    }),

    status: Joi.string().valid('pending', 'completed', 'refunded', 'failed').default('completed').messages({
        'any.only': 'Payment status must be one of: pending, completed, refunded, failed.',
    }),

    transactionReference: Joi.string().trim().allow('', null).optional(),
    transaction_reference: Joi.string().trim().allow('', null).optional(),

    paidAt: Joi.date().iso().optional(),
    paid_at: Joi.date().iso().optional(),
});

const updatePaymentStatusSchema = Joi.object({
    status: Joi.string().valid('pending', 'completed', 'refunded', 'failed').required().messages({
        'any.only': 'Payment status must be one of: pending, completed, refunded, failed.',
        'any.required': 'Status is required.',
    }),
});

const paymentIdParamSchema = Joi.object({
    id: Joi.string().trim().required().messages({
        'string.empty': 'Payment ID is required.',
        'any.required': 'Payment ID is required in URL parameters.',
    }),
});

const listPaymentsQuerySchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
    bookingId: Joi.string().trim().optional(),
    booking_id: Joi.string().trim().optional(),
    customerId: Joi.string().trim().optional(),
    customer_id: Joi.string().trim().optional(),
    method: Joi.string().trim().optional(),
    status: Joi.string().trim().optional(),
});

module.exports = {
    createPaymentSchema,
    updatePaymentStatusSchema,
    paymentIdParamSchema,
    listPaymentsQuerySchema,
};
