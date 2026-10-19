const serviceService = require('./service.service');
const { sendSuccess } = require('../../utils/response');

class ServiceController {
    /**
     * Create a new service under a business
     * POST /api/v1/services
     */
    async create(req, res, next) {
        try {
            const result = await serviceService.createService(req.user.id, req.body);
            return sendSuccess(res, {
                statusCode: 201,
                message: 'Service created successfully.',
                messageToShow: result.messageToShow,
                data: result.service,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Get all services for owner's business(es)
     * GET /api/v1/services?businessId=...&isActive=...
     */
    async getAll(req, res, next) {
        try {
            const result = await serviceService.getServices(req.user.id, req.query);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Services retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.services,
                meta: { total: result.total },
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Get single service by ID
     * GET /api/v1/services/:id
     */
    async getById(req, res, next) {
        try {
            const result = await serviceService.getServiceById(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Service retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.service,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Public route: Get all active services for booking by business slug
     * GET /api/v1/services/public/:businessSlug
     */
    async getPublicBySlug(req, res, next) {
        try {
            const result = await serviceService.getPublicServicesBySlug(req.params.businessSlug);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Services retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.services,
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
     * Update an existing service
     * PUT /api/v1/services/:id or PATCH /api/v1/services/:id
     */
    async update(req, res, next) {
        try {
            const result = await serviceService.updateService(req.user.id, req.params.id, req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Service updated successfully.',
                messageToShow: result.messageToShow,
                data: result.service,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Toggle active/inactive status
     * PATCH /api/v1/services/:id/toggle-status
     */
    async toggleStatus(req, res, next) {
        try {
            const result = await serviceService.toggleServiceStatus(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Service status updated successfully.',
                messageToShow: result.messageToShow,
                data: result.service,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Delete service
     * DELETE /api/v1/services/:id
     */
    async delete(req, res, next) {
        try {
            const result = await serviceService.deleteService(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Service deleted successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new ServiceController();
