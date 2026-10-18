const app = require('./app');
const env = require('./config/env');
const { sequelize, connectDatabase } = require('./config/database');

const { getLocalIpAddress } = require('./utils/network');

const startServer = async () => {
    try {
        await connectDatabase();

        const localIp = getLocalIpAddress();
        const server = app.listen(env.port, () => {
            console.log(`AppointmentPro API running:`);
            console.log(`  Local:   http://localhost:${env.port}`);
            console.log(`  Network: http://${localIp}:${env.port} (Scan QR from mobile device)`);
        });

        // Also listen on port 8080 for web booking template requests
        let webServer = null;
        if (Number(env.port) !== 8080) {
            try {
                webServer = app.listen(8080, () => {
                    console.log(`AppointmentPro Web Booking Template running:`);
                    console.log(`  Local:   http://localhost:8080`);
                    console.log(`  Network: http://${localIp}:8080`);
                });
                webServer.on('error', (err) => {
                    console.log(`Port 8080 notice: ${err.message}`);
                });
            } catch (portErr) {
                console.log(`Port 8080 notice: ${portErr.message}`);
            }
        }

        const shutdown = (signal) => {
            console.log(`${signal} received. Closing server...`);

            if (webServer) {
                try { webServer.close(); } catch (e) { }
            }

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