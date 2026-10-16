const paymentService = require('./payment.service');
const { sendSuccess } = require('../../utils/response');

class PaymentController {
    /**
     * Record a payment
     * POST /api/v1/payments
     */
    async create(req, res, next) {
        try {
            const result = await paymentService.createPayment(req.user.id, req.body);
            return sendSuccess(res, {
                statusCode: 201,
                message: 'Payment recorded successfully.',
                messageToShow: result.messageToShow,
                data: result.payment,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * List payments with revenue aggregation
     * GET /api/v1/payments
     */
    async getAll(req, res, next) {
        try {
            const result = await paymentService.getPayments(req.user.id, req.query);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Payments retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.payments,
                meta: {
                    total: result.total,
                    totalRevenue: result.totalRevenue,
                },
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Get single payment by ID
     * GET /api/v1/payments/:id
     */
    async getById(req, res, next) {
        try {
            const result = await paymentService.getPaymentById(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Payment details retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.payment,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Update payment status (e.g. refunded, completed)
     * PATCH /api/v1/payments/:id/status
     */
    async updateStatus(req, res, next) {
        try {
            const result = await paymentService.updatePaymentStatus(req.user.id, req.params.id, req.body.status);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Payment status updated successfully.',
                messageToShow: result.messageToShow,
                data: result.payment,
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new PaymentController();
