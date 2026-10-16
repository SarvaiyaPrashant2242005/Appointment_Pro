const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const Staff = sequelize.define('Staff', {
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
    user_id: {
        type: DataTypes.UUID,
        allowNull: true,
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
    email: {
        type: DataTypes.STRING(191),
        allowNull: true,
        validate: {
            isEmailOrEmpty(value) {
                if (value && value.trim() !== '') {
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    if (!emailRegex.test(value)) {
                        throw new Error('Please provide a valid staff email address.');
                    }
                }
            },
        },
    },
    phone: {
        type: DataTypes.STRING(20),
        allowNull: true,
    },
    avatar_url: {
        type: DataTypes.STRING(500),
        allowNull: true,
    },
    is_active: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true,
    },
}, {
    tableName: 'staff',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            fields: ['business_id', 'is_active'],
        },
        {
            fields: ['user_id'],
        },
    ],
});

/**
 * Format response to support database snake_case and Flutter StaffModel attributes
 */
Staff.prototype.toClientJSON = function () {
    const raw = this.get({ plain: true });

    // Extract assigned service IDs if associations were loaded
    let assignedServiceIds = [];
    if (Array.isArray(raw.services)) {
        assignedServiceIds = raw.services.map((s) => s.id);
    } else if (Array.isArray(raw.assignedServiceIds)) {
        assignedServiceIds = raw.assignedServiceIds;
    }

    // Format schedule map (1..7) if operating hours were loaded
    let schedule = null;
    if (Array.isArray(raw.operatingHours)) {
        schedule = {};
        raw.operatingHours.forEach((oh) => {
            schedule[oh.day_of_week] = {
                dayOfWeek: oh.day_of_week,
                isOpen: oh.is_working,
                openTime: oh.start_time?.substring(0, 5) || '09:00',
                closeTime: oh.close_time?.substring(0, 5) || '18:00',
                breaks: Array.isArray(oh.breaks)
                    ? oh.breaks.map((b) => ({
                        breakName: b.break_name,
                        startTime: b.start_time?.substring(0, 5) || '13:00',
                        endTime: b.end_time?.substring(0, 5) || '14:00',
                    }))
                    : [],
            };
        });
    }

    return {
        ...raw,
        // CamelCase aliases for Flutter StaffModel compatibility
        businessId: raw.business_id,
        avatarPath: raw.avatar_url,
        assignedServiceIds,
        schedule,
        isActive: raw.is_active,
        createdAt: raw.created_at,
        updatedAt: raw.updated_at,
    };
};

module.exports = Staff;
