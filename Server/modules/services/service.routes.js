const express = require('express');
const router = express.Router();

const serviceController = require('./service.controller');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const {
    createServiceSchema,
    updateServiceSchema,
    serviceIdParamSchema,
    businessSlugParamSchema,
    listServicesQuerySchema,
} = require('../../validators/service.validator');

// 1. Public route: Retrieve active services by business slug for customer booking (No authentication required)
router.get(
    '/public/:businessSlug',
    validate(businessSlugParamSchema, 'params'),
    serviceController.getPublicBySlug
);

// All subsequent routes require user authentication
router.use(authenticate);

// 2. Create a new service under a business
router.post(
    '/',
    validate(createServiceSchema),
    serviceController.create
);

// 3. List services (with optional ?businessId=... and ?isActive=... query filters)
router.get(
    '/',
    validate(listServicesQuerySchema, 'query'),
    serviceController.getAll
);

// 4. Get specific service by ID
router.get(
    '/:id',
    validate(serviceIdParamSchema, 'params'),
    serviceController.getById
);

// 5. Update service details (supports PUT & PATCH)
router.put(
    '/:id',
    validate(serviceIdParamSchema, 'params'),
    validate(updateServiceSchema),
    serviceController.update
);

router.patch(
    '/:id',
    validate(serviceIdParamSchema, 'params'),
    validate(updateServiceSchema),
    serviceController.update
);

// 6. Toggle active status (matches Flutter repository toggleStatus)
router.patch(
    '/:id/toggle-status',
    validate(serviceIdParamSchema, 'params'),
    serviceController.toggleStatus
);

// 7. Delete service
router.delete(
    '/:id',
    validate(serviceIdParamSchema, 'params'),
    serviceController.delete
);

module.exports = router;
