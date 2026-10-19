const businessService = require('./business.service');
const { sendSuccess } = require('../../utils/response');

class BusinessController {
    /**
     * Create a new business
     * POST /api/v1/businesses
     */
    async create(req, res, next) {
        try {
            const result = await businessService.createBusiness(req.user.id, req.body, req.file);
            return sendSuccess(res, {
                statusCode: 201,
                message: 'Business created successfully.',
                messageToShow: result.messageToShow,
                data: result.business,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Get all businesses owned by user
     * GET /api/v1/businesses
     */
    async getAll(req, res, next) {
        try {
            const result = await businessService.getBusinesses(req.user.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Businesses retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.businesses,
                meta: { total: result.total },
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Get single business by ID
     * GET /api/v1/businesses/:id
     */
    async getById(req, res, next) {
        try {
            const result = await businessService.getBusinessById(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Business retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.business,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Public business profile by slug (for customer appointment booking)
     * GET /api/v1/businesses/public/:slug
     */
    async getPublicBySlug(req, res, next) {
        try {
            const result = await businessService.getPublicBusinessBySlug(req.params.slug);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Business details retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.business,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Update business details or replace logo
     * PUT /api/v1/businesses/:id or PATCH /api/v1/businesses/:id
     */
    async update(req, res, next) {
        try {
            const result = await businessService.updateBusiness(req.user.id, req.params.id, req.body, req.file);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Business updated successfully.',
                messageToShow: result.messageToShow,
                data: result.business,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Switch active business
     * PATCH /api/v1/businesses/:id/activate
     */
    async setActive(req, res, next) {
        try {
            const result = await businessService.setActiveBusiness(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Active business updated successfully.',
                messageToShow: result.messageToShow,
                data: result.business,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Delete business
     * DELETE /api/v1/businesses/:id
     */
    async delete(req, res, next) {
        try {
            const result = await businessService.deleteBusiness(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Business deleted successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new BusinessController();
