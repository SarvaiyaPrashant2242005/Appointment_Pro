const bcrypt = require('bcrypt');
const path = require('path');
const fs = require('fs');
const { User, UserOtp, UserSession } = require('../users');
const { generateOtp, getOtpExpiry } = require('../../utils/otp');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../../utils/jwt');
const { sendVerificationEmail, sendPasswordResetEmail } = require('../../utils/mailer');
const env = require('../../config/env');

class AuthService {
    /**
     * Registers a new user and dispatches SMTP verification OTP
     */
    async register({ fullName, email, phone, password, role }) {
        const normalizedEmail = email.trim().toLowerCase();

        const existingUser = await User.findOne({ where: { email: normalizedEmail } });
        if (existingUser) {
            if (existingUser.is_email_verified) {
                const error = new Error('An account with this email is already registered. Please try logging in or register with a different email.');
                error.statusCode = 409;
                throw error;
            }

            // If user previously registered but never verified, update profile and issue fresh OTP
            const password_hash = await bcrypt.hash(password, 10);
            await existingUser.update({
                full_name: fullName.trim(),
                phone: phone.trim(),
                password_hash,
                role: role || existingUser.role,
            });

            // Remove old unverified OTPs and create a fresh one in user_otps table
            await UserOtp.destroy({
                where: { user_id: existingUser.id, type: 'email_verification' },
            });

            const otp = generateOtp(6);
            const otpExpiresAt = getOtpExpiry(10); // 10 minutes

            await UserOtp.create({
                user_id: existingUser.id,
                otp_code: otp,
                type: 'email_verification',
                expires_at: otpExpiresAt,
            });

            await sendVerificationEmail(normalizedEmail, fullName, otp);

            return {
                user: existingUser.toSafeJSON(),
                requiresVerification: true,
                messageToShow: 'Registration received! A 6-digit verification code has been sent to your email.',
            };
        }

        const password_hash = await bcrypt.hash(password, 10);

        const newUser = await User.create({
            full_name: fullName.trim(),
            email: normalizedEmail,
            phone: phone.trim(),
            password_hash,
            role: role || 'owner',
            is_email_verified: false,
        });

        // Store OTP in separate user_otps table
        const otp = generateOtp(6);
        const otpExpiresAt = getOtpExpiry(10); // 10 minutes

        await UserOtp.create({
            user_id: newUser.id,
            otp_code: otp,
            type: 'email_verification',
            expires_at: otpExpiresAt,
        });

        await sendVerificationEmail(normalizedEmail, fullName, otp);

        return {
            user: newUser.toSafeJSON(),
            requiresVerification: true,
            messageToShow: 'Account registered successfully! Please check your email for the 6-digit verification code.',
        };
    }

    /**
     * Verifies user email address via 6-digit OTP
     */
    async verifyEmail({ email, otp }) {
        const normalizedEmail = email.trim().toLowerCase();
        const user = await User.findOne({ where: { email: normalizedEmail } });

        if (!user) {
            const error = new Error('No account found with this email address. Please make sure you registered first.');
            error.statusCode = 404;
            throw error;
        }

        if (user.is_email_verified) {
            const error = new Error('Your email address is already verified. You can log in directly.');
            error.statusCode = 400;
            throw error;
        }

        const otpRecord = await UserOtp.findOne({
            where: {
                user_id: user.id,
                type: 'email_verification',
                otp_code: otp.trim(),
            },
        });

        if (!otpRecord) {
            const error = new Error('The verification code you entered is invalid. Please double-check and try again.');
            error.statusCode = 400;
            throw error;
        }

        if (new Date() > new Date(otpRecord.expires_at)) {
            await otpRecord.destroy();
            const error = new Error('Your verification code has expired. Please tap "Resend Code" to get a fresh code.');
            error.statusCode = 400;
            throw error;
        }

        // Clean up OTP record once verified (no NULL rows lingering)
        await otpRecord.destroy();

        // Mark user as verified
        await user.update({ is_email_verified: true });

        const tokenPayload = {
            id: user.id,
            email: user.email,
            role: user.role,
        };

        const accessToken = signAccessToken(tokenPayload);
        const refreshToken = signRefreshToken(tokenPayload);

        // Record session in user_sessions table
        await UserSession.create({
            user_id: user.id,
            refresh_token: refreshToken,
        });

        return {
            user: user.toSafeJSON(),
            accessToken,
            refreshToken,
            messageToShow: 'Your email address has been verified successfully. Welcome to AppointmentPro!',
        };
    }

