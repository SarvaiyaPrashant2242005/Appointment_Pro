const Joi = require('joi');

const timeRegex = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

const breakSchema = Joi.object({
    breakName: Joi.string().trim().max(100).default('Break').optional(),
    break_name: Joi.string().trim().max(100).default('Break').optional(),
    startTime: Joi.string().regex(timeRegex).required().messages({
        'string.pattern.base': 'Break start time must be in HH:mm format (e.g. 13:00).',
        'any.required': 'Break start time is required.',
    }),
    start_time: Joi.string().regex(timeRegex).optional(),
    endTime: Joi.string().regex(timeRegex).required().messages({
        'string.pattern.base': 'Break end time must be in HH:mm format (e.g. 14:00).',
        'any.required': 'Break end time is required.',
    }),
    end_time: Joi.string().regex(timeRegex).optional(),
});

const dayScheduleSchema = Joi.object({
    dayOfWeek: Joi.number().integer().min(1).max(7).optional(),
    day_of_week: Joi.number().integer().min(1).max(7).optional(),
    isOpen: Joi.boolean().default(true).optional(),
    is_open: Joi.boolean().default(true).optional(),
    openTime: Joi.string().regex(timeRegex).default('09:00').optional().messages({
        'string.pattern.base': 'Opening time must be in HH:mm format (e.g. 09:00).',
    }),
    open_time: Joi.string().regex(timeRegex).optional(),
    closeTime: Joi.string().regex(timeRegex).default('18:00').optional().messages({
        'string.pattern.base': 'Closing time must be in HH:mm format (e.g. 18:00).',
    }),
    close_time: Joi.string().regex(timeRegex).optional(),
    breaks: Joi.array().items(breakSchema).default([]).optional(),
});

const updateOperatingHoursSchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
    weeklySchedule: Joi.alternatives().try(
        Joi.object().pattern(Joi.string(), dayScheduleSchema),
        Joi.array().items(dayScheduleSchema)
    ).optional(),
    schedule: Joi.alternatives().try(
        Joi.object().pattern(Joi.string(), dayScheduleSchema),
        Joi.array().items(dayScheduleSchema)
    ).optional(),
    operatingHours: Joi.array().items(dayScheduleSchema).optional(),
}).or('weeklySchedule', 'schedule', 'operatingHours').messages({
    'object.missing': 'Please provide the weekly schedule or operating hours to update.',
});

const getOperatingHoursQuerySchema = Joi.object({
    businessId: Joi.string().trim().optional(),
    business_id: Joi.string().trim().optional(),
});

const dayOfWeekParamSchema = Joi.object({
    dayOfWeek: Joi.number().integer().min(1).max(7).required().messages({
        'number.base': 'Day of week must be a number between 1 (Monday) and 7 (Sunday).',
        'number.min': 'Day of week must be between 1 and 7.',
        'number.max': 'Day of week must be between 1 and 7.',
        'any.required': 'Day of week parameter is required.',
    }),
});

const businessSlugParamSchema = Joi.object({
    businessSlug: Joi.string().trim().required().messages({
        'string.empty': 'Business booking link slug is required.',
        'any.required': 'Business booking link slug is required in URL parameters.',
    }),
});

module.exports = {
    updateOperatingHoursSchema,
    getOperatingHoursQuerySchema,
    dayOfWeekParamSchema,
    businessSlugParamSchema,
};
