const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const Service = sequelize.define('Service', {
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
    description: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    price: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
        defaultValue: 0.00,
        validate: {
            min: 0,
        },
    },
    duration_minutes: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 30,
        validate: {
            min: 1,
            max: 1440,
        },
    },
    buffer_minutes: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0,
        validate: {
            min: 0,
            max: 240,
        },
    },
    is_active: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true,
    },
}, {
    tableName: 'services',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            fields: ['business_id', 'is_active'],
        },
    ],
});

/**
 * Format response to support both database snake_case and Flutter client camelCase
 */
Service.prototype.toClientJSON = function () {
    const raw = this.get({ plain: true });
    return {
        ...raw,
        price: parseFloat(raw.price) || 0.00,
        // CamelCase aliases for Flutter ServiceModel compatibility
        businessId: raw.business_id,
        durationMinutes: raw.duration_minutes,
        bufferMinutes: raw.buffer_minutes,
        isActive: raw.is_active,
        createdAt: raw.created_at,
        updatedAt: raw.updated_at,
    };
};

module.exports = Service;
