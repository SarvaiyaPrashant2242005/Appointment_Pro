const User = require('./user.model');
const UserOtp = require('./user_otp.model');
const UserSession = require('./user_session.model');
const UserFcmToken = require('./user_fcm_token.model');

// Associations
User.hasMany(UserOtp, {
    foreignKey: 'user_id',
    as: 'otps',
    onDelete: 'CASCADE',
});
UserOtp.belongsTo(User, {
    foreignKey: 'user_id',
    as: 'user',
});

User.hasMany(UserSession, {
    foreignKey: 'user_id',
    as: 'sessions',
    onDelete: 'CASCADE',
});
UserSession.belongsTo(User, {
    foreignKey: 'user_id',
    as: 'user',
});

User.hasMany(UserFcmToken, {
    foreignKey: 'user_id',
    as: 'fcmTokens',
    onDelete: 'CASCADE',
});
UserFcmToken.belongsTo(User, {
    foreignKey: 'user_id',
    as: 'user',
});

module.exports = {
    User,
    UserOtp,
    UserSession,
    UserFcmToken,
};
