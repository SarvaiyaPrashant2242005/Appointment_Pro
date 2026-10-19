const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const StaffService = sequelize.define('StaffService', {
    staff_id: {
        type: DataTypes.UUID,
        allowNull: false,
        primaryKey: true,
        references: {
            model: 'staff',
            key: 'id',
        },
    },
    service_id: {
        type: DataTypes.UUID,
        allowNull: false,
        primaryKey: true,
        references: {
            model: 'services',
            key: 'id',
        },
    },
}, {
    tableName: 'staff_services',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false,
    indexes: [
        {
            fields: ['service_id'],
        },
    ],
});

module.exports = StaffService;
