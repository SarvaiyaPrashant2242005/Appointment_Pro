const nodemailer = require('nodemailer');
const env = require('../config/env');

let transporter = null;

if (env.smtp.isConfigured) {
    transporter = nodemailer.createTransport({
        host: env.smtp.host,
        port: env.smtp.port,
        secure: env.smtp.secure,
        auth: {
            user: env.smtp.user,
            pass: env.smtp.pass,
        },
    });
}

/**
 * Base email sender helper
 */
const sendMail = async ({ to, subject, html, text }) => {
    if (!transporter) {
        console.log('\n================== ✉️ LOCAL EMAIL SIMULATOR ✉️ ==================');
        console.log(`To: ${to}`);
        console.log(`Subject: ${subject}`);
        console.log(`Body text:\n${text}`);
        console.log('=================================================================\n');
        return { messageId: 'simulated-local-id' };
    }

    return transporter.sendMail({
        from: env.smtp.from,
        to,
        subject,
        text,
        html,
    });
};

/**
 * Sends Email Verification OTP
 */
const sendVerificationEmail = async (to, fullName, otp) => {
    const subject = `${otp} is your AppointmentPro verification code`;
    const text = `Hi ${fullName},\n\nYour verification code is: ${otp}. This code is valid for 10 minutes.\n\nThank you,\nAppointmentPro Team`;

    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; color: #1e293b; }
        .card { max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 32px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
        .header { text-align: center; margin-bottom: 24px; }
        .logo { font-size: 22px; font-weight: bold; color: #0284c7; }
        .otp-box { background: #f0f9ff; border: 2px dashed #0284c7; border-radius: 12px; padding: 18px; text-align: center; margin: 24px 0; }
        .otp-code { font-size: 32px; font-weight: 800; letter-spacing: 6px; color: #0369a1; font-family: monospace; }
        .footer { text-align: center; font-size: 12px; color: #94a3b8; margin-top: 24px; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <div class="logo">AppointmentPro</div>
          <h2 style="margin: 8px 0; color: #0f172a;">Verify Your Email Address</h2>
        </div>
        <p>Hello <strong>${fullName}</strong>,</p>
        <p>Thank you for signing up with AppointmentPro. Please use the verification code below to activate your account:</p>
        
        <div class="otp-box">
          <div class="otp-code">${otp}</div>
          <small style="color: #64748b;">Valid for 10 minutes</small>
        </div>
        
        <p style="font-size: 13px; color: #64748b;">If you did not request this account registration, please ignore this email.</p>
        
        <div class="footer">
          &copy; ${new Date().getFullYear()} AppointmentPro. All rights reserved.
        </div>
      </div>
    </body>
    </html>
    `;

    return sendMail({ to, subject, html, text });
};

/**
 * Sends Password Reset OTP
 */
const sendPasswordResetEmail = async (to, fullName, otp) => {
    const subject = `${otp} is your AppointmentPro password reset code`;
    const text = `Hi ${fullName},\n\nYou requested to reset your password. Your reset code is: ${otp}. This code is valid for 15 minutes.\n\nIf you did not request this, please change your password immediately.\n\nAppointmentPro Team`;

    const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; color: #1e293b; }
        .card { max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 32px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
        .header { text-align: center; margin-bottom: 24px; }
        .logo { font-size: 22px; font-weight: bold; color: #dc2626; }
        .otp-box { background: #fef2f2; border: 2px dashed #ef4444; border-radius: 12px; padding: 18px; text-align: center; margin: 24px 0; }
        .otp-code { font-size: 32px; font-weight: 800; letter-spacing: 6px; color: #b91c1c; font-family: monospace; }
        .footer { text-align: center; font-size: 12px; color: #94a3b8; margin-top: 24px; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <div class="logo">AppointmentPro</div>
          <h2 style="margin: 8px 0; color: #0f172a;">Password Reset Request</h2>
        </div>
        <p>Hello <strong>${fullName}</strong>,</p>
        <p>We received a request to reset your password. Use the verification code below to proceed:</p>
        
        <div class="otp-box">
          <div class="otp-code">${otp}</div>
          <small style="color: #64748b;">Valid for 15 minutes</small>
        </div>
        
        <p style="font-size: 13px; color: #ef4444;"><strong>Security Note:</strong> Never share this code with anyone. If you did not make this request, please review your account security.</p>
        
        <div class="footer">
          &copy; ${new Date().getFullYear()} AppointmentPro. All rights reserved.
        </div>
      </div>
    </body>
    </html>
    `;

    return sendMail({ to, subject, html, text });
};

module.exports = {
    sendMail,
    sendVerificationEmail,
    sendPasswordResetEmail,
};
