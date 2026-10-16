const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const Booking = sequelize.define('Booking', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    booking_reference: {
        type: DataTypes.STRING(20),
        allowNull: false,
        unique: true,
    },
    business_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'businesses',
            key: 'id',
        },
    },
    service_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'services',
            key: 'id',
        },
    },
    staff_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'staff',
            key: 'id',
        },
    },
    customer_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'customers',
            key: 'id',
        },
    },
    service_name: {
        type: DataTypes.STRING(255),
        allowNull: false,
    },
    staff_name: {
        type: DataTypes.STRING(255),
        allowNull: true,
    },
    customer_name: {
        type: DataTypes.STRING(255),
        allowNull: false,
    },
    customer_country_code: {
        type: DataTypes.STRING(10),
        allowNull: false,
        defaultValue: '+91',
    },
    customer_phone: {
        type: DataTypes.STRING(20),
        allowNull: false,
    },
    customer_email: {
        type: DataTypes.STRING(191),
        allowNull: true,
    },
    customer_notes: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    start_at: {
        type: DataTypes.DATE,
        allowNull: false,
    },
    end_at: {
        type: DataTypes.DATE,
        allowNull: false,
    },
    price: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
        defaultValue: 0.00,
    },
    status: {
        type: DataTypes.ENUM('confirmed', 'completed', 'cancelled', 'noShow'),
        allowNull: false,
        defaultValue: 'confirmed',
    },
    cancellation_reason: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    cancelled_at: {
        type: DataTypes.DATE,
        allowNull: true,
    },
}, {
    tableName: 'bookings',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            unique: true,
            fields: ['booking_reference'],
        },
        {
            fields: ['business_id', 'staff_id', 'status', 'start_at', 'end_at'],
        },
        {
            fields: ['business_id', 'start_at', 'status'],
        },
        {
            fields: ['business_id', 'customer_id'],
        },
    ],
});

/**
 * Format response to support database snake_case and Flutter BookingModel attributes
 */
Booking.prototype.toClientJSON = function () {
    const raw = this.get({ plain: true });

    let rescheduleHistory = [];
    if (Array.isArray(raw.rescheduleHistory)) {
        rescheduleHistory = raw.rescheduleHistory.map((r) => ({
            id: r.id,
            previousStartAt: r.previous_start_at,
            previousEndAt: r.previous_end_at,
            newStartAt: r.new_start_at,
            newEndAt: r.new_end_at,
            previousStaffId: r.previous_staff_id,
            newStaffId: r.new_staff_id,
            reason: r.reason,
            rescheduledAt: r.rescheduled_at,
        }));
    }

    return {
        ...raw,
        price: parseFloat(raw.price) || 0.00,
        // CamelCase aliases for Flutter BookingModel compatibility
        bookingReference: raw.booking_reference,
        businessId: raw.business_id,
        serviceId: raw.service_id,
        staffId: raw.staff_id,
        customerId: raw.customer_id,
        customerName: raw.customer_name,
        customerCountryCode: raw.customer_country_code,
        customerPhone: raw.customer_phone,
        customerEmail: raw.customer_email,
        customerNotes: raw.customer_notes,
        startAt: raw.start_at,
        endAt: raw.end_at,
        serviceName: raw.service_name,
        staffName: raw.staff_name,
        cancellationReason: raw.cancellation_reason,
        cancelledAt: raw.cancelled_at,
        rescheduleHistory,
        createdAt: raw.created_at,
        updatedAt: raw.updated_at,
    };
};

module.exports = Booking;
