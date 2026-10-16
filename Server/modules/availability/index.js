const BusinessOperatingHour = require('./business_operating_hour.model');
const BusinessScheduleBreak = require('./business_schedule_break.model');
const { Business } = require('../businesses');

// Business <-> Operating Hours
Business.hasMany(BusinessOperatingHour, {
    foreignKey: 'business_id',
    as: 'operatingHours',
    onDelete: 'CASCADE',
});

BusinessOperatingHour.belongsTo(Business, {
    foreignKey: 'business_id',
    as: 'business',
});

// Operating Hours <-> Breaks
BusinessOperatingHour.hasMany(BusinessScheduleBreak, {
    foreignKey: 'operating_hour_id',
    as: 'breaks',
    onDelete: 'CASCADE',
});

BusinessScheduleBreak.belongsTo(BusinessOperatingHour, {
    foreignKey: 'operating_hour_id',
    as: 'operatingHour',
});

module.exports = {
    BusinessOperatingHour,
    BusinessScheduleBreak,
};
