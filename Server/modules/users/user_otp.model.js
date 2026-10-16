const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const UserOtp = sequelize.define('UserOtp', {
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
    otp_code: {
        type: DataTypes.STRING(6),
        allowNull: false,
    },
    type: {
        type: DataTypes.ENUM('email_verification', 'password_reset'),
        allowNull: false,
    },
    expires_at: {
        type: DataTypes.DATE,
        allowNull: false,
    },
}, {
    tableName: 'user_otps',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            fields: ['user_id', 'type'],
        },
    ],
});

module.exports = UserOtp;
