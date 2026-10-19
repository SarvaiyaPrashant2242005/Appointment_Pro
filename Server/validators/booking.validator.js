const Joi = require('joi');

/**
 * Validate and clean phone number based on customerCountryCode
 */
const validatePhoneByCountry = (value, helpers) => {
    if (!value) return value;
    const parent = helpers.state.ancestors[0] || {};
    const countryCode = (parent.customerCountryCode || parent.customer_country_code || '+91').trim();
    const digits = String(value).replace(/\D/g, '');

    if (countryCode === '+91') {
        if (digits.length !== 10) {
            return helpers.message('Indian mobile number (+91) must be exactly 10 digits.');
        }
        if (!/^[6-9]/.test(digits)) {
            return helpers.message('Indian mobile number (+91) must start with 6, 7, 8, or 9.');
        }
    } else if (countryCode === '+1') {
        if (digits.length !== 10) {
            return helpers.message('North American phone number (+1) must be exactly 10 digits.');
        }
        if (!/^[2-9]/.test(digits)) {
            return helpers.message('North American phone number (+1) cannot start with 0 or 1.');
        }
    } else if (countryCode === '+971') {
        if (!/^\d{9}$/.test(digits)) {
            return helpers.message('UAE mobile number (+971) must be exactly 9 digits.');
        }
    } else if (countryCode === '+65') {
        if (!/^[89]\d{7}$/.test(digits)) {
            return helpers.message('Singapore mobile number (+65) must be 8 digits starting with 8 or 9.');
        }
    } else if (countryCode === '+44') {
        if (!/^\d{10,11}$/.test(digits)) {
            return helpers.message('UK phone number (+44) must be 10 or 11 digits.');
        }
    } else if (countryCode === '+61') {
        if (!/^\d{9,10}$/.test(digits)) {
            return helpers.message('Australian phone number (+61) must be 9 or 10 digits.');
        }
    } else {
        if (digits.length < 7 || digits.length > 15) {
            return helpers.message('Phone number must contain between 7 and 15 digits.');
        }
    }
    return digits;
};

const createBookingSchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
    serviceId: Joi.string().trim().required().messages({
        'string.empty': 'Please select a service for the booking.',
        'any.required': 'Service selection is required.',
    }),
    staffId: Joi.string().trim().allow(null, '').optional(),
    staff_id: Joi.string().trim().allow(null, '').optional(),

    customerName: Joi.string()
        .trim()
        .min(2)
        .max(100)
        .pattern(/^[\p{L}\s.'-]+$/u)
        .required()
        .messages({
            'string.empty': 'Customer name is required.',
            'string.min': 'Customer name must be at least 2 characters long.',
            'string.max': 'Customer name cannot exceed 100 characters.',
            'string.pattern.base': 'Customer name should only contain letters, spaces, dots, or hyphens.',
            'any.required': 'Customer name is required.',
        }),
    customerCountryCode: Joi.string().trim().max(10).default('+91').optional(),
    customer_country_code: Joi.string().trim().max(10).default('+91').optional(),

    customerPhone: Joi.string()
        .trim()
        .custom(validatePhoneByCountry)
        .required()
        .messages({
            'string.empty': 'Customer phone number is required.',
            'any.required': 'Customer phone number is required.',
        }),
    customer_phone: Joi.string()
        .trim()
        .custom(validatePhoneByCountry)
        .optional(),

    customerEmail: Joi.string()
        .trim()
        .email({ tlds: { allow: false } })
        .max(120)
        .allow('', null)
        .optional()
        .messages({
            'string.email': 'Please enter a valid email address.',
            'string.max': 'Email address cannot exceed 120 characters.',
        }),
    customer_email: Joi.string()
        .trim()
        .email({ tlds: { allow: false } })
        .max(120)
        .allow('', null)
        .optional(),

    customerNotes: Joi.string().trim().max(500).allow('', null).optional().messages({
        'string.max': 'Customer notes cannot exceed 500 characters.',
    }),
    customer_notes: Joi.string().trim().max(500).allow('', null).optional(),

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

    customerName: Joi.string()
        .trim()
        .min(2)
        .max(100)
        .pattern(/^[\p{L}\s.'-]+$/u)
        .required()
        .messages({
            'string.empty': 'Your name is required.',
            'string.min': 'Name must be at least 2 characters long.',
            'string.max': 'Name cannot exceed 100 characters.',
            'string.pattern.base': 'Name should only contain letters, spaces, dots, or hyphens.',
            'any.required': 'Your name is required.',
        }),
    customerCountryCode: Joi.string().trim().max(10).default('+91').optional(),
    customer_country_code: Joi.string().trim().max(10).default('+91').optional(),

    customerPhone: Joi.string()
        .trim()
        .custom(validatePhoneByCountry)
        .required()
        .messages({
            'string.empty': 'Your phone number is required.',
            'any.required': 'Your phone number is required.',
        }),
    customer_phone: Joi.string()
        .trim()
        .custom(validatePhoneByCountry)
        .optional(),

    customerEmail: Joi.string()
        .trim()
        .email({ tlds: { allow: false } })
        .max(120)
        .allow('', null)
        .optional()
        .messages({
            'string.email': 'Please enter a valid email address.',
            'string.max': 'Email address cannot exceed 120 characters.',
        }),
    customer_email: Joi.string()
        .trim()
        .email({ tlds: { allow: false } })
        .max(120)
        .allow('', null)
        .optional(),

    customerNotes: Joi.string().trim().max(500).allow('', null).optional().messages({
        'string.max': 'Notes cannot exceed 500 characters.',
    }),
    customer_notes: Joi.string().trim().max(500).allow('', null).optional(),

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
