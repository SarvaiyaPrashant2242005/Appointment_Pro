const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const BusinessScheduleBreak = sequelize.define('BusinessScheduleBreak', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    operating_hour_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'business_operating_hours',
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
    tableName: 'business_schedule_breaks',
    timestamps: false,
    indexes: [
        {
            fields: ['operating_hour_id'],
        },
    ],
});

module.exports = BusinessScheduleBreak;
