const Joi = require('joi');

const createStaffSchema = Joi.object({
    id: Joi.string().trim().optional(),
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
    userId: Joi.string().trim().allow(null, '').optional(),
    user_id: Joi.string().trim().allow(null, '').optional(),

    name: Joi.string().trim().min(2).max(255).required().messages({
        'string.empty': 'Staff member name is required.',
        'string.min': 'Staff name must be at least 2 characters long.',
        'string.max': 'Staff name cannot exceed 255 characters.',
        'any.required': 'Staff member name is required.',
    }),

    email: Joi.string().trim().email().allow('', null).optional().messages({
        'string.email': 'Please provide a valid staff email address.',
    }),

    phone: Joi.string().trim().min(7).max(20).allow('', null).optional().messages({
        'string.min': 'Please enter a valid staff phone number.',
        'string.max': 'Staff phone number cannot exceed 20 characters.',
    }),

    assignedServiceIds: Joi.alternatives().try(
        Joi.array().items(Joi.string().trim()),
        Joi.string().trim() // handles JSON stringified array from multipart/form-data
    ).optional(),

    schedule: Joi.alternatives().try(
        Joi.object(),
        Joi.string().trim() // handles JSON stringified object from multipart/form-data
    ).optional(),

    isActive: Joi.boolean().default(true).optional(),
    is_active: Joi.boolean().default(true).optional(),
});

const updateStaffSchema = Joi.object({
    name: Joi.string().trim().min(2).max(255).optional().messages({
        'string.empty': 'Staff member name cannot be empty.',
        'string.min': 'Staff name must be at least 2 characters long.',
    }),

    email: Joi.string().trim().email().allow('', null).optional().messages({
        'string.email': 'Please provide a valid staff email address.',
    }),

    phone: Joi.string().trim().min(7).max(20).allow('', null).optional().messages({
        'string.min': 'Please enter a valid staff phone number.',
        'string.max': 'Staff phone number cannot exceed 20 characters.',
    }),

    assignedServiceIds: Joi.alternatives().try(
        Joi.array().items(Joi.string().trim()),
        Joi.string().trim()
    ).optional(),

    schedule: Joi.alternatives().try(
        Joi.object(),
        Joi.string().trim()
    ).optional(),

    isActive: Joi.boolean().optional(),
    is_active: Joi.boolean().optional(),
});

const staffIdParamSchema = Joi.object({
    id: Joi.string().trim().required().messages({
        'string.empty': 'Staff ID is required.',
        'any.required': 'Staff ID is required in URL parameters.',
    }),
});

const businessSlugParamSchema = Joi.object({
    businessSlug: Joi.string().trim().required().messages({
        'string.empty': 'Business booking link slug is required.',
        'any.required': 'Business booking link slug is required in URL parameters.',
    }),
});

const listStaffQuerySchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
    serviceId: Joi.string().trim().optional(),
    service_id: Joi.string().trim().optional(),
    isActive: Joi.boolean().optional(),
    is_active: Joi.boolean().optional(),
});

module.exports = {
    createStaffSchema,
    updateStaffSchema,
    staffIdParamSchema,
    businessSlugParamSchema,
    listStaffQuerySchema,
};
