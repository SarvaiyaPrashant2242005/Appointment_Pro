const express = require('express');
const router = express.Router();

const availabilityController = require('./availability.controller');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const {
    updateOperatingHoursSchema,
    getOperatingHoursQuerySchema,
    dayOfWeekParamSchema,
    businessSlugParamSchema,
} = require('../../validators/availability.validator');

// 1. Public route: Retrieve operating hours and breaks by business slug for booking (No authentication required)
router.get(
    '/public/:businessSlug',
    validate(businessSlugParamSchema, 'params'),
    availabilityController.getPublicBySlug
);

// All subsequent routes require user authentication
router.use(authenticate);

// 2. Get business operating hours and breaks (defaults to active business if businessId omitted)
router.get(
    ['/', '/operating-hours'],
    validate(getOperatingHoursQuerySchema, 'query'),
    availabilityController.getOperatingHours
);

// 3. Update weekly operating hours and schedule breaks (atomic update)
router.put(
    ['/', '/operating-hours'],
    validate(updateOperatingHoursSchema),
    availabilityController.updateOperatingHours
);

router.patch(
    ['/', '/operating-hours'],
    validate(updateOperatingHoursSchema),
    availabilityController.updateOperatingHours
);

// 4. Quick toggle day status (open/closed)
router.patch(
    ['/:dayOfWeek/toggle', '/operating-hours/:dayOfWeek/toggle'],
    validate(dayOfWeekParamSchema, 'params'),
    availabilityController.toggleDayStatus
);

module.exports = router;
