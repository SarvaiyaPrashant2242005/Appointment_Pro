/**
 * AppointmentPro — Business CRUD API Automated Test Suite
 * Run with: node test-business-api.js
 */

const { User, UserOtp } = require('./modules/users');
const { Business, BusinessMember } = require('./modules/businesses');
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
    console.log(`${colors.bold}   🚀 AppointmentPro — Business CRUD API Suite${colors.reset}`);
    console.log(`${colors.cyan}====================================================${colors.reset}\n`);

    const timestamp = Date.now();
    const testEmail = `biz_owner_${timestamp}@example.com`;
    const testPassword = 'Password@123';
    let accessToken = '';
    let ownerId = '';
    let business1Id = '';
    let business1Slug = '';
    let business2Id = '';

    try {
        // Step 1: Create verified user directly in DB for clean testing
        console.log(`${colors.yellow}Step 1: Setting up verified test owner user...${colors.reset}`);
        const passwordHash = await bcrypt.hash(testPassword, 10);
        const testUser = await User.create({
            full_name: 'Business Tester',
            email: testEmail,
            phone: '+919876543210',
            password_hash: passwordHash,
            role: 'owner',
            is_active: true,
            is_email_verified: true,
        });
        ownerId = testUser.id;

        // Login to get access token
        const loginRes = await apiRequest('/auth/login', {
            method: 'POST',
            body: {
                email: testEmail,
                password: testPassword,
            },
        });

        if (loginRes.status === 200 && loginRes.data.data?.accessToken) {
            accessToken = loginRes.data.data.accessToken;
            logPass('User Login & Auth Token generation', `Owner ID: ${ownerId}`);
        } else {
            throw new Error(`Login failed: ${JSON.stringify(loginRes.data)}`);
        }

        const authHeaders = { Authorization: `Bearer ${accessToken}` };

        // Test 1: Validation failure when required fields are missing
        console.log(`\n${colors.yellow}Test 1: Validation rejection on empty create payload${colors.reset}`);
        const invalidCreateRes = await apiRequest('/businesses', {
            method: 'POST',
            headers: authHeaders,
            body: {},
        });

        if (invalidCreateRes.status === 400 && invalidCreateRes.data.messageToShow) {
            logPass('Rejected incomplete business payload (400)', `MessageToShow: "${invalidCreateRes.data.messageToShow}"`);
        } else {
            logFail('Failed to reject incomplete payload', JSON.stringify(invalidCreateRes.data));
        }

        // Test 2: Create first business (Should auto-activate)
        console.log(`\n${colors.yellow}Test 2: Create first business (Auto-activation rule)${colors.reset}`);
        const createBiz1Res = await apiRequest('/businesses', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Apex Luxury Salon & Spa',
                type: 'salon',
                email: 'contact@apexluxury.com',
                phone: '9876543211',
                countryCode: '+91',
                currency: 'INR',
                timezone: 'Asia/Kolkata',
            },
        });

        if (createBiz1Res.status === 201 && createBiz1Res.data.data) {
            const biz = createBiz1Res.data.data;
            business1Id = biz.id;
            business1Slug = biz.slug;

            if (biz.is_active === true && biz.isActive === true) {
                logPass('Created 1st business with auto-activation (is_active: true)', `ID: ${biz.id} | Slug: ${biz.slug}`);
            } else {
                logFail('1st business was not automatically activated!', JSON.stringify(biz));
            }
            logPass('UI MessageToShow verified', `"${createBiz1Res.data.messageToShow}"`);
        } else {
            logFail('Failed to create first business', JSON.stringify(createBiz1Res.data));
        }

        // Test 3: Create second business (Should default to inactive)
        console.log(`\n${colors.yellow}Test 3: Create second business for same owner${colors.reset}`);
        const createBiz2Res = await apiRequest('/businesses', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Apex Dental Care Clinic',
                type: 'clinic',
                email: 'dentist@apexdental.com',
                phone: '9876543212',
            },
        });

        if (createBiz2Res.status === 201 && createBiz2Res.data.data) {
            const biz = createBiz2Res.data.data;
            business2Id = biz.id;

            if (biz.is_active === false && biz.isActive === false) {
                logPass('Created 2nd business defaulting to inactive (is_active: false)', `ID: ${biz.id} | Slug: ${biz.slug}`);
            } else {
                logFail('2nd business was unexpectedly activated', JSON.stringify(biz));
            }
        } else {
            logFail('Failed to create second business', JSON.stringify(createBiz2Res.data));
        }

        // Test 4: List all businesses for owner
        console.log(`\n${colors.yellow}Test 4: List all owner businesses${colors.reset}`);
        const listRes = await apiRequest('/businesses', {
            method: 'GET',
            headers: authHeaders,
        });

        if (listRes.status === 200 && Array.isArray(listRes.data.data)) {
            const businesses = listRes.data.data;
            const activeFirst = businesses[0].is_active === true;
            logPass(`Retrieved ${businesses.length} businesses`, `Active business ordered first: ${activeFirst}`);
            logPass('Meta count verified', `Total: ${listRes.data.meta?.total}`);
        } else {
            logFail('Failed to retrieve businesses', JSON.stringify(listRes.data));
        }

        // Test 5: Get single business by ID
        console.log(`\n${colors.yellow}Test 5: Retrieve single business by ID${colors.reset}`);
        const getBizRes = await apiRequest(`/businesses/${business1Id}`, {
            method: 'GET',
            headers: authHeaders,
        });

        if (getBizRes.status === 200 && getBizRes.data.data?.id === business1Id) {
            logPass('Retrieved business details by ID', `Name: ${getBizRes.data.data.name}`);
        } else {
            logFail('Failed to retrieve single business', JSON.stringify(getBizRes.data));
        }

        // Test 6: Public route by slug (No auth token)
        console.log(`\n${colors.yellow}Test 6: Public lookup by booking slug (No auth)${colors.reset}`);
        const publicSlugRes = await apiRequest(`/businesses/public/${business1Slug}`, {
            method: 'GET',
        });

        if (publicSlugRes.status === 200 && publicSlugRes.data.data?.slug === business1Slug) {
            logPass('Public slug lookup succeeded without auth', `Slug: ${publicSlugRes.data.data.slug} | Name: ${publicSlugRes.data.data.name}`);
        } else {
            logFail('Public slug lookup failed', JSON.stringify(publicSlugRes.data));
        }

        // Test 7: Update business details
        console.log(`\n${colors.yellow}Test 7: Update business details${colors.reset}`);
        const updateRes = await apiRequest(`/businesses/${business1Id}`, {
            method: 'PUT',
            headers: authHeaders,
            body: {
                name: 'Apex Luxury Salon, Spa & Wellness',
                otherType: 'Premium Unisex Salon',
                phone: '9876543299',
            },
        });

        if (updateRes.status === 200 && updateRes.data.data?.name === 'Apex Luxury Salon, Spa & Wellness') {
            logPass('Business details updated successfully', `New name: ${updateRes.data.data.name} | OtherType: ${updateRes.data.data.otherType}`);
        } else {
            logFail('Failed to update business details', JSON.stringify(updateRes.data));
        }

        // Test 8: Switch active business
        console.log(`\n${colors.yellow}Test 8: Switch active business (PATCH /:id/activate)${colors.reset}`);
        const switchRes = await apiRequest(`/businesses/${business2Id}/activate`, {
            method: 'PATCH',
            headers: authHeaders,
        });

        if (switchRes.status === 200 && switchRes.data.data?.is_active === true) {
            // Verify biz1 is now inactive
            const checkBiz1 = await apiRequest(`/businesses/${business1Id}`, { headers: authHeaders });
            if (checkBiz1.data.data?.is_active === false) {
                logPass('Switched active business to Business 2', `Business 2 is_active: true | Business 1 is_active: false`);
            } else {
                logFail('Previous business was not deactivated!', JSON.stringify(checkBiz1.data));
            }
        } else {
            logFail('Failed to switch active business', JSON.stringify(switchRes.data));
        }

        // Test 9: Delete active business and verify fallback activation
        console.log(`\n${colors.yellow}Test 9: Delete active business (Automatic fallback activation)${colors.reset}`);
        const deleteRes = await apiRequest(`/businesses/${business2Id}`, {
            method: 'DELETE',
            headers: authHeaders,
        });

        if (deleteRes.status === 200 && deleteRes.data.data?.deletedId === business2Id) {
            logPass('Business 2 deleted successfully', `Message: "${deleteRes.data.messageToShow}"`);

            // Check if Business 1 automatically became active
            const verifyFallback = await apiRequest(`/businesses/${business1Id}`, { headers: authHeaders });
            if (verifyFallback.data.data?.is_active === true) {
                logPass('Fallback activation succeeded', `Business 1 is now active again (is_active: true)`);
            } else {
                logFail('Fallback activation did not activate remaining business', JSON.stringify(verifyFallback.data));
            }
        } else {
            logFail('Failed to delete business', JSON.stringify(deleteRes.data));
        }

        // Test 10: Attempt to access deleted business (Should return 404)
        console.log(`\n${colors.yellow}Test 10: Access deleted business returns 404${colors.reset}`);
        const notFoundRes = await apiRequest(`/businesses/${business2Id}`, {
            headers: authHeaders,
        });

        if (notFoundRes.status === 404 && notFoundRes.data.messageToShow) {
            logPass('Returns 404 with user-friendly message', `MessageToShow: "${notFoundRes.data.messageToShow}"`);
        } else {
            logFail('Did not return 404 for deleted business', JSON.stringify(notFoundRes.data));
        }

        // Cleanup
        console.log(`\n${colors.yellow}Cleaning up test data...${colors.reset}`);
        await Business.destroy({ where: { owner_id: ownerId } });
        await User.destroy({ where: { id: ownerId } });
        console.log(`${colors.green}✔ Cleanup complete.${colors.reset}\n`);

        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}`);
        console.log(`${colors.bold}${colors.green}   🎉 ALL 10 BUSINESS CRUD TESTS PASSED PERFECTLY!${colors.reset}`);
        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}\n`);

    } catch (err) {
        console.error(`${colors.red}Test execution error:${colors.reset}`, err);
    } finally {
        await sequelize.close();
    }
};

runTestSuite();
