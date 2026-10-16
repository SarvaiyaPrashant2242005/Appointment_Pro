const Staff = require('./staff.model');
const StaffService = require('./staff_service.model');
const StaffOperatingHour = require('./staff_operating_hour.model');
const StaffScheduleBreak = require('./staff_schedule_break.model');
const { Business } = require('../businesses');
const { User } = require('../users');
const { Service } = require('../services');

// Business <-> Staff
Business.hasMany(Staff, {
    foreignKey: 'business_id',
    as: 'staff',
    onDelete: 'CASCADE',
});

Staff.belongsTo(Business, {
    foreignKey: 'business_id',
    as: 'business',
});

// User <-> Staff
Staff.belongsTo(User, {
    foreignKey: 'user_id',
    as: 'user',
});

User.hasMany(Staff, {
    foreignKey: 'user_id',
    as: 'staffProfiles',
});

// Staff <-> Service (M:N via StaffService)
Staff.belongsToMany(Service, {
    through: StaffService,
    foreignKey: 'staff_id',
    otherKey: 'service_id',
    as: 'services',
});

Service.belongsToMany(Staff, {
    through: StaffService,
    foreignKey: 'service_id',
    otherKey: 'staff_id',
    as: 'staff',
});

// Staff <-> Operating Hours
Staff.hasMany(StaffOperatingHour, {
    foreignKey: 'staff_id',
    as: 'operatingHours',
    onDelete: 'CASCADE',
});

StaffOperatingHour.belongsTo(Staff, {
    foreignKey: 'staff_id',
    as: 'staff',
});

// Operating Hours <-> Breaks
StaffOperatingHour.hasMany(StaffScheduleBreak, {
    foreignKey: 'staff_operating_hour_id',
    as: 'breaks',
    onDelete: 'CASCADE',
});

StaffScheduleBreak.belongsTo(StaffOperatingHour, {
    foreignKey: 'staff_operating_hour_id',
    as: 'operatingHour',
});

module.exports = {
    Staff,
    StaffService,
    StaffOperatingHour,
    StaffScheduleBreak,
};
