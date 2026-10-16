const availabilityService = require('./availability.service');
const { sendSuccess } = require('../../utils/response');

class AvailabilityController {
    /**
     * Get business operating hours & breaks
     * GET /api/v1/availability/operating-hours?businessId=...
     */
    async getOperatingHours(req, res, next) {
        try {
            const requestedBusinessId = req.query.businessId || req.query.business_id || req.params.businessId;
            const result = await availabilityService.getBusinessOperatingHours(req.user.id, requestedBusinessId);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Business operating hours retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Save/update weekly schedule and schedule breaks
     * PUT /api/v1/availability/operating-hours
     */
    async updateOperatingHours(req, res, next) {
        try {
            const result = await availabilityService.updateBusinessOperatingHours(req.user.id, req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Operating hours and breaks saved successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Quick toggle open/closed for a specific day
     * PATCH /api/v1/availability/operating-hours/:dayOfWeek/toggle
     */
    async toggleDayStatus(req, res, next) {
        try {
            const requestedBusinessId = req.body?.businessId || req.query?.businessId;
            const result = await availabilityService.toggleDayStatus(req.user.id, req.params.dayOfWeek, requestedBusinessId);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Operating status updated successfully.',
                messageToShow: result.messageToShow,
                data: result.day,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * Public route: Get operating hours by business slug for customer booking
     * GET /api/v1/availability/public/:businessSlug
     */
    async getPublicBySlug(req, res, next) {
        try {
            const result = await availabilityService.getPublicOperatingHoursBySlug(req.params.businessSlug);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Business operating hours loaded successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new AvailabilityController();
