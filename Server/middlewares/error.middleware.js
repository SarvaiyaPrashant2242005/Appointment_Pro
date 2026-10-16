const multer = require('multer');
const { sendError } = require('../utils/response');

/**
 * Global application error handling middleware
 */
const errorHandler = (err, req, res, next) => { // eslint-disable-line no-unused-vars
    console.error('Unhandled Application Error:', err);

    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return sendError(res, {
                statusCode: 400,
                message: 'Image size limit exceeded (Maximum 5MB allowed).',
                messageToShow: 'The uploaded image is too large. Maximum allowed size is 5MB.',
            });
        }
        return sendError(res, {
            statusCode: 400,
            message: `File upload error: ${err.message}`,
            messageToShow: err.message || 'Error uploading file. Please try again.',
        });
    }

    if (err.name === 'SequelizeUniqueConstraintError') {
        const field = err.errors?.[0]?.path || 'field';
        let friendlyMessage = `An account with this ${field} already exists.`;
        if (field === 'email') {
            friendlyMessage = 'An account with this email is already registered. Please try logging in or register with a different email.';
        } else if (field === 'phone') {
            friendlyMessage = 'An account with this phone number is already registered. Please use a different phone number.';
        }

        return sendError(res, {
            statusCode: 409,
            message: `A record with this ${field} already exists.`,
            messageToShow: friendlyMessage,
            errors: err.errors?.map((e) => ({ field: e.path, message: e.message })),
        });
    }

    if (err.name === 'SequelizeValidationError') {
        const firstError = err.errors?.[0]?.message || 'Database validation error';
        return sendError(res, {
            statusCode: 400,
            message: 'Database validation error',
            messageToShow: firstError,
            errors: err.errors?.map((e) => ({ field: e.path, message: e.message })),
        });
    }

    const statusCode = err.statusCode || 500;
    const message = err.message || 'Internal Server Error';
    const messageToShow = err.messageToShow || (statusCode < 500 ? message : 'Something went wrong on our end. Please try again in a moment.');

    return sendError(res, {
        statusCode,
        message,
        messageToShow,
    });
};

module.exports = errorHandler;
