const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const UserSession = sequelize.define('UserSession', {
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
    refresh_token: {
        type: DataTypes.TEXT,
        allowNull: false,
    },
    user_agent: {
        type: DataTypes.STRING(500),
        allowNull: true,
    },
    ip_address: {
        type: DataTypes.STRING(50),
        allowNull: true,
    },
    expires_at: {
        type: DataTypes.DATE,
        allowNull: true,
    },
}, {
    tableName: 'user_sessions',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            fields: ['user_id'],
        },
    ],
});

module.exports = UserSession;
