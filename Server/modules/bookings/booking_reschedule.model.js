const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const BookingReschedule = sequelize.define('BookingReschedule', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    booking_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'bookings',
            key: 'id',
        },
    },
    previous_start_at: {
        type: DataTypes.DATE,
        allowNull: false,
    },
    previous_end_at: {
        type: DataTypes.DATE,
        allowNull: false,
    },
    new_start_at: {
        type: DataTypes.DATE,
        allowNull: false,
    },
    new_end_at: {
        type: DataTypes.DATE,
        allowNull: false,
    },
    previous_staff_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'staff',
            key: 'id',
        },
    },
    new_staff_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'staff',
            key: 'id',
        },
    },
    reason: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    rescheduled_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
    },
}, {
    tableName: 'booking_reschedules',
    timestamps: false,
    indexes: [
        {
            fields: ['booking_id'],
        },
    ],
});

module.exports = BookingReschedule;
