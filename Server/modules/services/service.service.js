const { Op } = require('sequelize');
const { Service } = require('./index');
const { Business, BusinessMember } = require('../businesses');

class ServiceService {
    /**
     * Helper to verify business ownership or resolve user's active business
     */
    async _resolveBusiness(ownerId, requestedBusinessId) {
        if (requestedBusinessId) {
            const business = await Business.findOne({
                where: { id: requestedBusinessId },
            });

            if (!business) {
                const error = new Error('Business not found.');
                error.statusCode = 404;
                error.messageToShow = 'The requested business could not be found.';
                throw error;
            }

            // Check if user is owner or an active member
            const isOwner = business.owner_id === ownerId;
            if (!isOwner) {
                const membership = await BusinessMember.findOne({
                    where: {
                        business_id: requestedBusinessId,
                        user_id: ownerId,
                        is_active: true,
                    },
                });

                if (!membership) {
                    const error = new Error('Unauthorized business access.');
                    error.statusCode = 403;
                    error.messageToShow = 'You do not have permission to manage services for this business.';
                    throw error;
                }
            }

            return business;
        }

        // If no businessId passed, fallback to user's active business
        const activeBusiness = await Business.findOne({
            where: {
                owner_id: ownerId,
                is_active: true,
            },
        });

        if (!activeBusiness) {
            const error = new Error('No active business found.');
            error.statusCode = 400;
            error.messageToShow = 'Please select or create an active business before adding services.';
            throw error;
        }

        return activeBusiness;
    }

    /**
     * Create a new service under a business
     */
    async createService(ownerId, data) {
        const business = await this._resolveBusiness(ownerId, data.businessId || data.business_id);

        const name = data.name.trim();
        const description = (data.description && data.description.trim()) ? data.description.trim() : null;
        const price = data.price !== undefined ? parseFloat(data.price) : 0.00;
        const duration_minutes = parseInt(data.durationMinutes || data.duration_minutes || 30, 10);
        const buffer_minutes = parseInt(data.bufferMinutes || data.buffer_minutes || 0, 10);
        
        const is_active = (data.isActive !== undefined)
            ? Boolean(data.isActive)
            : ((data.is_active !== undefined) ? Boolean(data.is_active) : true);

        const newService = await Service.create({
            business_id: business.id,
            name,
            description,
            price,
            duration_minutes,
            buffer_minutes,
            is_active,
        });

        return {
            service: newService.toClientJSON(),
            messageToShow: `"${newService.name}" service has been created successfully.`,
        };
    }

    /**
     * Get all services for owner's business(es)
     */
    async getServices(ownerId, query = {}) {
        const requestedBusinessId = query.businessId || query.business_id;
        const whereClause = {};

        if (requestedBusinessId) {
            // Verify access to specific business
            const business = await this._resolveBusiness(ownerId, requestedBusinessId);
            whereClause.business_id = business.id;
        } else {
            // Find all businesses user owns or is a member of
            const userBusinesses = await Business.findAll({
                where: { owner_id: ownerId },
                attributes: ['id'],
            });
            const businessIds = userBusinesses.map((b) => b.id);
            whereClause.business_id = { [Op.in]: businessIds };
        }

        // Optional filter by active status
        if (query.isActive !== undefined || query.is_active !== undefined) {
            const activeFilter = query.isActive !== undefined ? query.isActive : query.is_active;
            whereClause.is_active = activeFilter === true || activeFilter === 'true';
        }

        const services = await Service.findAll({
            where: whereClause,
            order: [
                ['is_active', 'DESC'],
                ['created_at', 'DESC'],
            ],
            include: [
                {
                    model: Business,
                    as: 'business',
                    attributes: ['id', 'name', 'currency'],
                },
            ],
        });

        return {
            services: services.map((s) => s.toClientJSON()),
            total: services.length,
            messageToShow: services.length > 0
                ? 'Services retrieved successfully.'
                : 'No services found. You can add your first service to get started.',
        };
    }

