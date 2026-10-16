const Booking = require('./booking.model');
const BookingReschedule = require('./booking_reschedule.model');
const Payment = require('./payment.model');
const Customer = require('../customers/customer.model');
const { Business } = require('../businesses');
const { Service } = require('../services');
const { Staff } = require('../staff');

// Customer <-> Business
Business.hasMany(Customer, {
    foreignKey: 'business_id',
    as: 'customers',
    onDelete: 'CASCADE',
});

Customer.belongsTo(Business, {
    foreignKey: 'business_id',
    as: 'business',
});

// Booking <-> Business
Business.hasMany(Booking, {
    foreignKey: 'business_id',
    as: 'bookings',
    onDelete: 'CASCADE',
});

Booking.belongsTo(Business, {
    foreignKey: 'business_id',
    as: 'business',
});

// Booking <-> Customer
Customer.hasMany(Booking, {
    foreignKey: 'customer_id',
    as: 'bookings',
    onDelete: 'RESTRICT',
});

Booking.belongsTo(Customer, {
    foreignKey: 'customer_id',
    as: 'customer',
});

// Booking <-> Service
Service.hasMany(Booking, {
    foreignKey: 'service_id',
    as: 'bookings',
    onDelete: 'RESTRICT',
});

Booking.belongsTo(Service, {
    foreignKey: 'service_id',
    as: 'service',
});

// Booking <-> Staff
Staff.hasMany(Booking, {
    foreignKey: 'staff_id',
    as: 'bookings',
    onDelete: 'SET NULL',
});

Booking.belongsTo(Staff, {
    foreignKey: 'staff_id',
    as: 'staff',
});

// Booking <-> Reschedule Audit Trail
Booking.hasMany(BookingReschedule, {
    foreignKey: 'booking_id',
    as: 'rescheduleHistory',
    onDelete: 'CASCADE',
});

BookingReschedule.belongsTo(Booking, {
    foreignKey: 'booking_id',
    as: 'booking',
});

BookingReschedule.belongsTo(Staff, {
    foreignKey: 'previous_staff_id',
    as: 'previousStaff',
});

BookingReschedule.belongsTo(Staff, {
    foreignKey: 'new_staff_id',
    as: 'newStaff',
});

// Booking <-> Payment
Booking.hasMany(Payment, {
    foreignKey: 'booking_id',
    as: 'payments',
    onDelete: 'CASCADE',
});

Payment.belongsTo(Booking, {
    foreignKey: 'booking_id',
    as: 'booking',
});

// Payment <-> Business
Business.hasMany(Payment, {
    foreignKey: 'business_id',
    as: 'payments',
    onDelete: 'CASCADE',
});

Payment.belongsTo(Business, {
    foreignKey: 'business_id',
    as: 'business',
});

// Payment <-> Customer
Customer.hasMany(Payment, {
    foreignKey: 'customer_id',
    as: 'payments',
    onDelete: 'RESTRICT',
});

Payment.belongsTo(Customer, {
    foreignKey: 'customer_id',
    as: 'customer',
});

module.exports = {
    Booking,
    BookingReschedule,
    Payment,
    Customer,
};
