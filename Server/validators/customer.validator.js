const Joi = require('joi');

const createCustomerSchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),

    name: Joi.string().trim().min(2).max(255).required().messages({
        'string.empty': 'Customer name is required.',
        'string.min': 'Customer name must be at least 2 characters long.',
        'any.required': 'Customer name is required.',
    }),

    countryCode: Joi.string().trim().max(10).default('+91').optional(),
    country_code: Joi.string().trim().max(10).default('+91').optional(),

    phone: Joi.string().trim().min(7).max(20).required().messages({
        'string.empty': 'Customer phone number is required.',
        'string.min': 'Please enter a valid phone number.',
        'any.required': 'Customer phone number is required.',
    }),

    email: Joi.string().trim().email().allow('', null).optional().messages({
        'string.email': 'Please enter a valid email address.',
    }),

    notes: Joi.string().trim().allow('', null).optional(),
});

const updateCustomerSchema = Joi.object({
    name: Joi.string().trim().min(2).max(255).optional().messages({
        'string.empty': 'Customer name cannot be empty.',
    }),
    countryCode: Joi.string().trim().max(10).optional(),
    country_code: Joi.string().trim().max(10).optional(),
    phone: Joi.string().trim().min(7).max(20).optional(),
    email: Joi.string().trim().email().allow('', null).optional(),
    notes: Joi.string().trim().allow('', null).optional(),
});

const customerIdParamSchema = Joi.object({
    id: Joi.string().trim().required().messages({
        'string.empty': 'Customer ID is required.',
        'any.required': 'Customer ID is required in URL parameters.',
    }),
});

const listCustomersQuerySchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
    search: Joi.string().trim().optional(),
});

module.exports = {
    createCustomerSchema,
    updateCustomerSchema,
    customerIdParamSchema,
    listCustomersQuerySchema,
};
