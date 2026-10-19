const bookingService = require('./booking.service');
const { sendSuccess } = require('../../utils/response');

class BookingController {
    /**
     * Create an appointment booking (Authenticated owner or staff)
     * POST /api/v1/bookings
     */
    async create(req, res, next) {
        try {
            const result = await bookingService.createBooking({
                ownerId: req.user.id,
                data: req.body,
            });
            return sendSuccess(res, {
                statusCode: 201,
                message: 'Booking created successfully.',
                messageToShow: result.messageToShow,
                data: result.booking,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Public appointment booking by customer (No login required)
     * POST /api/v1/bookings/public/:businessSlug
     */
    async createPublic(req, res, next) {
        try {
            const result = await bookingService.createBooking({
                businessSlug: req.params.businessSlug || req.params.slug,
                data: req.body,
            });
            return sendSuccess(res, {
                statusCode: 201,
                message: 'Appointment booked successfully.',
                messageToShow: result.messageToShow,
                data: result.booking,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * List all bookings with date, staff, status filters
     * GET /api/v1/bookings
     */
    async getAll(req, res, next) {
        try {
            const result = await bookingService.getBookings(req.user.id, req.query);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Bookings retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.bookings,
                meta: { total: result.total },
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Get single booking by ID
     * GET /api/v1/bookings/:id
     */
    async getById(req, res, next) {
        try {
            const result = await bookingService.getBookingById(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Booking details retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.booking,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Public appointment lookup by booking reference code
     * GET /api/v1/bookings/ref/:bookingReference
     */
    async getByReference(req, res, next) {
        try {
            const result = await bookingService.getBookingByReference(req.params.bookingReference);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Booking reference retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.booking,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Public booked slots lookup for live calendar availability
     * GET /api/v1/bookings/public-slots/:businessId?date=YYYY-MM-DD
     */
    async getPublicBookedSlots(req, res, next) {
        try {
            const businessId = req.params.businessId;
            const dateStr = req.query.date;
            const result = await bookingService.getPublicBookedSlots(businessId, dateStr);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Occupied slots retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Update booking status (confirmed, completed, cancelled, noShow)
     * PATCH /api/v1/bookings/:id/status
     */
    async updateStatus(req, res, next) {
        try {
            const result = await bookingService.updateBookingStatus(req.user.id, req.params.id, req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Booking status updated successfully.',
                messageToShow: result.messageToShow,
                data: result.booking,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Reschedule appointment
     * PATCH /api/v1/bookings/:id/reschedule
     */
    async reschedule(req, res, next) {
        try {
            const result = await bookingService.rescheduleBooking(req.user?.id, req.params.id, req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Appointment rescheduled successfully.',
                messageToShow: result.messageToShow,
                data: result.booking,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Public cancellation by customer
     * PATCH /api/v1/bookings/public-cancel/:id
     */
    async cancelPublic(req, res, next) {
        try {
            const result = await bookingService.updateBookingStatus(null, req.params.id, {
                status: 'cancelled',
                cancellationReason: req.body?.cancellationReason || 'Cancelled by customer via online portal.',
            });
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Appointment cancelled successfully.',
                messageToShow: result.messageToShow,
                data: result.booking,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Delete booking
     * DELETE /api/v1/bookings/:id
     */
    async delete(req, res, next) {
        try {
            const result = await bookingService.deleteBooking(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Booking deleted successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new BookingController();
