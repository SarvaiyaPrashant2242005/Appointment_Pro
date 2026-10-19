const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const BusinessMember = sequelize.define('BusinessMember', {
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
        allowNull: false,
        references: {
            model: 'users',
            key: 'id',
        },
    },
    role: {
        type: DataTypes.ENUM('owner', 'manager', 'staff'),
        allowNull: false,
        defaultValue: 'staff',
    },
    is_active: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true,
    },
}, {
    tableName: 'business_members',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false, // schema.sql specifies only created_at for business_members
    indexes: [
        {
            unique: true,
            fields: ['business_id', 'user_id'],
        },
    ],
});

module.exports = BusinessMember;
