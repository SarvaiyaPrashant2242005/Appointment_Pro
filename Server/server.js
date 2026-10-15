const app = require('./app');
const env = require('./config/env');
const { sequelize, connectDatabase } = require('./config/database');

const startServer = async () => {
    try {
        await connectDatabase();

        const server = app.listen(env.port, () => {
            console.log(`AppointmentPro API running on port ${env.port}`);
        });

        const shutdown = (signal) => {
            console.log(`${signal} received. Closing server...`);

            server.close(async (error) => {
                try {
                    await sequelize.close();

                    if (error) {
                        console.error(error);
                        process.exitCode = 1;
                    }
                } catch (dbError) {
                    console.error('Database shutdown error:', dbError);
                    process.exitCode = 1;
                }
            });
        };

        process.once('SIGINT', () => shutdown('SIGINT'));
        process.once('SIGTERM', () => shutdown('SIGTERM'));
    } catch (error) {
        console.error('Server startup failed:', error.message);
        process.exitCode = 1;
    }
};

startServer();