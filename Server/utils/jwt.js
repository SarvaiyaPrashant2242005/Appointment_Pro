const jwt = require('jsonwebtoken');
const env = require('../config/env');

/**
 * Signs a JWT Access Token
 * @param {object} payload e.g. { id, email, role }
 */
const signAccessToken = (payload) => {
    return jwt.sign(payload, env.jwt.accessSecret, {
        expiresIn: env.jwt.accessExpiresIn,
    });
};

/**
 * Signs a JWT Refresh Token
 * @param {object} payload e.g. { id, email }
 */
const signRefreshToken = (payload) => {
    return jwt.sign(payload, env.jwt.refreshSecret, {
        expiresIn: env.jwt.refreshExpiresIn,
    });
};

/**
 * Verifies JWT Access Token
 * @param {string} token
 */
const verifyAccessToken = (token) => {
    return jwt.verify(token, env.jwt.accessSecret);
};

/**
 * Verifies JWT Refresh Token
 * @param {string} token
 */
const verifyRefreshToken = (token) => {
    return jwt.verify(token, env.jwt.refreshSecret);
};

module.exports = {
    signAccessToken,
    signRefreshToken,
    verifyAccessToken,
    verifyRefreshToken,
};
