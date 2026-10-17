/**
 * Standardized API Response Utilities with User-Friendly messageToShow
 */

const sendSuccess = (res, { statusCode = 200, message = 'Success', messageToShow = null, data = null, meta = null } = {}) => {
    const finalMessage = messageToShow || message;

    const payload = {
        success: true,
        message: message,
        messageToShow: finalMessage,
    };

    if (data !== null) payload.data = data;
    if (meta !== null) payload.meta = meta;

    return res.status(statusCode).json(payload);
};

const sendError = (res, { statusCode = 500, message = 'An error occurred', messageToShow = null, errors = null, ...rest } = {}) => {
    const finalMessage = messageToShow || message;

    const payload = {
        success: false,
        message: message,
        messageToShow: finalMessage,
        ...rest,
    };

    if (errors !== null) payload.errors = errors;

    return res.status(statusCode).json(payload);
};

module.exports = {
    sendSuccess,
    sendError,
};
