const Service = require('./service.model');
const { Business } = require('../businesses');

// Associations: Business <-> Service
Business.hasMany(Service, {
    foreignKey: 'business_id',
    as: 'services',
    onDelete: 'CASCADE',
});

Service.belongsTo(Business, {
    foreignKey: 'business_id',
    as: 'business',
});

module.exports = {
    Service,
};
