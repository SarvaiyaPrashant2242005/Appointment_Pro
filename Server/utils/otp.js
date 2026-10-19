const crypto = require('crypto');

/**
 * Generates a cryptographically secure numeric OTP
 * @param {number} length Default 6 digits
 * @returns {string} e.g. "849201"
 */
const generateOtp = (length = 6) => {
    const min = Math.pow(10, length - 1);
    const max = Math.pow(10, length) - 1;
    return crypto.randomInt(min, max + 1).toString();
};

/**
 * Calculates expiration timestamp
 * @param {number} minutesMinutes Default 10 minutes
 * @returns {Date}
 */
const getOtpExpiry = (minutes = 10) => {
    return new Date(Date.now() + minutes * 60 * 1000);
};

module.exports = {
    generateOtp,
    getOtpExpiry,
};
