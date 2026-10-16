const authService = require('./auth.service');
const { sendSuccess } = require('../../utils/response');

class AuthController {
    async register(req, res, next) {
        try {
            const result = await authService.register(req.body);
            return sendSuccess(res, {
                statusCode: 201,
                message: 'Account registered successfully.',
                messageToShow: result.messageToShow || 'Account registered successfully. Please check your email for the verification code.',
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }

    async verifyEmail(req, res, next) {
        try {
            const result = await authService.verifyEmail(req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Email verified successfully.',
                messageToShow: result.messageToShow || 'Your email address has been verified successfully. Welcome to AppointmentPro!',
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }

    async resendVerification(req, res, next) {
        try {
            const result = await authService.resendVerificationOtp(req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: result.message,
                messageToShow: result.messageToShow || result.message,
            });
        } catch (error) {
            next(error);
        }
    }

    async login(req, res, next) {
        try {
            const result = await authService.login(req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Logged in successfully.',
                messageToShow: result.messageToShow || 'Welcome back! You have logged in successfully.',
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }

    async refreshToken(req, res, next) {
        try {
            const result = await authService.refreshToken(req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Token refreshed successfully.',
                messageToShow: result.messageToShow || 'Session refreshed successfully.',
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }

    async forgotPassword(req, res, next) {
        try {
            const result = await authService.forgotPassword(req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: result.message,
                messageToShow: result.messageToShow || result.message,
            });
        } catch (error) {
            next(error);
        }
    }

    async resetPassword(req, res, next) {
        try {
            const result = await authService.resetPassword(req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: result.message,
                messageToShow: result.messageToShow || result.message,
            });
        } catch (error) {
            next(error);
        }
    }

    async getProfile(req, res, next) {
        try {
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Profile retrieved successfully.',
                messageToShow: 'Profile retrieved successfully.',
                data: req.user.toSafeJSON(),
            });
        } catch (error) {
            next(error);
        }
    }

    async updateProfile(req, res, next) {
        try {
            const result = await authService.updateProfile(req.user, req.body, req.file);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Profile updated successfully.',
                messageToShow: result.messageToShow || 'Your profile has been updated successfully.',
                data: result.user || result,
            });
        } catch (error) {
            next(error);
        }
    }

    async changePassword(req, res, next) {
        try {
            const result = await authService.changePassword(req.user, req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: result.message,
                messageToShow: result.messageToShow || result.message,
            });
        } catch (error) {
            next(error);
        }
    }

    async logout(req, res, next) {
        try {
            const result = await authService.logout(req.user.id, req.body?.refreshToken);
            return sendSuccess(res, {
                statusCode: 200,
                message: result.message,
                messageToShow: result.messageToShow || result.message,
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new AuthController();
