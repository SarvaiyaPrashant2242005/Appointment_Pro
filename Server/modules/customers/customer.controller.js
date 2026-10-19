const customerService = require('./customer.service');
const { sendSuccess } = require('../../utils/response');

class CustomerController {
    async create(req, res, next) {
        try {
            const result = await customerService.createCustomer(req.user.id, req.body);
            return sendSuccess(res, {
                statusCode: 201,
                message: 'Customer saved successfully.',
                messageToShow: result.messageToShow,
                data: result.customer,
            });
        } catch (error) {
            next(error);
        }
    }

    async getAll(req, res, next) {
        try {
            const result = await customerService.getCustomers(req.user.id, req.query);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Customers retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.customers,
                meta: { total: result.total },
            });
        } catch (error) {
            next(error);
        }
    }

    async getById(req, res, next) {
        try {
            const result = await customerService.getCustomerById(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Customer retrieved successfully.',
                messageToShow: result.messageToShow,
                data: result.customer,
            });
        } catch (error) {
            next(error);
        }
    }

    async update(req, res, next) {
        try {
            const result = await customerService.updateCustomer(req.user.id, req.params.id, req.body);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Customer updated successfully.',
                messageToShow: result.messageToShow,
                data: result.customer,
            });
        } catch (error) {
            next(error);
        }
    }

    async delete(req, res, next) {
        try {
            const result = await customerService.deleteCustomer(req.user.id, req.params.id);
            return sendSuccess(res, {
                statusCode: 200,
                message: 'Customer deleted successfully.',
                messageToShow: result.messageToShow,
                data: result,
            });
        } catch (error) {
            next(error);
        }
    }
}

module.exports = new CustomerController();
