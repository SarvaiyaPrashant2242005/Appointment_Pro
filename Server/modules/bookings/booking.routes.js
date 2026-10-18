const express = require('express');
const router = express.Router();

const bookingController = require('./booking.controller');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const {
    createBookingSchema,
    publicBookingSchema,
    updateBookingStatusSchema,
    rescheduleBookingSchema,
    bookingIdParamSchema,
    bookingRefParamSchema,
    publicBusinessSlugParamSchema,
    listBookingsQuerySchema,
} = require('../../validators/booking.validator');

// 1. Public customer appointment booking (No authentication required)
router.post(
    '/public/:businessSlug',
    validate(publicBusinessSlugParamSchema, 'params'),
    validate(publicBookingSchema),
    bookingController.createPublic
);

// 2. Public lookup by booking reference code (e.g. AP-849201)
router.get(
    '/ref/:bookingReference',
    validate(bookingRefParamSchema, 'params'),
    bookingController.getByReference
);

// 3. Public customer reschedule via booking reference / ID
router.patch(
    '/public-reschedule/:id',
    validate(bookingIdParamSchema, 'params'),
    validate(rescheduleBookingSchema),
    bookingController.reschedule
);

// 4. Public customer cancellation via booking reference / ID
router.patch(
    '/public-cancel/:id',
    validate(bookingIdParamSchema, 'params'),
    bookingController.cancelPublic
);

// 5. Public booked slots for a business and date (for live availability calendar)
router.get(
    '/public-slots/:businessId',
    bookingController.getPublicBookedSlots
);

// All subsequent routes require user authentication
router.use(authenticate);

// 4. Create appointment booking
router.post(
    '/',
    validate(createBookingSchema),
    bookingController.create
);

// 5. List bookings with date, staff, status filters
router.get(
    '/',
    validate(listBookingsQuerySchema, 'query'),
    bookingController.getAll
);

// 6. Get single booking by ID
router.get(
    '/:id',
    validate(bookingIdParamSchema, 'params'),
    bookingController.getById
);

// 7. Update booking status (confirmed, completed, cancelled, noShow)
router.patch(
    '/:id/status',
    validate(bookingIdParamSchema, 'params'),
    validate(updateBookingStatusSchema),
    bookingController.updateStatus
);

// 8. Reschedule appointment (audit logged in booking_reschedules)
router.patch(
    '/:id/reschedule',
    validate(bookingIdParamSchema, 'params'),
    validate(rescheduleBookingSchema),
    bookingController.reschedule
);

// 9. Delete booking
router.delete(
    '/:id',
    validate(bookingIdParamSchema, 'params'),
    bookingController.delete
);

module.exports = router;
