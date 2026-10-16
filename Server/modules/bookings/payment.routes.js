const express = require('express');
const router = express.Router();

const paymentController = require('./payment.controller');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const {
    createPaymentSchema,
    updatePaymentStatusSchema,
    paymentIdParamSchema,
    listPaymentsQuerySchema,
} = require('../../validators/payment.validator');

router.use(authenticate);

// 1. Record payment for a booking
router.post(
    '/',
    validate(createPaymentSchema),
    paymentController.create
);

// 2. List payments with filters & revenue aggregation
router.get(
    '/',
    validate(listPaymentsQuerySchema, 'query'),
    paymentController.getAll
);

// 3. Get payment details by ID
router.get(
    '/:id',
    validate(paymentIdParamSchema, 'params'),
    paymentController.getById
);

// 4. Update payment status (e.g. refunded, failed)
router.patch(
    '/:id/status',
    validate(paymentIdParamSchema, 'params'),
    validate(updatePaymentStatusSchema),
    paymentController.updateStatus
);

module.exports = router;
