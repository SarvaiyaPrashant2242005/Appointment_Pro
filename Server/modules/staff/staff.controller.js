const staffService = require('./staff.service');
const { sendSuccess } = require('../../utils/response');

class StaffController {
    /**
     * Create a new staff member
     * POST /api/v1/staff
     */
    async create(req, res, next) {
        try {
            const result = await staffService.createStaff(req.user.id, req.body, req.file);
            return sendSuccess(res, {
                statusCode: 201,
                message: 'Staff member created successfully.',
                messageToShow: result.messageToShow,
                data: result.staff,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Get all staff for owner's business
     * GET /api/v1/staff?businessId=...&serviceId=...&isActive=...
     */
    async getAll(req, res, next) {
        try {
            const result = await staffService.getStaff(req.user.id, req.query);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Staff team retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.staff,
                meta: { total: result.total },
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Get single staff member by ID
     * GET /api/v1/staff/:id
     */
    async getById(req, res, next) {
        try {
            const result = await staffService.getStaffById(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Staff member retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.staff,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Public route: Get active staff by business slug (optionally filtered by ?serviceId=)
     * GET /api/v1/staff/public/:businessSlug
     */
    async getPublicBySlug(req, res, next) {
        try {
            const result = await staffService.getPublicStaffBySlug(req.params.businessSlug, req.query);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Staff members retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.staff,
                meta: {
                    business: result.business,
                    total: result.total,
                },
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Update staff member details or avatar
     * PUT /api/v1/staff/:id or PATCH /api/v1/staff/:id
     */
    async update(req, res, next) {
        try {
            const result = await staffService.updateStaff(req.user.id, req.params.id, req.body, req.file);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Staff member updated successfully.',
                messageToShow: result.messageToShow,
                data: result.staff,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Toggle active/inactive status
     * PATCH /api/v1/staff/:id/toggle-status
     */
    async toggleStatus(req, res, next) {
        try {
            const result = await staffService.toggleStaffStatus(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Staff status updated successfully.',
                messageToShow: result.messageToShow,
                data: result.staff,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Delete staff member
     * DELETE /api/v1/staff/:id
     */
    async delete(req, res, next) {
        try {
            const result = await staffService.deleteStaff(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Staff member deleted successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new StaffController();
