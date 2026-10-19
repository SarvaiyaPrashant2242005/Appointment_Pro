const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const Customer = sequelize.define('Customer', {
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
    name: {
        type: DataTypes.STRING(255),
        allowNull: false,
        validate: {
            notEmpty: true,
            len: [2, 255],
        },
    },
    country_code: {
        type: DataTypes.STRING(10),
        allowNull: false,
        defaultValue: '+91',
    },
    phone: {
        type: DataTypes.STRING(20),
        allowNull: false,
        validate: {
            notEmpty: true,
        },
    },
    email: {
        type: DataTypes.STRING(191),
        allowNull: true,
        validate: {
            isEmailOrEmpty(value) {
                if (value && value.trim() !== '') {
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    if (!emailRegex.test(value)) {
                        throw new Error('Please provide a valid customer email address.');
                    }
                }
            },
        },
    },
    notes: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
}, {
    tableName: 'customers',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            unique: true,
            fields: ['business_id', 'phone'],
        },
        {
            fields: ['business_id', 'email'],
        },
    ],
});

/**
 * Format response to support database snake_case and Flutter camelCase
 */
Customer.prototype.toClientJSON = function () {
    const raw = this.get({ plain: true });
    return {
        ...raw,
        businessId: raw.business_id,
        countryCode: raw.country_code,
        createdAt: raw.created_at,
        updatedAt: raw.updated_at,
    };
};

module.exports = Customer;
