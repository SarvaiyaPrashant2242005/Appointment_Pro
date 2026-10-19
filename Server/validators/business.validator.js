const Joi = require('joi');

const createBusinessSchema = Joi.object({
    name: Joi.string().trim().min(2).max(255).required().messages({
        'string.empty': 'Business name is required.',
        'string.min': 'Business name must be at least 2 characters long.',
        'string.max': 'Business name cannot exceed 255 characters.',
        'any.required': 'Business name is required.',
    }),
    type: Joi.string().trim().min(2).max(100).required().messages({
        'string.empty': 'Business category/type is required.',
        'string.min': 'Business type must be at least 2 characters long.',
        'string.max': 'Business type cannot exceed 100 characters.',
        'any.required': 'Business category/type is required.',
    }),
    otherType: Joi.string().trim().max(100).allow('', null).optional(),
    other_type: Joi.string().trim().max(100).allow('', null).optional(),

    email: Joi.string().trim().email().allow('', null).optional().messages({
        'string.email': 'Please enter a valid business email address.',
    }),

    countryCode: Joi.string().trim().max(10).default('+91').optional(),
    country_code: Joi.string().trim().max(10).default('+91').optional(),

    phone: Joi.string().trim().min(7).max(20).allow('', null).optional().messages({
        'string.min': 'Please enter a valid business phone number.',
        'string.max': 'Business phone number cannot exceed 20 characters.',
    }),

    currency: Joi.string().trim().max(10).default('INR').optional(),
    timezone: Joi.string().trim().max(100).default('Asia/Kolkata').optional(),

    isActive: Joi.boolean().optional(),
    is_active: Joi.boolean().optional(),
});

const updateBusinessSchema = Joi.object({
    name: Joi.string().trim().min(2).max(255).optional().messages({
        'string.empty': 'Business name cannot be empty.',
        'string.min': 'Business name must be at least 2 characters long.',
        'string.max': 'Business name cannot exceed 255 characters.',
    }),
    type: Joi.string().trim().min(2).max(100).optional().messages({
        'string.empty': 'Business category/type cannot be empty.',
        'string.min': 'Business type must be at least 2 characters long.',
    }),
    otherType: Joi.string().trim().max(100).allow('', null).optional(),
    other_type: Joi.string().trim().max(100).allow('', null).optional(),

    email: Joi.string().trim().email().allow('', null).optional().messages({
        'string.email': 'Please enter a valid business email address.',
    }),

    countryCode: Joi.string().trim().max(10).optional(),
    country_code: Joi.string().trim().max(10).optional(),

    phone: Joi.string().trim().min(7).max(20).allow('', null).optional().messages({
        'string.min': 'Please enter a valid business phone number.',
        'string.max': 'Business phone number cannot exceed 20 characters.',
    }),

    currency: Joi.string().trim().max(10).optional(),
    timezone: Joi.string().trim().max(100).optional(),

    isActive: Joi.boolean().optional(),
    is_active: Joi.boolean().optional(),
});

const businessIdParamSchema = Joi.object({
    id: Joi.string().trim().required().messages({
        'string.empty': 'Business ID is required.',
        'any.required': 'Business ID is required in the URL parameters.',
    }),
});

const businessSlugParamSchema = Joi.object({
    slug: Joi.string().trim().required().messages({
        'string.empty': 'Business booking link slug is required.',
        'any.required': 'Business booking link slug is required in the URL parameters.',
    }),
});

module.exports = {
    createBusinessSchema,
    updateBusinessSchema,
    businessIdParamSchema,
    businessSlugParamSchema,
};
