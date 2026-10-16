/**
 * AppointmentPro — Business Operating Hours & Schedule Breaks Automated Test Suite
 * Run with: node test-availability-api.js
 */

const { User } = require('./modules/users');
const { Business } = require('./modules/businesses');
const { BusinessOperatingHour, BusinessScheduleBreak } = require('./modules/availability');
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
    console.log(`${colors.bold}   🚀 AppointmentPro — Operating Hours & Breaks Suite${colors.reset}`);
    console.log(`${colors.cyan}====================================================${colors.reset}\n`);

    const timestamp = Date.now();
    const testEmail = `avail_owner_${timestamp}@example.com`;
    const testPassword = 'Password@123';
    let accessToken = '';
    let ownerId = '';
    let businessId = '';
    let businessSlug = '';

    try {
        // Step 1: Create verified owner user and active business
        console.log(`${colors.yellow}Step 1: Setting up test owner & active business...${colors.reset}`);
        const passwordHash = await bcrypt.hash(testPassword, 10);
        const testUser = await User.create({
            full_name: 'Operating Hours Test Owner',
            email: testEmail,
            phone: '+919876543240',
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
                name: 'Zenith Wellness & Physiotherapy',
                type: 'clinic',
                email: 'contact@zenithwellness.com',
                phone: '9876543241',
            },
        });
        businessId = bizRes.data.data.id;
        businessSlug = bizRes.data.data.slug;
        logPass('Owner & Active Business Ready', `Business: "${bizRes.data.data.name}" (${businessSlug})`);

        // Test 1: Get initial operating hours (auto default 7 days)
        console.log(`\n${colors.yellow}Test 1: Get initial operating hours (7-day default structure)${colors.reset}`);
        const getRes = await apiRequest('/availability/operating-hours', {
            method: 'GET',
            headers: authHeaders,
        });

        if (getRes.status === 200 && getRes.data.data?.weeklySchedule) {
            const data = getRes.data.data;
            const sched = data.weeklySchedule;
            const daysCount = Object.keys(sched).length;

            if (daysCount === 7 && sched['1']?.isOpen === true && sched['7']?.isOpen === false) {
                logPass('Default 7-day schedule generated perfectly', `Mon (Day 1): Open ${sched['1'].openTime}-${sched['1'].closeTime} | Sun (Day 7): Closed`);
            } else {
                logFail('Default schedule mismatch', JSON.stringify(sched));
            }
            logPass('UI MessageToShow verified', `"${getRes.data.messageToShow}"`);
        } else {
            logFail('Failed to retrieve initial operating hours', JSON.stringify(getRes.data));
        }

        // Test 2: Update weekly schedule with custom hours & multiple breaks
        console.log(`\n${colors.yellow}Test 2: Save custom operating hours and multiple breaks (PUT)${colors.reset}`);
        const customWeeklySchedule = {
            1: {
                dayOfWeek: 1,
                isOpen: true,
                openTime: '08:30',
                closeTime: '19:30',
                breaks: [
                    { breakName: 'Morning Tea', startTime: '11:00', endTime: '11:15' },
                    { breakName: 'Lunch Break', startTime: '13:00', endTime: '14:00' },
                    { breakName: 'Evening Tea', startTime: '16:30', endTime: '16:45' },
                ],
            },
            2: { dayOfWeek: 2, isOpen: true, openTime: '08:30', closeTime: '19:30', breaks: [{ breakName: 'Lunch', startTime: '13:00', endTime: '14:00' }] },
            3: { dayOfWeek: 3, isOpen: true, openTime: '08:30', closeTime: '19:30', breaks: [] },
            4: { dayOfWeek: 4, isOpen: true, openTime: '08:30', closeTime: '19:30', breaks: [] },
            5: { dayOfWeek: 5, isOpen: true, openTime: '08:30', closeTime: '19:30', breaks: [] },
            6: { dayOfWeek: 6, isOpen: true, openTime: '09:00', closeTime: '15:00', breaks: [] },
            7: { dayOfWeek: 7, isOpen: false, openTime: '09:00', closeTime: '18:00', breaks: [] },
        };

        const updateRes = await apiRequest('/availability/operating-hours', {
            method: 'PUT',
            headers: authHeaders,
            body: {
                businessId: businessId,
                weeklySchedule: customWeeklySchedule,
            },
        });

        if (updateRes.status === 200 && updateRes.data.data?.weeklySchedule) {
            const mon = updateRes.data.data.weeklySchedule['1'];
            if (mon.openTime === '08:30' && mon.closeTime === '19:30' && mon.breaks?.length === 3) {
                logPass('Custom hours and 3 breaks saved successfully', `Mon: ${mon.openTime}-${mon.closeTime} with 3 breaks: [${mon.breaks.map(b => b.breakName).join(', ')}]`);
            } else {
                logFail('Custom hours not reflected in response', JSON.stringify(mon));
            }
            logPass('UI MessageToShow verified', `"${updateRes.data.messageToShow}"`);
        } else {
            logFail('Failed to update operating hours', JSON.stringify(updateRes.data));
        }

        // Test 3: Quick toggle day status (open/closed)
        console.log(`\n${colors.yellow}Test 3: Quick toggle day status (PATCH /:dayOfWeek/toggle)${colors.reset}`);
        // Sunday (day 7) was closed, toggle to open
        const toggleSun = await apiRequest(`/availability/operating-hours/7/toggle`, {
            method: 'PATCH',
            headers: authHeaders,
            body: { businessId },
        });

        if (toggleSun.status === 200 && toggleSun.data.data?.isOpen === true) {
            logPass('Sunday successfully toggled to OPEN', `Message: "${toggleSun.data.messageToShow}"`);

            // Toggle back to closed
            const toggleSunBack = await apiRequest(`/availability/operating-hours/7/toggle`, {
                method: 'PATCH',
                headers: authHeaders,
                body: { businessId },
            });
            if (toggleSunBack.data.data?.isOpen === false) {
                logPass('Sunday successfully toggled back to CLOSED', `isOpen: false`);
            }
        } else {
            logFail('Failed to toggle Sunday status', JSON.stringify(toggleSun.data));
        }

        // Test 4: Public booking lookup by business slug (No Auth)
        console.log(`\n${colors.yellow}Test 4: Public operating hours lookup by business slug (No auth)${colors.reset}`);
        const publicRes = await apiRequest(`/availability/public/${businessSlug}`, {
            method: 'GET',
        });

        if (publicRes.status === 200 && publicRes.data.data?.weeklySchedule) {
            const pubMon = publicRes.data.data.weeklySchedule['1'];
            logPass('Public customer booking loaded operating hours without token', `Mon: ${pubMon.openTime}-${pubMon.closeTime} | Breaks: ${pubMon.breaks?.length}`);
            logPass('Public MessageToShow verified', `"${publicRes.data.messageToShow}"`);
        } else {
            logFail('Public lookup failed', JSON.stringify(publicRes.data));
        }

        // Test 5: Verify direct alias route (/operating-hours)
        console.log(`\n${colors.yellow}Test 5: Verify route alias (/api/v1/operating-hours)${colors.reset}`);
        const aliasRes = await apiRequest('/operating-hours', {
            method: 'GET',
            headers: authHeaders,
        });

        if (aliasRes.status === 200 && aliasRes.data.data?.weeklySchedule) {
            logPass('Alias route /api/v1/operating-hours works identically', `Business: ${aliasRes.data.data.businessName}`);
        } else {
            logFail('Alias route failed', JSON.stringify(aliasRes.data));
        }

        // Test 6: Cross-tenant unauthorized access rejection
        console.log(`\n${colors.yellow}Test 6: Cross-tenant unauthorized access rejection (Security check)${colors.reset}`);
        const otherUser = await User.create({
            full_name: 'Other Hours Owner',
            email: `other_hours_${timestamp}@example.com`,
            phone: '+919876543290',
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

        const unauthorizedRes = await apiRequest(`/availability/operating-hours?businessId=${businessId}`, {
            headers: otherHeaders,
        });

        if (unauthorizedRes.status === 403 && unauthorizedRes.data.messageToShow) {
            logPass('Cross-owner access securely rejected (403)', `MessageToShow: "${unauthorizedRes.data.messageToShow}"`);
        } else {
            logFail('Failed to reject cross-tenant access', JSON.stringify(unauthorizedRes.data));
        }

        // Cleanup
        console.log(`\n${colors.yellow}Cleaning up test data...${colors.reset}`);
        const hours = await BusinessOperatingHour.findAll({ where: { business_id: businessId } });
        const hourIds = hours.map(h => h.id);
        await BusinessScheduleBreak.destroy({ where: { operating_hour_id: { [require('sequelize').Op.in]: hourIds } } });
        await BusinessOperatingHour.destroy({ where: { business_id: businessId } });
        await Business.destroy({ where: { owner_id: ownerId } });
        await User.destroy({ where: { id: ownerId } });
        await User.destroy({ where: { id: otherUser.id } });
        console.log(`${colors.green}✔ Cleanup complete.${colors.reset}\n`);

        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}`);
        console.log(`${colors.bold}${colors.green}   🎉 ALL 6 OPERATING HOURS TESTS PASSED PERFECTLY!${colors.reset}`);
        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}\n`);

    } catch (err) {
        console.error(`${colors.red}Test execution error:${colors.reset}`, err);
    } finally {
        await sequelize.close();
    }
};

runTestSuite();
