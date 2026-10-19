const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const Payment = sequelize.define('Payment', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    business_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'businesses',
            key: 'id',
        },
    },
    booking_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'bookings',
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
    amount: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
        defaultValue: 0.00,
    },
    method: {
        type: DataTypes.ENUM('cash', 'upi', 'card', 'online', 'bank_transfer', 'other'),
        allowNull: false,
        defaultValue: 'cash',
    },
    status: {
        type: DataTypes.ENUM('pending', 'completed', 'refunded', 'failed'),
        allowNull: false,
        defaultValue: 'completed',
    },
    transaction_reference: {
        type: DataTypes.STRING(100),
        allowNull: true,
    },
    paid_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
    },
}, {
    tableName: 'payments',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false,
    indexes: [
        {
            fields: ['booking_id'],
        },
        {
            fields: ['business_id', 'paid_at'],
        },
    ],
});

/**
 * Format response to support database snake_case and client camelCase
 */
Payment.prototype.toClientJSON = function () {
    const raw = this.get({ plain: true });
    return {
        ...raw,
        amount: parseFloat(raw.amount) || 0.00,
        businessId: raw.business_id,
        bookingId: raw.booking_id,
        customerId: raw.customer_id,
        transactionReference: raw.transaction_reference,
        paidAt: raw.paid_at,
        createdAt: raw.created_at,
    };
};

module.exports = Payment;
