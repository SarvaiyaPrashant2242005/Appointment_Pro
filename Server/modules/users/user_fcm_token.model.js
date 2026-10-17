const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const UserFcmToken = sequelize.define('UserFcmToken', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'users',
            key: 'id',
        },
        onDelete: 'CASCADE',
    },
    fcm_token: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    device_type: {
        type: DataTypes.STRING(50),
        allowNull: true,
        defaultValue: 'android',
    },
    device_id: {
        type: DataTypes.STRING(100),
        allowNull: true,
    },
    last_active_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
    },
}, {
    tableName: 'user_fcm_tokens',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            fields: ['user_id'],
        },
        {
            fields: ['fcm_token'],
        },
    ],
});

module.exports = UserFcmToken;
