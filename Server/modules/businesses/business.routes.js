const express = require('express');
const router = express.Router();

const businessController = require('./business.controller');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const { uploadBusinessLogo } = require('../../middlewares/upload.middleware');
const {
    createBusinessSchema,
    updateBusinessSchema,
    businessIdParamSchema,
    businessSlugParamSchema,
} = require('../../validators/business.validator');

// 1. Public route: Retrieve business by slug for booking (No authentication required)
router.get(
    '/public/:slug',
    validate(businessSlugParamSchema, 'params'),
    businessController.getPublicBySlug
);

// All subsequent routes require user authentication
router.use(authenticate);

// 2. Create a new business (supports optional multipart logo upload)
router.post(
    '/',
    uploadBusinessLogo.single('logo'),
    validate(createBusinessSchema),
    businessController.create
);

// 3. List all businesses owned by authenticated user
router.get(
    '/',
    businessController.getAll
);

// 4. Get specific business by ID
router.get(
    '/:id',
    validate(businessIdParamSchema, 'params'),
    businessController.getById
);

// 5. Update business details / logo (supports PUT & PATCH)
router.put(
    '/:id',
    uploadBusinessLogo.single('logo'),
    validate(businessIdParamSchema, 'params'),
    validate(updateBusinessSchema),
    businessController.update
);

router.patch(
    '/:id',
    uploadBusinessLogo.single('logo'),
    validate(businessIdParamSchema, 'params'),
    validate(updateBusinessSchema),
    businessController.update
);

// 6. Switch active business
router.patch(
    '/:id/activate',
    validate(businessIdParamSchema, 'params'),
    businessController.setActive
);

// 7. Delete business
router.delete(
    '/:id',
    validate(businessIdParamSchema, 'params'),
    businessController.delete
);

module.exports = router;
