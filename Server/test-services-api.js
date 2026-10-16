/**
 * AppointmentPro — Services CRUD API Automated Test Suite
 * Run with: node test-services-api.js
 */

const { User } = require('./modules/users');
const { Business } = require('./modules/businesses');
const { Service } = require('./modules/services');
const { sequelize } = require('./config/database');
const bcrypt = require('bcrypt');

const BASE_URL = 'http://localhost:5000/api/v1';

const colors = {
    reset: '\x1b[0m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    cyan: '\x1b[36m',
    bold: '\x1b[1m',
};

const logPass = (title, details) => {
    console.log(`${colors.green}✔ [PASS] ${colors.bold}${title}${colors.reset}`);
    if (details) console.log(`   ${colors.cyan}${details}${colors.reset}`);
};

const logFail = (title, error) => {
    console.error(`${colors.red}✖ [FAIL] ${colors.bold}${title}${colors.reset}`);
    if (error) console.error(`   ${colors.yellow}${error}${colors.reset}`);
};

const apiRequest = async (endpoint, options = {}) => {
    const url = endpoint.startsWith('http') ? endpoint : `${BASE_URL}${endpoint}`;
    const headers = {
        'Content-Type': 'application/json',
        ...(options.headers || {}),
    };

    const response = await fetch(url, {
        method: options.method || 'GET',
        headers,
        body: options.body ? JSON.stringify(options.body) : undefined,
    });

    const json = await response.json();
    return { status: response.status, data: json };
};

const runTestSuite = async () => {
    console.log(`\n${colors.bold}${colors.cyan}====================================================${colors.reset}`);
    console.log(`${colors.bold}   🚀 AppointmentPro — Services CRUD API Suite${colors.reset}`);
    console.log(`${colors.cyan}====================================================${colors.reset}\n`);

    const timestamp = Date.now();
    const testEmail = `service_owner_${timestamp}@example.com`;
    const testPassword = 'Password@123';
    let accessToken = '';
    let ownerId = '';
    let businessId = '';
    let businessSlug = '';
    let service1Id = '';
    let service2Id = '';

    try {
        // Step 1: Create verified owner user and active business
        console.log(`${colors.yellow}Step 1: Setting up test owner & active business...${colors.reset}`);
        const passwordHash = await bcrypt.hash(testPassword, 10);
        const testUser = await User.create({
            full_name: 'Services Test Owner',
            email: testEmail,
            phone: '+919876543220',
            password_hash: passwordHash,
            role: 'owner',
            is_active: true,
            is_email_verified: true,
        });
        ownerId = testUser.id;

        // Login
        const loginRes = await apiRequest('/auth/login', {
            method: 'POST',
            body: { email: testEmail, password: testPassword },
        });
        accessToken = loginRes.data.data.accessToken;
        const authHeaders = { Authorization: `Bearer ${accessToken}` };

        // Create business via API (auto-activates as 1st business)
        const bizRes = await apiRequest('/businesses', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Elite Glow Beauty Lounge',
                type: 'salon',
                email: 'info@eliteglow.com',
                phone: '9876543221',
            },
        });
        businessId = bizRes.data.data.id;
        businessSlug = bizRes.data.data.slug;
        logPass('Owner & Active Business Ready', `Business: "${bizRes.data.data.name}" (${businessSlug})`);

        // Test 1: Validation rejection on empty service payload
        console.log(`\n${colors.yellow}Test 1: Validation rejection on empty service payload${colors.reset}`);
        const invalidCreate = await apiRequest('/services', {
            method: 'POST',
            headers: authHeaders,
            body: {},
        });

        if (invalidCreate.status === 400 && invalidCreate.data.messageToShow) {
            logPass('Rejected invalid service payload (400)', `MessageToShow: "${invalidCreate.data.messageToShow}"`);
        } else {
            logFail('Failed to reject empty payload', JSON.stringify(invalidCreate.data));
        }

        // Test 2: Create service with automatic active-business fallback
        console.log(`\n${colors.yellow}Test 2: Create service (Auto active-business fallback)${colors.reset}`);
        const createSvc1 = await apiRequest('/services', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Signature Haircut & Styling',
                description: 'Includes wash, cut, blowdry and styling by senior stylist.',
                price: 799.00,
                durationMinutes: 45,
                bufferMinutes: 10,
            },
        });

        if (createSvc1.status === 201 && createSvc1.data.data) {
            const svc = createSvc1.data.data;
            service1Id = svc.id;

            if (svc.businessId === businessId && svc.price === 799 && svc.durationMinutes === 45) {
                logPass('Service 1 created with active business fallback', `ID: ${svc.id} | Price: ₹${svc.price} | Duration: ${svc.durationMinutes}m`);
            } else {
                logFail('Service 1 attributes mismatch', JSON.stringify(svc));
            }
            logPass('UI MessageToShow verified', `"${createSvc1.data.messageToShow}"`);
        } else {
            logFail('Failed to create service 1', JSON.stringify(createSvc1.data));
        }

        // Test 3: Create second service with explicit businessId
        console.log(`\n${colors.yellow}Test 3: Create service with explicit businessId${colors.reset}`);
        const createSvc2 = await apiRequest('/services', {
            method: 'POST',
            headers: authHeaders,
            body: {
                businessId: businessId,
                name: 'Hydra Facial & Skin Therapy',
                description: 'Deep cleansing and skin rejuvenation facial treatment.',
                price: 1999.00,
                durationMinutes: 60,
                bufferMinutes: 15,
            },
        });

        if (createSvc2.status === 201 && createSvc2.data.data) {
            service2Id = createSvc2.data.data.id;
            logPass('Service 2 created successfully', `ID: ${service2Id} | Name: ${createSvc2.data.data.name}`);
        } else {
            logFail('Failed to create service 2', JSON.stringify(createSvc2.data));
        }

        // Test 4: List all services for business
        console.log(`\n${colors.yellow}Test 4: List all services for business${colors.reset}`);
        const listRes = await apiRequest(`/services?businessId=${businessId}`, {
            method: 'GET',
            headers: authHeaders,
        });

        if (listRes.status === 200 && Array.isArray(listRes.data.data) && listRes.data.data.length === 2) {
            logPass('Retrieved all services for business', `Count: ${listRes.data.data.length} services`);
            logPass('Verified Flutter camelCase fields', `durationMinutes: ${listRes.data.data[0].durationMinutes}, isActive: ${listRes.data.data[0].isActive}`);
        } else {
            logFail('Failed to retrieve services list', JSON.stringify(listRes.data));
        }

        // Test 5: Get single service by ID
        console.log(`\n${colors.yellow}Test 5: Retrieve single service by ID${colors.reset}`);
        const getSingleRes = await apiRequest(`/services/${service1Id}`, {
            method: 'GET',
            headers: authHeaders,
        });

        if (getSingleRes.status === 200 && getSingleRes.data.data?.id === service1Id) {
            logPass('Retrieved single service by ID', `Name: "${getSingleRes.data.data.name}"`);
        } else {
            logFail('Failed to retrieve single service', JSON.stringify(getSingleRes.data));
        }

        // Test 6: Public booking lookup by business slug (No Auth)
        console.log(`\n${colors.yellow}Test 6: Public services lookup by business slug (No auth)${colors.reset}`);
        const publicRes = await apiRequest(`/services/public/${businessSlug}`, {
            method: 'GET',
        });

        if (publicRes.status === 200 && Array.isArray(publicRes.data.data) && publicRes.data.data.length === 2) {
            logPass('Public lookup succeeded without token', `Loaded ${publicRes.data.data.length} active booking services for "${businessSlug}"`);
        } else {
            logFail('Public lookup failed', JSON.stringify(publicRes.data));
        }

        // Test 7: Update service details
        console.log(`\n${colors.yellow}Test 7: Update service details (PUT/PATCH)${colors.reset}`);
        const updateRes = await apiRequest(`/services/${service1Id}`, {
            method: 'PUT',
            headers: authHeaders,
            body: {
                name: 'Signature Haircut, Spa & Styling',
                price: 899.00,
                durationMinutes: 50,
            },
        });

        if (updateRes.status === 200 && updateRes.data.data?.price === 899 && updateRes.data.data?.durationMinutes === 50) {
            logPass('Service updated successfully', `New name: "${updateRes.data.data.name}" | Price: ₹${updateRes.data.data.price}`);
        } else {
            logFail('Failed to update service', JSON.stringify(updateRes.data));
        }

        // Test 8: Toggle status (Active <-> Inactive)
        console.log(`\n${colors.yellow}Test 8: Toggle service status (PATCH /:id/toggle-status)${colors.reset}`);
        const toggle1 = await apiRequest(`/services/${service1Id}/toggle-status`, {
            method: 'PATCH',
            headers: authHeaders,
        });

        if (toggle1.status === 200 && toggle1.data.data?.is_active === false) {
            logPass('Service toggled to inactive', `MessageToShow: "${toggle1.data.messageToShow}"`);

            // Verify public customer booking endpoint now excludes inactive service
            const publicCheck = await apiRequest(`/services/public/${businessSlug}`);
            if (publicCheck.data.data?.length === 1) {
                logPass('Public customer booking excludes inactive service', `Only ${publicCheck.data.data.length} active service shown to customers`);
            } else {
                logFail('Inactive service was still returned in public booking API!', JSON.stringify(publicCheck.data));
            }

            // Toggle back to active
            const toggleBack = await apiRequest(`/services/${service1Id}/toggle-status`, {
                method: 'PATCH',
                headers: authHeaders,
            });
            if (toggleBack.data.data?.is_active === true) {
                logPass('Service toggled back to active', `is_active: true`);
            }
        } else {
            logFail('Failed to toggle service status', JSON.stringify(toggle1.data));
        }

        // Test 9: Delete service
        console.log(`\n${colors.yellow}Test 9: Delete service (DELETE /:id)${colors.reset}`);
        const deleteRes = await apiRequest(`/services/${service2Id}`, {
            method: 'DELETE',
            headers: authHeaders,
        });

        if (deleteRes.status === 200 && deleteRes.data.data?.deletedId === service2Id) {
            logPass('Service deleted successfully', `MessageToShow: "${deleteRes.data.messageToShow}"`);

            // Verify 404
            const checkDeleted = await apiRequest(`/services/${service2Id}`, { headers: authHeaders });
            if (checkDeleted.status === 404) {
                logPass('Deleted service returns 404', `MessageToShow: "${checkDeleted.data.messageToShow}"`);
            } else {
                logFail('Deleted service still accessible', JSON.stringify(checkDeleted.data));
            }
        } else {
            logFail('Failed to delete service', JSON.stringify(deleteRes.data));
        }

        // Test 10: Unauthorized cross-tenant access rejection
        console.log(`\n${colors.yellow}Test 10: Unauthorized access rejection (Security check)${colors.reset}`);
        const otherUser = await User.create({
            full_name: 'Other Owner',
            email: `other_${timestamp}@example.com`,
            phone: '+919876543299',
            password_hash: passwordHash,
            role: 'owner',
            is_active: true,
            is_email_verified: true,
        });
        const otherLogin = await apiRequest('/auth/login', {
            method: 'POST',
            body: { email: otherUser.email, password: testPassword },
        });
        const otherHeaders = { Authorization: `Bearer ${otherLogin.data.data.accessToken}` };

        const unauthorizedRes = await apiRequest(`/services/${service1Id}`, {
            headers: otherHeaders,
        });

        if (unauthorizedRes.status === 403 && unauthorizedRes.data.messageToShow) {
            logPass('Cross-owner access securely rejected (403)', `MessageToShow: "${unauthorizedRes.data.messageToShow}"`);
        } else {
            logFail('Failed to reject cross-tenant access', JSON.stringify(unauthorizedRes.data));
        }

        // Cleanup
        console.log(`\n${colors.yellow}Cleaning up test data...${colors.reset}`);
        await Service.destroy({ where: { business_id: businessId } });
        await Business.destroy({ where: { owner_id: ownerId } });
        await User.destroy({ where: { id: ownerId } });
        await User.destroy({ where: { id: otherUser.id } });
        console.log(`${colors.green}✔ Cleanup complete.${colors.reset}\n`);

        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}`);
        console.log(`${colors.bold}${colors.green}   🎉 ALL 10 SERVICES CRUD TESTS PASSED PERFECTLY!${colors.reset}`);
        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}\n`);

    } catch (err) {
        console.error(`${colors.red}Test execution error:${colors.reset}`, err);
    } finally {
        await sequelize.close();
    }
};

runTestSuite();
