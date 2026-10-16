const Joi = require('joi');

const createBookingSchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
    serviceId: Joi.string().trim().required().messages({
        'string.empty': 'Please select a service for the booking.',
        'any.required': 'Service selection is required.',
    }),
    staffId: Joi.string().trim().allow(null, '').optional(),
    staff_id: Joi.string().trim().allow(null, '').optional(),

    customerName: Joi.string().trim().min(2).max(255).required().messages({
        'string.empty': 'Customer name is required.',
        'string.min': 'Customer name must be at least 2 characters long.',
        'any.required': 'Customer name is required.',
    }),
    customerCountryCode: Joi.string().trim().max(10).default('+91').optional(),
    customer_country_code: Joi.string().trim().max(10).default('+91').optional(),

    customerPhone: Joi.string().trim().min(7).max(20).required().messages({
        'string.empty': 'Customer phone number is required.',
        'string.min': 'Please enter a valid phone number.',
        'any.required': 'Customer phone number is required.',
    }),
    customer_phone: Joi.string().trim().min(7).max(20).optional(),

    customerEmail: Joi.string().trim().email().allow('', null).optional().messages({
        'string.email': 'Please enter a valid email address.',
    }),
    customer_email: Joi.string().trim().email().allow('', null).optional(),

    customerNotes: Joi.string().trim().allow('', null).optional(),
    customer_notes: Joi.string().trim().allow('', null).optional(),

    startAt: Joi.date().iso().required().messages({
        'date.base': 'Please select a valid booking date and time.',
        'any.required': 'Booking start time is required.',
    }),
    start_at: Joi.date().iso().optional(),

    endAt: Joi.date().iso().optional(),
    end_at: Joi.date().iso().optional(),

    price: Joi.number().min(0).optional(),
});

const publicBookingSchema = Joi.object({
    serviceId: Joi.string().trim().required().messages({
        'string.empty': 'Please select a service for your appointment.',
        'any.required': 'Service selection is required.',
    }),
    service_id: Joi.string().trim().optional(),

    staffId: Joi.string().trim().allow(null, '').optional(),
    staff_id: Joi.string().trim().allow(null, '').optional(),

    customerName: Joi.string().trim().min(2).max(255).required().messages({
        'string.empty': 'Your name is required.',
        'string.min': 'Name must be at least 2 characters long.',
        'any.required': 'Your name is required.',
    }),
    customerCountryCode: Joi.string().trim().max(10).default('+91').optional(),
    customer_country_code: Joi.string().trim().max(10).default('+91').optional(),

    customerPhone: Joi.string().trim().min(7).max(20).required().messages({
        'string.empty': 'Your phone number is required.',
        'string.min': 'Please enter a valid phone number.',
        'any.required': 'Your phone number is required.',
    }),
    customer_phone: Joi.string().trim().min(7).max(20).optional(),

    customerEmail: Joi.string().trim().email().allow('', null).optional().messages({
        'string.email': 'Please enter a valid email address.',
    }),
    customer_email: Joi.string().trim().email().allow('', null).optional(),

    customerNotes: Joi.string().trim().allow('', null).optional(),
    customer_notes: Joi.string().trim().allow('', null).optional(),

    startAt: Joi.date().iso().required().messages({
        'date.base': 'Please select an appointment time slot.',
        'any.required': 'Appointment time is required.',
    }),
    start_at: Joi.date().iso().optional(),
});

const updateBookingStatusSchema = Joi.object({
    status: Joi.string().valid('confirmed', 'completed', 'cancelled', 'noShow').required().messages({
        'any.only': 'Status must be one of: confirmed, completed, cancelled, noShow.',
        'any.required': 'Booking status is required.',
    }),
    cancellationReason: Joi.string().trim().allow('', null).optional(),
    cancellation_reason: Joi.string().trim().allow('', null).optional(),
});

const rescheduleBookingSchema = Joi.object({
    newStartAt: Joi.date().iso().required().messages({
        'date.base': 'Please provide a valid new start date and time.',
        'any.required': 'New start time is required for rescheduling.',
    }),
    new_start_at: Joi.date().iso().optional(),

    newEndAt: Joi.date().iso().optional(),
    new_end_at: Joi.date().iso().optional(),

    newStaffId: Joi.string().trim().allow(null, '').optional(),
    new_staff_id: Joi.string().trim().allow(null, '').optional(),

    reason: Joi.string().trim().allow('', null).optional(),
});

const bookingIdParamSchema = Joi.object({
    id: Joi.string().trim().required().messages({
        'string.empty': 'Booking ID is required.',
        'any.required': 'Booking ID is required in URL parameters.',
    }),
});

const bookingRefParamSchema = Joi.object({
    bookingReference: Joi.string().trim().required().messages({
        'string.empty': 'Booking reference is required.',
        'any.required': 'Booking reference is required in URL parameters.',
    }),
});

const publicBusinessSlugParamSchema = Joi.object({
    businessSlug: Joi.string().trim().optional(),
    slug: Joi.string().trim().optional(),
}).or('businessSlug', 'slug').messages({
    'object.missing': 'Business slug is required in URL parameters.',
});

const listBookingsQuerySchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
    status: Joi.string().trim().optional(),
    startDate: Joi.date().iso().optional(),
    start_date: Joi.date().iso().optional(),
    endDate: Joi.date().iso().optional(),
    end_date: Joi.date().iso().optional(),
    staffId: Joi.string().trim().optional(),
    staff_id: Joi.string().trim().optional(),
    customerId: Joi.string().trim().optional(),
    customer_id: Joi.string().trim().optional(),
    search: Joi.string().trim().optional(),
});

module.exports = {
    createBookingSchema,
    publicBookingSchema,
    updateBookingStatusSchema,
    rescheduleBookingSchema,
    bookingIdParamSchema,
    bookingRefParamSchema,
    publicBusinessSlugParamSchema,
    listBookingsQuerySchema,
};
