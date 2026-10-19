const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const Business = sequelize.define('Business', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    owner_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'users',
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
    slug: {
        type: DataTypes.STRING(255),
        allowNull: false,
        unique: true,
        validate: {
            notEmpty: true,
        },
    },
    type: {
        type: DataTypes.STRING(100),
        allowNull: false,
        validate: {
            notEmpty: true,
        },
    },
    other_type: {
        type: DataTypes.STRING(100),
        allowNull: true,
    },
    logo_url: {
        type: DataTypes.STRING(500),
        allowNull: true,
    },
    email: {
        type: DataTypes.STRING(191),
        allowNull: true,
        validate: {
            isEmailOrEmpty(value) {
                if (value && value.trim() !== '') {
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    if (!emailRegex.test(value)) {
                        throw new Error('Please provide a valid business email address.');
                    }
                }
            },
        },
    },
    country_code: {
        type: DataTypes.STRING(10),
        allowNull: false,
        defaultValue: '+91',
    },
    phone: {
        type: DataTypes.STRING(20),
        allowNull: true,
    },
    currency: {
        type: DataTypes.STRING(10),
        allowNull: false,
        defaultValue: 'INR',
    },
    timezone: {
        type: DataTypes.STRING(100),
        allowNull: false,
        defaultValue: 'Asia/Kolkata',
    },
    is_active: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false,
    },
}, {
    tableName: 'businesses',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            unique: true,
            fields: ['slug'],
        },
        {
            fields: ['owner_id'],
        },
    ],
});

const { getNetworkBaseUrl, getLocalIpAddress } = require('../../utils/network');

/**
 * Format response to support both database snake_case and Flutter client camelCase
 */
Business.prototype.toClientJSON = function () {
    const raw = this.get({ plain: true });
    const port = process.env.PORT || 5000;
    const networkBase = getNetworkBaseUrl(port);
    const slug = raw.slug || raw.id;
    return {
        ...raw,
        // CamelCase aliases for Flutter BusinessModel compatibility
        logoPath: raw.logo_url,
        otherType: raw.other_type,
        countryCode: raw.country_code,
        isActive: raw.is_active,
        createdAt: raw.created_at,
        updatedAt: raw.updated_at,
        // Dynamic URLs for QR code and public customer booking
        bookingUrl: `${networkBase}/${slug}/${raw.id}`,
        shortBookingUrl: `${networkBase}/book/${slug}`,
        networkHost: getLocalIpAddress(),
    };
};

module.exports = Business;