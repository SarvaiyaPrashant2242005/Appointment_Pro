const express = require('express');
const router = express.Router();

const authRoutes = require('../modules/auth/auth.routes');
const businessRoutes = require('../modules/businesses/business.routes');

// Mount routes
router.use('/auth', authRoutes);
router.use('/businesses', businessRoutes);

module.exports = router;
