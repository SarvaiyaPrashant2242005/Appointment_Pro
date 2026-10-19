const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const BusinessOperatingHour = sequelize.define('BusinessOperatingHour', {
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
    day_of_week: {
        type: DataTypes.INTEGER,
        allowNull: false,
        validate: {
            min: 1,
            max: 7,
        },
    },
    is_open: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true,
    },
    open_time: {
        type: DataTypes.TIME,
        allowNull: false,
        defaultValue: '09:00:00',
    },
    close_time: {
        type: DataTypes.TIME,
        allowNull: false,
        defaultValue: '18:00:00',
    },
}, {
    tableName: 'business_operating_hours',
    timestamps: false,
    indexes: [
        {
            unique: true,
            fields: ['business_id', 'day_of_week'],
        },
    ],
});

/**
 * Helper to serialize day schedule to client format
 */
BusinessOperatingHour.prototype.toClientJSON = function () {
    const raw = this.get({ plain: true });
    const formattedBreaks = Array.isArray(raw.breaks)
        ? raw.breaks.map((b) => ({
            id: b.id,
            breakName: b.break_name,
            startTime: b.start_time?.substring(0, 5) || '13:00',
            endTime: b.end_time?.substring(0, 5) || '14:00',
        }))
        : [];

    return {
        id: raw.id,
        businessId: raw.business_id,
        dayOfWeek: raw.day_of_week,
        isOpen: raw.is_open,
        openTime: raw.open_time?.substring(0, 5) || '09:00',
        closeTime: raw.close_time?.substring(0, 5) || '18:00',
        breaks: formattedBreaks,
        // Snake case aliases
        is_open: raw.is_open,
        open_time: raw.open_time,
        close_time: raw.close_time,
    };
};

module.exports = BusinessOperatingHour;
