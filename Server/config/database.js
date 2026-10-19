const { Sequelize } = require('sequelize');
const env = require('./env');

const sequelize = new Sequelize(
    env.database.name,
    env.database.username,
    env.database.password,
    {
        host: env.database.host,
        port: env.database.port,
        dialect: 'postgres',
        logging: env.database.logging ? console.log : false,

        pool: {
            max: 10,
            min: 0,
            acquire: 30000,
            idle: 10000,
        },
    }
);

const connectDatabase = async () => {
    try {
        await sequelize.authenticate();
        console.log('✅ PostgreSQL Connected Successfully');

        if (env.nodeEnv === 'development') {
            await sequelize.sync({ alter: true });
            console.log('📂 Database & tables synced!');
        }
    } catch (err) {
        console.error("❌ Database Connection Failed");
        console.error(err.message || err);

        // Terminate process with failure code (1) to prevent the web server from running in an unhealthy state
        process.exit(1);
    }
};

module.exports = { sequelize, connectDatabase };