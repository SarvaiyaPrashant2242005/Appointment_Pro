const express = require('express');
const router = express.Router();

const authRoutes = require('../modules/auth/auth.routes');
const businessRoutes = require('../modules/businesses/business.routes');
const serviceRoutes = require('../modules/services/service.routes');
const staffRoutes = require('../modules/staff/staff.routes');

// Mount routes
router.use('/auth', authRoutes);
router.use('/businesses', businessRoutes);
router.use('/services', serviceRoutes);
router.use('/staff', staffRoutes);

module.exports = router;