    /**
     * Resends email verification code
     */
    async resendVerificationOtp({ email }) {
        const normalizedEmail = email.trim().toLowerCase();
        const user = await User.findOne({ where: { email: normalizedEmail } });

        if (!user) {
            const error = new Error('No account found with this email address. Please register first.');
            error.statusCode = 404;
            throw error;
        }

        if (user.is_email_verified) {
            const error = new Error('Your email address is already verified. You can log in directly.');
            error.statusCode = 400;
            throw error;
        }

        // Clean up old email verification OTPs
        await UserOtp.destroy({
            where: { user_id: user.id, type: 'email_verification' },
        });

        const otp = generateOtp(6);
        const otpExpiresAt = getOtpExpiry(10);

        await UserOtp.create({
            user_id: user.id,
            otp_code: otp,
            type: 'email_verification',
            expires_at: otpExpiresAt,
        });

        await sendVerificationEmail(normalizedEmail, user.full_name, otp);

        return {
            message: 'A fresh 6-digit verification code has been sent to your email. Please check your inbox.',
            messageToShow: 'A fresh 6-digit verification code has been sent to your email. Please check your inbox.',
        };
    }

    /**
     * Authenticates user with email and password
     */
    async login({ email, password }) {
        const normalizedEmail = email.trim().toLowerCase();
        const user = await User.findOne({ where: { email: normalizedEmail } });

        if (!user) {
            const error = new Error('The email address or password you entered is incorrect. Please try again.');
            error.statusCode = 401;
            throw error;
        }

        const isPasswordMatch = await bcrypt.compare(password, user.password_hash);
        if (!isPasswordMatch) {
            const error = new Error('The email address or password you entered is incorrect. Please try again.');
            error.statusCode = 401;
            throw error;
        }

        if (!user.is_active) {
            const error = new Error('Your account has been deactivated. Please contact support for assistance.');
            error.statusCode = 403;
            throw error;
        }

        if (!user.is_email_verified) {
            // Re-issue an OTP to help user verify immediately
            await UserOtp.destroy({
                where: { user_id: user.id, type: 'email_verification' },
            });

            const otp = generateOtp(6);
            const otpExpiresAt = getOtpExpiry(10);

            await UserOtp.create({
                user_id: user.id,
                otp_code: otp,
                type: 'email_verification',
                expires_at: otpExpiresAt,
            });

            await sendVerificationEmail(normalizedEmail, user.full_name, otp);

            const error = new Error('Your email address is not verified yet. We have sent a new verification code to your email.');
            error.statusCode = 403;
            error.requiresVerification = true;
            error.email = normalizedEmail;
            throw error;
        }

        const tokenPayload = {
            id: user.id,
            email: user.email,
            role: user.role,
        };

        const accessToken = signAccessToken(tokenPayload);
        const refreshToken = signRefreshToken(tokenPayload);

        // Store active session in user_sessions table
        await UserSession.create({
            user_id: user.id,
            refresh_token: refreshToken,
        });

        return {
            user: user.toSafeJSON(),
            accessToken,
            refreshToken,
            messageToShow: 'Welcome back! You have logged in successfully.',
        };
    }

    /**
     * Exchanges refresh token for new access and refresh token pair
     */
    async refreshToken({ refreshToken }) {
        let decoded;
        try {
            decoded = verifyRefreshToken(refreshToken);
        } catch (_) {
            const error = new Error('Your session has expired. Please log in again to continue.');
            error.statusCode = 401;
            throw error;
        }

        // Validate session existence in user_sessions table
        const session = await UserSession.findOne({
            where: {
                user_id: decoded.id,
                refresh_token: refreshToken,
            },
        });

        if (!session) {
            const error = new Error('Your session is invalid or has been logged out. Please log in again.');
            error.statusCode = 401;
            throw error;
        }

        const user = await User.findByPk(decoded.id);
        if (!user || !user.is_active) {
            await session.destroy();
            const error = new Error('Account inactive or not found. Please log in again.');
            error.statusCode = 401;
            throw error;
        }

        const tokenPayload = {
            id: user.id,
            email: user.email,
            role: user.role,
        };

        const newAccessToken = signAccessToken(tokenPayload);
        const newRefreshToken = signRefreshToken(tokenPayload);

        // Rotate token in session table
        await session.update({ refresh_token: newRefreshToken });

        return {
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            messageToShow: 'Session refreshed successfully.',
        };
    }

