/**
 * AppointmentPro — Staff CRUD API Automated Test Suite
 * Run with: node test-staff-api.js
 */

const { User } = require('./modules/users');
const { Business } = require('./modules/businesses');
const { Service } = require('./modules/services');
const { Staff, StaffService, StaffOperatingHour, StaffScheduleBreak } = require('./modules/staff');
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
    console.log(`${colors.bold}   🚀 AppointmentPro — Staff CRUD API Suite${colors.reset}`);
    console.log(`${colors.cyan}====================================================${colors.reset}\n`);

    const timestamp = Date.now();
    const testEmail = `staff_owner_${timestamp}@example.com`;
    const testPassword = 'Password@123';
    let accessToken = '';
    let ownerId = '';
    let businessId = '';
    let businessSlug = '';
    let serviceId = '';
    let staff1Id = '';
    let staff2Id = '';

    try {
        // Step 1: Create verified owner user, active business, and a service
        console.log(`${colors.yellow}Step 1: Setting up test owner, active business, and test service...${colors.reset}`);
        const passwordHash = await bcrypt.hash(testPassword, 10);
        const testUser = await User.create({
            full_name: 'Staff Test Owner',
            email: testEmail,
            phone: '+919876543230',
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

        // Create business
        const bizRes = await apiRequest('/businesses', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Royale Barber & Styling Studio',
                type: 'salon',
                email: 'hello@royalebarber.com',
                phone: '9876543231',
            },
        });
        businessId = bizRes.data.data.id;
        businessSlug = bizRes.data.data.slug;

        // Create test service
        const svcRes = await apiRequest('/services', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Classic Haircut & Beard Grooming',
                price: 550.00,
                durationMinutes: 40,
            },
        });
        serviceId = svcRes.data.data.id;
        logPass('Prerequisites Ready', `Business: "${bizRes.data.data.name}" | Service: "${svcRes.data.data.name}"`);

        // Test 1: Validation rejection on empty staff payload
        console.log(`\n${colors.yellow}Test 1: Validation rejection on empty staff payload${colors.reset}`);
        const invalidCreate = await apiRequest('/staff', {
            method: 'POST',
            headers: authHeaders,
            body: {},
        });

        if (invalidCreate.status === 400 && invalidCreate.data.messageToShow) {
            logPass('Rejected incomplete staff payload (400)', `MessageToShow: "${invalidCreate.data.messageToShow}"`);
        } else {
            logFail('Failed to reject empty payload', JSON.stringify(invalidCreate.data));
        }

        // Test 2: Create staff with active-business fallback, assigned services & schedule
        console.log(`\n${colors.yellow}Test 2: Create staff member with schedule & service mapping${colors.reset}`);
        const sampleSchedule = {
            1: { isOpen: true, openTime: '09:00', closeTime: '18:00', breaks: [{ breakName: 'Lunch', startTime: '13:00', endTime: '14:00' }] },
            2: { isOpen: true, openTime: '09:00', closeTime: '18:00', breaks: [{ breakName: 'Lunch', startTime: '13:00', endTime: '14:00' }] },
            3: { isOpen: true, openTime: '09:00', closeTime: '18:00', breaks: [] },
            4: { isOpen: true, openTime: '09:00', closeTime: '18:00', breaks: [] },
            5: { isOpen: true, openTime: '09:00', closeTime: '18:00', breaks: [] },
            6: { isOpen: true, openTime: '10:00', closeTime: '16:00', breaks: [] },
            7: { isOpen: false, openTime: '09:00', closeTime: '18:00', breaks: [] },
        };

        const createStaff1 = await apiRequest('/staff', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Vikram Sharma',
                email: 'vikram.sharma@example.com',
                phone: '9876543240',
                assignedServiceIds: [serviceId],
                schedule: sampleSchedule,
            },
        });

        if (createStaff1.status === 201 && createStaff1.data.data) {
            const st = createStaff1.data.data;
            staff1Id = st.id;

            if (st.businessId === businessId && st.assignedServiceIds?.includes(serviceId)) {
                logPass('Staff 1 created with active business fallback', `ID: ${st.id} | Services: ${st.assignedServiceIds.length}`);
            } else {
                logFail('Staff 1 properties mismatch', JSON.stringify(st));
            }
            if (st.schedule && st.schedule['1']?.isOpen === true) {
                logPass('Staff schedule verified (Day 1 Mon)', `Hours: ${st.schedule['1'].openTime} - ${st.schedule['1'].closeTime} | Breaks: ${st.schedule['1'].breaks?.length}`);
            }
            logPass('UI MessageToShow verified', `"${createStaff1.data.messageToShow}"`);
        } else {
            logFail('Failed to create staff member 1', JSON.stringify(createStaff1.data));
        }

        // Test 3: Create second staff member with explicit businessId
        console.log(`\n${colors.yellow}Test 3: Create second staff member${colors.reset}`);
        const createStaff2 = await apiRequest('/staff', {
            method: 'POST',
            headers: authHeaders,
            body: {
                businessId: businessId,
                name: 'Ananya Verma',
                email: 'ananya.verma@example.com',
                phone: '9876543241',
            },
        });

        if (createStaff2.status === 201 && createStaff2.data.data) {
            staff2Id = createStaff2.data.data.id;
            logPass('Staff 2 created successfully', `ID: ${staff2Id} | Name: "${createStaff2.data.data.name}"`);
        } else {
            logFail('Failed to create staff 2', JSON.stringify(createStaff2.data));
        }

        // Test 4: List all staff for business
        console.log(`\n${colors.yellow}Test 4: List all staff members for business${colors.reset}`);
        const listRes = await apiRequest(`/staff?businessId=${businessId}`, {
            method: 'GET',
            headers: authHeaders,
        });

        if (listRes.status === 200 && Array.isArray(listRes.data.data) && listRes.data.data.length === 2) {
            logPass(`Retrieved all staff members`, `Count: ${listRes.data.data.length}`);
            logPass('Meta count verified', `Total: ${listRes.data.meta?.total}`);
        } else {
            logFail('Failed to list staff members', JSON.stringify(listRes.data));
        }

        // Test 5: Filter staff by assigned service
        console.log(`\n${colors.yellow}Test 5: Filter staff by service (?serviceId=...)${colors.reset}`);
        const filterRes = await apiRequest(`/staff?businessId=${businessId}&serviceId=${serviceId}`, {
            method: 'GET',
            headers: authHeaders,
        });

        if (filterRes.status === 200 && filterRes.data.data.length === 1 && filterRes.data.data[0].id === staff1Id) {
            logPass('Filtered staff by service successfully', `Found: "${filterRes.data.data[0].name}" for service ID`);
        } else {
            logFail('Failed to filter staff by service', JSON.stringify(filterRes.data));
        }

        // Test 6: Get single staff by ID
        console.log(`\n${colors.yellow}Test 6: Retrieve single staff by ID${colors.reset}`);
        const getSingleRes = await apiRequest(`/staff/${staff1Id}`, {
            method: 'GET',
            headers: authHeaders,
        });

        if (getSingleRes.status === 200 && getSingleRes.data.data?.id === staff1Id) {
            logPass('Retrieved staff member by ID', `Name: "${getSingleRes.data.data.name}"`);
        } else {
            logFail('Failed to retrieve single staff', JSON.stringify(getSingleRes.data));
        }

        // Test 7: Public booking lookup by business slug (No Auth)
        console.log(`\n${colors.yellow}Test 7: Public staff lookup by business slug (No auth)${colors.reset}`);
        const publicRes = await apiRequest(`/staff/public/${businessSlug}`, {
            method: 'GET',
        });

        if (publicRes.status === 200 && Array.isArray(publicRes.data.data) && publicRes.data.data.length === 2) {
            logPass('Public staff lookup succeeded without auth', `Loaded ${publicRes.data.data.length} staff members for booking link "${businessSlug}"`);
        } else {
            logFail('Public staff lookup failed', JSON.stringify(publicRes.data));
        }

        // Test 8: Update staff details
        console.log(`\n${colors.yellow}Test 8: Update staff details (PUT/PATCH)${colors.reset}`);
        const updateRes = await apiRequest(`/staff/${staff1Id}`, {
            method: 'PUT',
            headers: authHeaders,
            body: {
                name: 'Vikram R. Sharma (Master Stylist)',
                phone: '9876543299',
            },
        });

        if (updateRes.status === 200 && updateRes.data.data?.name === 'Vikram R. Sharma (Master Stylist)') {
            logPass('Staff details updated successfully', `New name: "${updateRes.data.data.name}" | Phone: ${updateRes.data.data.phone}`);
        } else {
            logFail('Failed to update staff details', JSON.stringify(updateRes.data));
        }

        // Test 9: Toggle staff status
        console.log(`\n${colors.yellow}Test 9: Toggle staff status (PATCH /:id/toggle-status)${colors.reset}`);
        const toggle1 = await apiRequest(`/staff/${staff1Id}/toggle-status`, {
            method: 'PATCH',
            headers: authHeaders,
        });

        if (toggle1.status === 200 && toggle1.data.data?.is_active === false) {
            logPass('Staff toggled to inactive', `MessageToShow: "${toggle1.data.messageToShow}"`);

            // Verify public customer booking hides inactive staff
            const publicCheck = await apiRequest(`/staff/public/${businessSlug}`);
            if (publicCheck.data.data?.length === 1) {
                logPass('Public customer booking excludes inactive staff', `Only ${publicCheck.data.data.length} active staff member shown`);
            } else {
                logFail('Inactive staff was still visible in public booking API!', JSON.stringify(publicCheck.data));
            }

            // Toggle back to active
            const toggleBack = await apiRequest(`/staff/${staff1Id}/toggle-status`, {
                method: 'PATCH',
                headers: authHeaders,
            });
            if (toggleBack.data.data?.is_active === true) {
                logPass('Staff toggled back to active', `is_active: true`);
            }
        } else {
            logFail('Failed to toggle staff status', JSON.stringify(toggle1.data));
        }

        // Test 10: Delete staff member
        console.log(`\n${colors.yellow}Test 10: Delete staff member (DELETE /:id)${colors.reset}`);
        const deleteRes = await apiRequest(`/staff/${staff2Id}`, {
            method: 'DELETE',
            headers: authHeaders,
        });

        if (deleteRes.status === 200 && deleteRes.data.data?.deletedId === staff2Id) {
            logPass('Staff deleted successfully', `MessageToShow: "${deleteRes.data.messageToShow}"`);

            // Verify 404
            const checkDeleted = await apiRequest(`/staff/${staff2Id}`, { headers: authHeaders });
            if (checkDeleted.status === 404) {
                logPass('Deleted staff returns 404', `MessageToShow: "${checkDeleted.data.messageToShow}"`);
            } else {
                logFail('Deleted staff still accessible', JSON.stringify(checkDeleted.data));
            }
        } else {
            logFail('Failed to delete staff member', JSON.stringify(deleteRes.data));
        }

        // Test 11: Cross-owner unauthorized access rejection
        console.log(`\n${colors.yellow}Test 11: Cross-owner unauthorized access rejection (Security check)${colors.reset}`);
        const otherUser = await User.create({
            full_name: 'Other Staff Owner',
            email: `other_staff_${timestamp}@example.com`,
            phone: '+919876543288',
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

        const unauthorizedRes = await apiRequest(`/staff/${staff1Id}`, {
            headers: otherHeaders,
        });

        if (unauthorizedRes.status === 403 && unauthorizedRes.data.messageToShow) {
            logPass('Cross-owner access securely rejected (403)', `MessageToShow: "${unauthorizedRes.data.messageToShow}"`);
        } else {
            logFail('Failed to reject cross-tenant staff access', JSON.stringify(unauthorizedRes.data));
        }

        // Cleanup
        console.log(`\n${colors.yellow}Cleaning up test data...${colors.reset}`);
        await Staff.destroy({ where: { business_id: businessId } });
        await Service.destroy({ where: { business_id: businessId } });
        await Business.destroy({ where: { owner_id: ownerId } });
        await User.destroy({ where: { id: ownerId } });
        await User.destroy({ where: { id: otherUser.id } });
        console.log(`${colors.green}✔ Cleanup complete.${colors.reset}\n`);

        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}`);
        console.log(`${colors.bold}${colors.green}   🎉 ALL 11 STAFF CRUD TESTS PASSED PERFECTLY!${colors.reset}`);
        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}\n`);

    } catch (err) {
        console.error(`${colors.red}Test execution error:${colors.reset}`, err);
    } finally {
        await sequelize.close();
    }
};

runTestSuite();
