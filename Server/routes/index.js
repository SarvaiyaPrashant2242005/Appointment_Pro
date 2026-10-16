const express = require('express');
const router = express.Router();

const authRoutes = require('../modules/auth/auth.routes');
const businessRoutes = require('../modules/businesses/business.routes');
const serviceRoutes = require('../modules/services/service.routes');

// Mount routes
router.use('/auth', authRoutes);
router.use('/businesses', businessRoutes);
router.use('/services', serviceRoutes);

module.exports = router;