    /**
     * Initiates Forgot Password flow by sending reset OTP via SMTP
     */
    async forgotPassword({ email }) {
        const normalizedEmail = email.trim().toLowerCase();
        const user = await User.findOne({ where: { email: normalizedEmail } });

        // Security best practice: don't reveal whether user exists
        if (!user || !user.is_active) {
            return {
                message: 'If an account exists with this email, a password reset code has been sent.',
                messageToShow: 'If an account exists with this email, a 6-digit password reset code has been sent. Please check your inbox.',
            };
        }

        // Remove old password reset OTPs
        await UserOtp.destroy({
            where: { user_id: user.id, type: 'password_reset' },
        });

        const resetOtp = generateOtp(6);
        const resetExpiresAt = getOtpExpiry(15); // 15 minutes

        await UserOtp.create({
            user_id: user.id,
            otp_code: resetOtp,
            type: 'password_reset',
            expires_at: resetExpiresAt,
        });

        await sendPasswordResetEmail(normalizedEmail, user.full_name, resetOtp);

        return {
            message: 'If an account exists with this email, a password reset code has been sent.',
            messageToShow: 'If an account exists with this email, a 6-digit password reset code has been sent. Please check your inbox.',
        };
    }

    /**
     * Resets password using valid OTP
     */
    async resetPassword({ email, otp, newPassword }) {
        const normalizedEmail = email.trim().toLowerCase();
        const user = await User.findOne({ where: { email: normalizedEmail } });

        if (!user) {
            const error = new Error('Unable to reset password. Please make sure the email address is correct.');
            error.statusCode = 400;
            throw error;
        }

        const otpRecord = await UserOtp.findOne({
            where: {
                user_id: user.id,
                type: 'password_reset',
                otp_code: otp.trim(),
            },
        });

        if (!otpRecord) {
            const error = new Error('The password reset code you entered is invalid. Please double-check and try again.');
            error.statusCode = 400;
            throw error;
        }

        if (new Date() > new Date(otpRecord.expires_at)) {
            await otpRecord.destroy();
            const error = new Error('Your password reset code has expired. Please request a new code.');
            error.statusCode = 400;
            throw error;
        }

        const newPasswordHash = await bcrypt.hash(newPassword, 10);

        // Update password and clean up OTP record
        await user.update({ password_hash: newPasswordHash });
        await otpRecord.destroy();

        // Invalidate all active login sessions across devices for security
        await UserSession.destroy({ where: { user_id: user.id } });

        return {
            message: 'Password has been reset successfully. You can now log in with your new password.',
            messageToShow: 'Your password has been reset successfully. You can now log in with your new password.',
        };
    }

    /**
     * Changes password for an authenticated user
     */
    async changePassword(user, { currentPassword, newPassword }) {
        const isMatch = await bcrypt.compare(currentPassword, user.password_hash);
        if (!isMatch) {
            const error = new Error('The current password you entered is incorrect. Please try again.');
            error.statusCode = 400;
            throw error;
        }

        const newHash = await bcrypt.hash(newPassword, 10);
        await user.update({ password_hash: newHash });

        // Invalidate all sessions on password change
        await UserSession.destroy({ where: { user_id: user.id } });

        return {
            message: 'Password updated successfully.',
            messageToShow: 'Your password has been changed successfully.',
        };
    }

    /**
     * Updates user profile (name, phone, avatar)
     */
    async updateProfile(user, { fullName, phone }, avatarFile) {
        const updateFields = {};

        if (fullName) updateFields.full_name = fullName.trim();
        if (phone) updateFields.phone = phone.trim();

        if (avatarFile) {
            // Delete old avatar if it exists
            if (user.avatar_url) {
                const oldPath = path.join(__dirname, '..', '..', user.avatar_url);
                if (fs.existsSync(oldPath)) {
                    try {
                        fs.unlinkSync(oldPath);
                    } catch (_) {}
                }
            }
            updateFields.avatar_url = `/${env.uploadDir}/avatars/${avatarFile.filename}`;
        }

        await user.update(updateFields);
        return {
            user: user.toSafeJSON(),
            messageToShow: 'Your profile has been updated successfully.',
        };
    }

    /**
     * Invalidate user session on logout
     */
    async logout(userId, refreshToken = null) {
        if (refreshToken) {
            await UserSession.destroy({
                where: { user_id: userId, refresh_token: refreshToken },
            });
        } else {
            await UserSession.destroy({
                where: { user_id: userId },
            });
        }

        return {
            message: 'Logged out successfully.',
            messageToShow: 'You have been logged out successfully.',
        };
    }
}

module.exports = new AuthService();
