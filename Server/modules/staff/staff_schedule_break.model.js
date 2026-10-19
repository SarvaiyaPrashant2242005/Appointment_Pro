const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const StaffScheduleBreak = sequelize.define('StaffScheduleBreak', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    staff_operating_hour_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'staff_operating_hours',
            key: 'id',
        },
    },
    break_name: {
        type: DataTypes.STRING(100),
        allowNull: false,
        defaultValue: 'Break',
    },
    start_time: {
        type: DataTypes.TIME,
        allowNull: false,
    },
    end_time: {
        type: DataTypes.TIME,
        allowNull: false,
    },
}, {
    tableName: 'staff_schedule_breaks',
    timestamps: false,
    indexes: [
        {
            fields: ['staff_operating_hour_id'],
        },
    ],
});

module.exports = StaffScheduleBreak;
