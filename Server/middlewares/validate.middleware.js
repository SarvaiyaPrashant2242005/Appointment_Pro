const { sendError } = require('../utils/response');

/**
 * Middleware factory for Joi schema validation
 * @param {object} schema Joi schema
 * @param {'body' | 'query' | 'params'} source Source to validate (default 'body')
 */
const validate = (schema, source = 'body') => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req[source], {
            abortEarly: false,
            stripUnknown: true,
        });

        if (error) {
            const errorDetails = error.details.map((detail) => ({
                field: detail.path.join('.'),
                message: detail.message.replace(/['"]/g, ''),
            }));

            // Pick the first clean error message to show directly on UI toast/snackbar
            const firstErrorMessage = errorDetails[0]?.message || 'Please check your input details and try again.';

            return sendError(res, {
                statusCode: 400,
                message: 'Validation failed',
                messageToShow: firstErrorMessage,
                errors: errorDetails,
            });
        }

        req[source] = value;
        return next();
    };
};

module.exports = validate;
