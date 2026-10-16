const Joi = require('joi');

const registerSchema = Joi.object({
    fullName: Joi.string().trim().min(2).max(100).required().messages({
        'string.empty': 'Full name is required',
        'string.min': 'Full name must be at least 2 characters',
        'string.max': 'Full name cannot exceed 100 characters',
    }),
    email: Joi.string().trim().email().required().messages({
        'string.empty': 'Email address is required',
        'string.email': 'Please provide a valid email address',
    }),
    phone: Joi.string().trim().min(7).max(20).required().messages({
        'string.empty': 'Phone number is required',
        'string.min': 'Please provide a valid phone number',
    }),
    password: Joi.string().min(6).max(128).required().messages({
        'string.empty': 'Password is required',
        'string.min': 'Password must be at least 6 characters long',
    }),
    role: Joi.string().valid('owner', 'manager', 'staff', 'customer').default('owner'),
});

const verifyEmailSchema = Joi.object({
    email: Joi.string().trim().email().required().messages({
        'string.empty': 'Email is required',
        'string.email': 'Valid email is required',
    }),
    otp: Joi.string().trim().length(6).required().messages({
        'string.empty': 'OTP is required',
        'string.length': 'OTP must be exactly 6 digits',
    }),
});

const resendOtpSchema = Joi.object({
    email: Joi.string().trim().email().required().messages({
        'string.empty': 'Email is required',
        'string.email': 'Valid email is required',
    }),
});

const loginSchema = Joi.object({
    email: Joi.string().trim().email().required().messages({
        'string.empty': 'Email is required',
        'string.email': 'Valid email is required',
    }),
    password: Joi.string().required().messages({
        'string.empty': 'Password is required',
    }),
});

const refreshTokenSchema = Joi.object({
    refreshToken: Joi.string().required().messages({
        'string.empty': 'Refresh token is required',
    }),
});

const forgotPasswordSchema = Joi.object({
    email: Joi.string().trim().email().required().messages({
        'string.empty': 'Email is required',
        'string.email': 'Valid email is required',
    }),
});

const resetPasswordSchema = Joi.object({
    email: Joi.string().trim().email().required().messages({
        'string.empty': 'Email is required',
        'string.email': 'Valid email is required',
    }),
    otp: Joi.string().trim().length(6).required().messages({
        'string.empty': 'OTP is required',
        'string.length': 'OTP must be exactly 6 digits',
    }),
    newPassword: Joi.string().min(6).max(128).required().messages({
        'string.empty': 'New password is required',
        'string.min': 'Password must be at least 6 characters long',
    }),
});

const changePasswordSchema = Joi.object({
    currentPassword: Joi.string().required().messages({
        'string.empty': 'Current password is required',
    }),
    newPassword: Joi.string().min(6).max(128).required().messages({
        'string.empty': 'New password is required',
        'string.min': 'New password must be at least 6 characters long',
    }),
});

const updateProfileSchema = Joi.object({
    fullName: Joi.string().trim().min(2).max(100).optional(),
    phone: Joi.string().trim().min(7).max(20).optional(),
});

module.exports = {
    registerSchema,
    verifyEmailSchema,
    resendOtpSchema,
    loginSchema,
    refreshTokenSchema,
    forgotPasswordSchema,
    resetPasswordSchema,
    changePasswordSchema,
    updateProfileSchema,
};