    /**
     * Get single service by ID
     */
    async getServiceById(ownerId, serviceId) {
        const service = await Service.findByPk(serviceId, {
            include: [
                {
                    model: Business,
                    as: 'business',
                    attributes: ['id', 'owner_id', 'name', 'currency'],
                },
            ],
        });

        if (!service) {
            const error = new Error('Service not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested service could not be found.';
            throw error;
        }

        // Verify owner permission
        if (service.business?.owner_id !== ownerId) {
            const membership = await BusinessMember.findOne({
                where: {
                    business_id: service.business_id,
                    user_id: ownerId,
                    is_active: true,
                },
            });

            if (!membership) {
                const error = new Error('Unauthorized service access.');
                error.statusCode = 403;
                error.messageToShow = 'You do not have permission to view this service.';
                throw error;
            }
        }

        return {
            service: service.toClientJSON(),
            messageToShow: 'Service details retrieved successfully.',
        };
    }

    /**
     * Public lookup by business booking link slug (for customer online booking)
     */
    async getPublicServicesBySlug(businessSlug) {
        const cleanSlug = businessSlug.trim().toLowerCase();
        const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(businessSlug.trim());

        const business = await Business.findOne({
            where: isUUID
                ? { [Op.or]: [{ id: businessSlug.trim() }, { slug: cleanSlug }] }
                : { slug: cleanSlug },
            attributes: ['id', 'name', 'slug', 'currency', 'timezone', 'is_active'],
        });

        if (!business) {
            const error = new Error('Business not found with this booking link.');
            error.statusCode = 404;
            error.messageToShow = 'No business was found with this booking link.';
            throw error;
        }

        const services = await Service.findAll({
            where: {
                business_id: business.id,
                is_active: true,
            },
            order: [['name', 'ASC']],
        });

        return {
            business: business.toClientJSON(),
            services: services.map((s) => s.toClientJSON()),
            total: services.length,
            messageToShow: 'Services loaded successfully.',
        };
    }

    /**
     * Update an existing service
     */
    async updateService(ownerId, serviceId, data) {
        const service = await Service.findByPk(serviceId, {
            include: [
                {
                    model: Business,
                    as: 'business',
                    attributes: ['id', 'owner_id', 'name'],
                },
            ],
        });

        if (!service) {
            const error = new Error('Service not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested service could not be found.';
            throw error;
        }

        // Verify permission
        if (service.business?.owner_id !== ownerId) {
            const membership = await BusinessMember.findOne({
                where: {
                    business_id: service.business_id,
                    user_id: ownerId,
                    is_active: true,
                },
            });

            if (!membership) {
                const error = new Error('Unauthorized service update.');
                error.statusCode = 403;
                error.messageToShow = 'You do not have permission to modify this service.';
                throw error;
            }
        }

        const updateData = {};

        if (data.name !== undefined && data.name.trim() !== '') {
            updateData.name = data.name.trim();
        }
        if (data.description !== undefined) {
            updateData.description = data.description ? data.description.trim() : null;
        }
        if (data.price !== undefined) {
            updateData.price = parseFloat(data.price);
        }
        if (data.durationMinutes !== undefined || data.duration_minutes !== undefined) {
            updateData.duration_minutes = parseInt(data.durationMinutes || data.duration_minutes, 10);
        }
        if (data.bufferMinutes !== undefined || data.buffer_minutes !== undefined) {
            updateData.buffer_minutes = parseInt(data.bufferMinutes || data.buffer_minutes, 10);
        }
        if (data.isActive !== undefined || data.is_active !== undefined) {
            const activeVal = data.isActive !== undefined ? data.isActive : data.is_active;
            updateData.is_active = activeVal === true || activeVal === 'true';
        }

        await service.update(updateData);
        await service.reload();

        return {
            service: service.toClientJSON(),
            messageToShow: `"${service.name}" service updated successfully.`,
        };
    }

    /**
     * Toggle active/inactive status
     */
    async toggleServiceStatus(ownerId, serviceId) {
        const service = await Service.findByPk(serviceId, {
            include: [
                {
                    model: Business,
                    as: 'business',
                    attributes: ['id', 'owner_id', 'name'],
                },
            ],
        });

        if (!service) {
            const error = new Error('Service not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested service could not be found.';
            throw error;
        }

        if (service.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to modify this service.';
            throw error;
        }

        const newStatus = !service.is_active;
        await service.update({ is_active: newStatus });

        return {
            service: service.toClientJSON(),
            messageToShow: `"${service.name}" is now ${newStatus ? 'active' : 'inactive'}.`,
        };
    }

    /**
     * Delete service
     */
    async deleteService(ownerId, serviceId) {
        const service = await Service.findByPk(serviceId, {
            include: [
                {
                    model: Business,
                    as: 'business',
                    attributes: ['id', 'owner_id', 'name'],
                },
            ],
        });

        if (!service) {
            const error = new Error('Service not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested service could not be found.';
            throw error;
        }

        if (service.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to delete this service.';
            throw error;
        }

        const serviceName = service.name;
        await service.destroy();

        return {
            deletedId: serviceId,
            messageToShow: `"${serviceName}" service has been deleted successfully.`,
        };
    }
}

module.exports = new ServiceService();
