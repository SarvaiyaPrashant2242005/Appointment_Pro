const Joi = require('joi');

const createServiceSchema = Joi.object({
    id: Joi.string().trim().optional(),
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),

    name: Joi.string().trim().min(2).max(255).required().messages({
        'string.empty': 'Service name is required.',
        'string.min': 'Service name must be at least 2 characters long.',
        'string.max': 'Service name cannot exceed 255 characters.',
        'any.required': 'Service name is required.',
    }),

    description: Joi.string().trim().allow('', null).optional().messages({
        'string.base': 'Description must be text.',
    }),

    price: Joi.number().min(0).required().messages({
        'number.base': 'Please enter a valid price for the service.',
        'number.min': 'Service price cannot be negative.',
        'any.required': 'Service price is required.',
    }),

    durationMinutes: Joi.number().integer().min(1).max(1440).optional().messages({
        'number.base': 'Service duration must be a valid number of minutes.',
        'number.min': 'Service duration must be at least 1 minute.',
        'number.max': 'Service duration cannot exceed 24 hours (1440 minutes).',
    }),
    duration_minutes: Joi.number().integer().min(1).max(1440).optional(),

    bufferMinutes: Joi.number().integer().min(0).max(240).default(0).optional().messages({
        'number.base': 'Buffer time must be a number of minutes.',
        'number.min': 'Buffer time cannot be negative.',
        'number.max': 'Buffer time cannot exceed 4 hours (240 minutes).',
    }),
    buffer_minutes: Joi.number().integer().min(0).max(240).default(0).optional(),

    isActive: Joi.boolean().default(true).optional(),
    is_active: Joi.boolean().default(true).optional(),
});

const updateServiceSchema = Joi.object({
    name: Joi.string().trim().min(2).max(255).optional().messages({
        'string.empty': 'Service name cannot be empty.',
        'string.min': 'Service name must be at least 2 characters long.',
        'string.max': 'Service name cannot exceed 255 characters.',
    }),

    description: Joi.string().trim().allow('', null).optional(),

    price: Joi.number().min(0).optional().messages({
        'number.base': 'Please enter a valid price for the service.',
        'number.min': 'Service price cannot be negative.',
    }),

    durationMinutes: Joi.number().integer().min(1).max(1440).optional().messages({
        'number.base': 'Service duration must be a valid number of minutes.',
        'number.min': 'Service duration must be at least 1 minute.',
        'number.max': 'Service duration cannot exceed 24 hours (1440 minutes).',
    }),
    duration_minutes: Joi.number().integer().min(1).max(1440).optional(),

    bufferMinutes: Joi.number().integer().min(0).max(240).optional().messages({
        'number.base': 'Buffer time must be a number of minutes.',
        'number.min': 'Buffer time cannot be negative.',
        'number.max': 'Buffer time cannot exceed 4 hours (240 minutes).',
    }),
    buffer_minutes: Joi.number().integer().min(0).max(240).optional(),

    isActive: Joi.boolean().optional(),
    is_active: Joi.boolean().optional(),
});

const serviceIdParamSchema = Joi.object({
    id: Joi.string().trim().required().messages({
        'string.empty': 'Service ID is required.',
        'any.required': 'Service ID is required in the URL parameters.',
    }),
});

const businessSlugParamSchema = Joi.object({
    businessSlug: Joi.string().trim().required().messages({
        'string.empty': 'Business booking link slug is required.',
        'any.required': 'Business booking link slug is required in the URL parameters.',
    }),
});

const listServicesQuerySchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
    isActive: Joi.boolean().optional(),
    is_active: Joi.boolean().optional(),
});

module.exports = {
    createServiceSchema,
    updateServiceSchema,
    serviceIdParamSchema,
    businessSlugParamSchema,
    listServicesQuerySchema,
};
