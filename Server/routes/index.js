const express = require('express');
const router = express.Router();

const authRoutes = require('../modules/auth/auth.routes');

// Mount Auth routes under /auth
router.use('/auth', authRoutes);

module.exports = router;
