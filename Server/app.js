const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');

const env = require('./config/env');
const apiRoutes = require('./routes');
const errorHandler = require('./middlewares/error.middleware');

const app = express();

app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' }, // Allows loading uploaded avatars from other ports
}));
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(env.nodeEnv === 'development' ? 'dev' : 'combined'));

// Serve uploaded assets statically
app.use(`/${env.uploadDir}`, express.static(path.join(__dirname, env.uploadDir)));

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: `AppointmentPro API is running on port ${env.port}`,
        messageToShow: `AppointmentPro server is active and running smoothly.`,
        environment: env.nodeEnv,
        timestamp: new Date().toISOString(),
    });
});

// Mount API routes
app.use('/api/v1', apiRoutes);
app.use('/api', apiRoutes); // Backwards compatibility alias

// 404 Catch-All Route
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint not found',
        messageToShow: 'The requested API route was not found.',
    });
});

// Global Error Handler
app.use(errorHandler);

module.exports = app;