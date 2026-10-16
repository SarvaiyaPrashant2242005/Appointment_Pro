const Business = require('./business.model');
const BusinessMember = require('./business_member.model');
const { User } = require('../users');

// Associations: Business <-> User (Owner)
Business.belongsTo(User, {
    foreignKey: 'owner_id',
    as: 'owner',
    onDelete: 'RESTRICT',
});

User.hasMany(Business, {
    foreignKey: 'owner_id',
    as: 'businesses',
});

// Associations: Business <-> BusinessMember
Business.hasMany(BusinessMember, {
    foreignKey: 'business_id',
    as: 'members',
    onDelete: 'CASCADE',
});

BusinessMember.belongsTo(Business, {
    foreignKey: 'business_id',
    as: 'business',
});

// Associations: BusinessMember <-> User
BusinessMember.belongsTo(User, {
    foreignKey: 'user_id',
    as: 'user',
});

User.hasMany(BusinessMember, {
    foreignKey: 'user_id',
    as: 'businessMemberships',
    onDelete: 'CASCADE',
});

module.exports = {
    Business,
    BusinessMember,
};
