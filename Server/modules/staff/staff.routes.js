const express = require('express');
const router = express.Router();

const staffController = require('./staff.controller');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const { uploadAvatar } = require('../../middlewares/upload.middleware');
const {
    createStaffSchema,
    updateStaffSchema,
    staffIdParamSchema,
    businessSlugParamSchema,
    listStaffQuerySchema,
} = require('../../validators/staff.validator');

// 1. Public route: Retrieve active staff for customer appointment booking
router.get(
    '/public/:businessSlug',
    validate(businessSlugParamSchema, 'params'),
    staffController.getPublicBySlug
);

// All subsequent routes require user authentication
router.use(authenticate);

// 2. Create a new staff member (supports avatar upload)
router.post(
    '/',
    uploadAvatar.single('avatar'),
    validate(createStaffSchema),
    staffController.create
);

// 3. List staff members (with optional ?businessId=..., ?serviceId=..., ?isActive=... query filters)
router.get(
    '/',
    validate(listStaffQuerySchema, 'query'),
    staffController.getAll
);

// 4. Get specific staff member by ID
router.get(
    '/:id',
    validate(staffIdParamSchema, 'params'),
    staffController.getById
);

// 5. Update staff member details / avatar (supports PUT & PATCH)
router.put(
    '/:id',
    uploadAvatar.single('avatar'),
    validate(staffIdParamSchema, 'params'),
    validate(updateStaffSchema),
    staffController.update
);

router.patch(
    '/:id',
    uploadAvatar.single('avatar'),
    validate(staffIdParamSchema, 'params'),
    validate(updateStaffSchema),
    staffController.update
);

// 6. Toggle staff active status
router.patch(
    '/:id/toggle-status',
    validate(staffIdParamSchema, 'params'),
    staffController.toggleStatus
);

// 7. Delete staff member
router.delete(
    '/:id',
    validate(staffIdParamSchema, 'params'),
    staffController.delete
);

module.exports = router;
