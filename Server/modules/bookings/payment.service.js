const { Op } = require('sequelize');
const { Payment, Booking, Customer } = require('./index');
const { Business, BusinessMember } = require('../businesses');

class PaymentService {
    /**
     * Record a payment for a booking
     */
    async createPayment(ownerId, data) {
        const bookingId = data.bookingId || data.booking_id;
        const booking = await Booking.findByPk(bookingId, {
            include: [{ model: Business, as: 'business', attributes: ['id', 'owner_id', 'name', 'currency'] }],
        });

        if (!booking) {
            const error = new Error('Booking not found.');
            error.statusCode = 404;
            error.messageToShow = 'The appointment for this payment could not be found.';
            throw error;
        }

        if (booking.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to record payments for this business.';
            throw error;
        }

        const amount = data.amount !== undefined ? parseFloat(data.amount) : parseFloat(booking.price);
        const method = data.method || 'cash';
        const status = data.status || 'completed';
        const transaction_reference = data.transactionReference || data.transaction_reference || null;
        const paid_at = data.paidAt || data.paid_at ? new Date(data.paidAt || data.paid_at) : new Date();

        const payment = await Payment.create({
            business_id: booking.business_id,
            booking_id: booking.id,
            customer_id: booking.customer_id,
            amount,
            method,
            status,
            transaction_reference,
            paid_at,
        });

        return {
            payment: payment.toClientJSON(),
            messageToShow: `Payment of ${booking.business?.currency || 'INR'} ${amount} recorded successfully via ${method.toUpperCase()}.`,
        };
    }

    /**
     * Get all payments for business
     */
    async getPayments(ownerId, query = {}) {
        const requestedBusinessId = query.businessId || query.business_id;
        const whereClause = {};

        if (requestedBusinessId) {
            const business = await Business.findOne({ where: { id: requestedBusinessId } });
            if (!business || business.owner_id !== ownerId) {
                const error = new Error('Unauthorized.');
                error.statusCode = 403;
                error.messageToShow = 'You do not have permission to view payments for this business.';
                throw error;
            }
            whereClause.business_id = business.id;
        } else {
            const userBusinesses = await Business.findAll({
                where: { owner_id: ownerId },
                attributes: ['id'],
            });
            const businessIds = userBusinesses.map((b) => b.id);
            whereClause.business_id = { [Op.in]: businessIds };
        }

        const bookingId = query.bookingId || query.booking_id;
        if (bookingId) whereClause.booking_id = bookingId;

        const customerId = query.customerId || query.customer_id;
        if (customerId) whereClause.customer_id = customerId;

        if (query.method) whereClause.method = query.method;
        if (query.status) whereClause.status = query.status;

        const payments = await Payment.findAll({
            where: whereClause,
            order: [['paid_at', 'DESC']],
            include: [
                { model: Booking, as: 'booking', attributes: ['id', 'booking_reference', 'service_name', 'customer_name'] },
                { model: Customer, as: 'customer', attributes: ['id', 'name', 'phone'] },
            ],
        });

        const totalRevenue = payments
            .filter((p) => p.status === 'completed')
            .reduce((sum, p) => sum + parseFloat(p.amount), 0);

        return {
            payments: payments.map((p) => p.toClientJSON()),
            total: payments.length,
            totalRevenue,
            messageToShow: payments.length > 0
                ? 'Payment records retrieved successfully.'
                : 'No payments found matching your criteria.',
        };
    }

    /**
     * Get single payment by ID
     */
    async getPaymentById(ownerId, paymentId) {
        const payment = await Payment.findByPk(paymentId, {
            include: [
                { model: Business, as: 'business', attributes: ['id', 'owner_id', 'name', 'currency'] },
                { model: Booking, as: 'booking' },
                { model: Customer, as: 'customer' },
            ],
        });

        if (!payment) {
            const error = new Error('Payment not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested payment transaction could not be found.';
            throw error;
        }

        if (payment.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to view this payment.';
            throw error;
        }

        return {
            payment: payment.toClientJSON(),
            messageToShow: 'Payment transaction loaded successfully.',
        };
    }

    /**
     * Update payment status
     */
    async updatePaymentStatus(ownerId, paymentId, status) {
        const payment = await Payment.findByPk(paymentId, {
            include: [{ model: Business, as: 'business', attributes: ['id', 'owner_id', 'name'] }],
        });

        if (!payment) {
            const error = new Error('Payment not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested payment could not be found.';
            throw error;
        }

        if (payment.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to update this payment.';
            throw error;
        }

        await payment.update({ status });

        return {
            payment: payment.toClientJSON(),
            messageToShow: `Payment status updated to "${status}".`,
        };
    }
}

module.exports = new PaymentService();
