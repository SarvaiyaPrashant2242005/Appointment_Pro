const express = require('express');
const router = express.Router();

const customerController = require('./customer.controller');
const authenticate = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const {
    createCustomerSchema,
    updateCustomerSchema,
    customerIdParamSchema,
    listCustomersQuerySchema,
} = require('../../validators/customer.validator');

router.use(authenticate);

// 1. Create / Upsert customer
router.post('/', validate(createCustomerSchema), customerController.create);

// 2. List customers
router.get('/', validate(listCustomersQuerySchema, 'query'), customerController.getAll);

// 3. Get customer by ID
router.get('/:id', validate(customerIdParamSchema, 'params'), customerController.getById);

// 4. Update customer
router.put('/:id', validate(customerIdParamSchema, 'params'), validate(updateCustomerSchema), customerController.update);
router.patch('/:id', validate(customerIdParamSchema, 'params'), validate(updateCustomerSchema), customerController.update);

// 5. Delete customer
router.delete('/:id', validate(customerIdParamSchema, 'params'), customerController.delete);

module.exports = router;
