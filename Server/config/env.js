require("dotenv").config();

const requiredVariables = [
    'DB_HOST',
    'DB_NAME',
    'DB_USER',
    'DB_PASSWORD'
];

for (const key of requiredVariables) {
    if (!process.env[key]) {
        throw new Error(`Missing environment variable ${key}`);
    }
}

module.exports = {
    nodeEnv: process.env.NODE_ENV || 'development',
    port: Number(process.env.PORT) || 3000,

    database: {
        host: process.env.DB_HOST,
        port: Number(process.env.DB_PORT) || 5432,
        name: process.env.DB_NAME,
        username: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        logging: process.env.DB_LOGGING === 'true',
    }
};