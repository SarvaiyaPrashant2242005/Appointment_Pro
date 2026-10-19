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
    contentSecurityPolicy: false, // Allows inline script / styling in customer booking template
}));
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(env.nodeEnv === 'development' ? 'dev' : 'combined'));

// Serve uploaded assets statically
app.use(`/${env.uploadDir}`, express.static(path.join(__dirname, env.uploadDir)));

const { getLocalIpAddress, getNetworkBaseUrl } = require('./utils/network');

// Health check endpoint with dynamic network info
app.get('/api/health', (req, res) => {
    const ip = getLocalIpAddress();
    const port = env.port || 5000;
    res.status(200).json({
        success: true,
        message: `AppointmentPro API is running on port ${env.port}`,
        messageToShow: `AppointmentPro server is active and running smoothly.`,
        environment: env.nodeEnv,
        serverIp: ip,
        networkUrl: `http://${ip}:${port}`,
        timestamp: new Date().toISOString(),
    });
});

// Dynamic Network & Host Discovery endpoint for QR scanning
app.get(['/api/v1/system/network-info', '/api/network-info'], (req, res) => {
    const ip = getLocalIpAddress();
    const port = Number(env.port || 5000);
    res.status(200).json({
        success: true,
        ip,
        port,
        webPort: 8080,
        localUrl: `http://localhost:${port}`,
        networkUrl: `http://${ip}:${port}`,
        webLocalUrl: `http://localhost:8080`,
        webNetworkUrl: `http://${ip}:8080`,
    });
});

// Mount API routes
app.use('/api/v1', apiRoutes);
app.use('/api', apiRoutes); // Backwards compatibility alias

// Customer online booking web template (index.html)
// Serves dynamic booking routes e.g. /:slug, /:slug/:businessId, /book/:slug
const publicHtmlPath = path.join(__dirname, '..', 'index.html');
const bookingPaths = [
    '/',
    '/index.html',
    '/:businessSlug',
    '/:businessSlug/:businessId',
    '/book/:businessSlug',
    '/book/:businessSlug/:businessId',
    '/slug/:businessSlug',
    '/slug/:businessSlug/:businessId',
    '/business/:businessSlug',
    '/business/:businessSlug/:businessId',
];

app.get(bookingPaths, (req, res, next) => {
    if (req.path.startsWith('/api') || req.path.startsWith('/uploads') || req.path.includes('.')) {
        return next();
    }
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.sendFile(publicHtmlPath);
});

// 404 Catch-All Route for API
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