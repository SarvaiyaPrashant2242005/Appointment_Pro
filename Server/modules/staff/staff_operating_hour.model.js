const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const StaffOperatingHour = sequelize.define('StaffOperatingHour', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    staff_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'staff',
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
    is_working: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true,
    },
    start_time: {
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
    tableName: 'staff_operating_hours',
    timestamps: false,
    indexes: [
        {
            unique: true,
            fields: ['staff_id', 'day_of_week'],
        },
    ],
});

module.exports = StaffOperatingHour;
