const { verifyAccessToken } = require('../utils/jwt');
const { sendError } = require('../utils/response');
const User = require('../modules/users/user.model');

/**
 * Authentication middleware verifying Bearer JWT Token
 */
const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return sendError(res, {
                statusCode: 401,
                message: 'Authorization token required. Please log in.',
                messageToShow: 'Please log in to continue.',
            });
        }

        const token = authHeader.split(' ')[1];
        let decoded;
        try {
            decoded = verifyAccessToken(token);
        } catch (jwtError) {
            if (jwtError.name === 'TokenExpiredError') {
                return sendError(res, {
                    statusCode: 401,
                    message: 'Session expired. Please log in again.',
                    messageToShow: 'Your session has expired. Please log in again to continue.',
                });
            }
            return sendError(res, {
                statusCode: 401,
                message: 'Invalid authorization token.',
                messageToShow: 'Your login session is invalid. Please log in again.',
            });
        }

        const user = await User.findByPk(decoded.id);
        if (!user) {
            return sendError(res, {
                statusCode: 401,
                message: 'User account not found.',
                messageToShow: 'Account could not be found. Please log in again.',
            });
        }

        if (!user.is_active) {
            return sendError(res, {
                statusCode: 403,
                message: 'Account has been deactivated. Please contact support.',
                messageToShow: 'Your account has been deactivated. Please contact support for assistance.',
            });
        }

        req.user = user;
        return next();
    } catch (error) {
        console.error('Auth Middleware Error:', error);
        return sendError(res, {
            statusCode: 500,
            message: 'Authentication error',
            messageToShow: 'Something went wrong verifying your session. Please try again.',
        });
    }
};

module.exports = authenticate;
