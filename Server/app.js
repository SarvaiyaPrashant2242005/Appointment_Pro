const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const morgan = require("morgan");

const env = require("./config/env");
const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(env.nodeEnv === 'development' ? 'dev' : "combined"));

app.get('/api/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: `AppointmentPro API is running on port ${env.port}`,
        environment: env.nodeEnv,
        timestamp: new Date().toISOString(),
    });
});

// Mount feature routes here when implemented.

app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found',
    });
});


module.exports = app;