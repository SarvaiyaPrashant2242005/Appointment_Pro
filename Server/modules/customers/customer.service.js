const { Op } = require('sequelize');
const { Customer } = require('./index');
const { Business, BusinessMember } = require('../businesses');

class CustomerService {
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
                    error.messageToShow = 'You do not have permission to manage customers for this business.';
                    throw error;
                }
            }

            return business;
        }

        const activeBusiness = await Business.findOne({
            where: {
                owner_id: ownerId,
                is_active: true,
            },
        });

        if (!activeBusiness) {
            const error = new Error('No active business found.');
            error.statusCode = 400;
            error.messageToShow = 'Please select or create an active business before accessing customer records.';
            throw error;
        }

        return activeBusiness;
    }

    /**
     * Create or upsert customer in business CRM ledger
     */
    async createCustomer(ownerId, data) {
        const business = await this._resolveBusiness(ownerId, data.businessId || data.business_id);

        const name = data.name.trim();
        const country_code = data.countryCode || data.country_code || '+91';
        const phone = data.phone.trim();
        const email = data.email && data.email.trim() ? data.email.trim().toLowerCase() : null;
        const notes = data.notes && data.notes.trim() ? data.notes.trim() : null;

        // Check if customer already exists for this business by phone
        let customer = await Customer.findOne({
            where: {
                business_id: business.id,
                phone,
            },
        });

        if (customer) {
            await customer.update({
                name,
                country_code,
                email: email || customer.email,
                notes: notes || customer.notes,
            });

            return {
                customer: customer.toClientJSON(),
                messageToShow: `Customer "${customer.name}" profile updated in your client directory.`,
            };
        }

        customer = await Customer.create({
            business_id: business.id,
            name,
            country_code,
            phone,
            email,
            notes,
        });

        return {
            customer: customer.toClientJSON(),
            messageToShow: `Customer "${customer.name}" added to your client directory successfully.`,
        };
    }

    /**
     * Get all customers for business (supports keyword search)
     */
    async getCustomers(ownerId, query = {}) {
        const requestedBusinessId = query.businessId || query.business_id;
        const whereClause = {};

        if (requestedBusinessId) {
            const business = await this._resolveBusiness(ownerId, requestedBusinessId);
            whereClause.business_id = business.id;
        } else {
            const userBusinesses = await Business.findAll({
                where: { owner_id: ownerId },
                attributes: ['id'],
            });
            const businessIds = userBusinesses.map((b) => b.id);
            whereClause.business_id = { [Op.in]: businessIds };
        }

        if (query.search && query.search.trim()) {
            const searchKeyword = `%${query.search.trim()}%`;
            whereClause[Op.or] = [
                { name: { [Op.iLike || Op.like]: searchKeyword } },
                { phone: { [Op.iLike || Op.like]: searchKeyword } },
                { email: { [Op.iLike || Op.like]: searchKeyword } },
            ];
        }

        const customers = await Customer.findAll({
            where: whereClause,
            order: [['name', 'ASC']],
        });

        return {
            customers: customers.map((c) => c.toClientJSON()),
            total: customers.length,
            messageToShow: customers.length > 0
                ? 'Customer list retrieved successfully.'
                : 'No customers found matching your criteria.',
        };
    }

    /**
     * Get single customer by ID
     */
    async getCustomerById(ownerId, customerId) {
        const customer = await Customer.findByPk(customerId, {
            include: [{ model: Business, as: 'business', attributes: ['id', 'owner_id', 'name'] }],
        });

        if (!customer) {
            const error = new Error('Customer not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested customer profile could not be found.';
            throw error;
        }

        if (customer.business?.owner_id !== ownerId) {
            const membership = await BusinessMember.findOne({
                where: {
                    business_id: customer.business_id,
                    user_id: ownerId,
                    is_active: true,
                },
            });

            if (!membership) {
                const error = new Error('Unauthorized.');
                error.statusCode = 403;
                error.messageToShow = 'You do not have permission to view this customer.';
                throw error;
            }
        }

        return {
            customer: customer.toClientJSON(),
            messageToShow: 'Customer details retrieved successfully.',
        };
    }

    /**
     * Update customer details
     */
    async updateCustomer(ownerId, customerId, data) {
        const customer = await Customer.findByPk(customerId, {
            include: [{ model: Business, as: 'business', attributes: ['id', 'owner_id', 'name'] }],
        });

        if (!customer) {
            const error = new Error('Customer not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested customer profile could not be found.';
            throw error;
        }

        if (customer.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to modify this customer.';
            throw error;
        }

        const updateData = {};
        if (data.name !== undefined && data.name.trim() !== '') updateData.name = data.name.trim();
        if (data.countryCode !== undefined || data.country_code !== undefined) updateData.country_code = data.countryCode || data.country_code;
        if (data.phone !== undefined && data.phone.trim() !== '') updateData.phone = data.phone.trim();
        if (data.email !== undefined) updateData.email = data.email && data.email.trim() ? data.email.trim().toLowerCase() : null;
        if (data.notes !== undefined) updateData.notes = data.notes && data.notes.trim() ? data.notes.trim() : null;

        await customer.update(updateData);

        return {
            customer: customer.toClientJSON(),
            messageToShow: `Customer "${customer.name}" profile updated successfully.`,
        };
    }

    /**
     * Delete customer
     */
    async deleteCustomer(ownerId, customerId) {
        const customer = await Customer.findByPk(customerId, {
            include: [{ model: Business, as: 'business', attributes: ['id', 'owner_id', 'name'] }],
        });

        if (!customer) {
            const error = new Error('Customer not found.');
            error.statusCode = 404;
            error.messageToShow = 'The requested customer profile could not be found.';
            throw error;
        }

        if (customer.business?.owner_id !== ownerId) {
            const error = new Error('Unauthorized.');
            error.statusCode = 403;
            error.messageToShow = 'You do not have permission to delete this customer.';
            throw error;
        }

        const customerName = customer.name;
        await customer.destroy();

        return {
            deletedId: customerId,
            messageToShow: `Customer "${customerName}" has been deleted from your directory.`,
        };
    }
}

module.exports = new CustomerService();
