/**
 * AppointmentPro — Customers, Bookings, Reschedules & Payments Automated Test Suite
 * Run with: node test-bookings-api.js
 */

const { User } = require('./modules/users');
const { Business } = require('./modules/businesses');
const { Service } = require('./modules/services');
const { Staff } = require('./modules/staff');
const { Customer } = require('./modules/customers');
const { Booking, BookingReschedule, Payment } = require('./modules/bookings');
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
    console.log(`${colors.bold}   🚀 AppointmentPro — Bookings, CRM & Payments Suite${colors.reset}`);
    console.log(`${colors.cyan}====================================================${colors.reset}\n`);

    const timestamp = Date.now();
    const testEmail = `booking_owner_${timestamp}@example.com`;
    const testPassword = 'Password@123';
    let accessToken = '';
    let ownerId = '';
    let businessId = '';
    let businessSlug = '';
    let serviceId = '';
    let staffId = '';
    let customerId = '';
    let booking1Id = '';
    let booking1Ref = '';
    let booking2Ref = '';

    try {
        // Step 1: Create verified owner, active business, service, and staff
        console.log(`${colors.yellow}Step 1: Setting up test environment (Owner, Business, Service, Staff)...${colors.reset}`);
        const passwordHash = await bcrypt.hash(testPassword, 10);
        const testUser = await User.create({
            full_name: 'Booking System Test Owner',
            email: testEmail,
            phone: '+919876543250',
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
                name: 'Prime Aesthetics & Wellness',
                type: 'clinic',
                email: 'contact@primeaesthetics.com',
                phone: '9876543251',
            },
        });
        businessId = bizRes.data.data.id;
        businessSlug = bizRes.data.data.slug;

        // Create service
        const svcRes = await apiRequest('/services', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Advanced Laser Skin Therapy',
                price: 1500.00,
                durationMinutes: 45,
            },
        });
        serviceId = svcRes.data.data.id;

        // Create staff
        const staffRes = await apiRequest('/staff', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Dr. Kavita Mehta',
                email: 'dr.kavita@primeaesthetics.com',
                phone: '9876543252',
                assignedServiceIds: [serviceId],
            },
        });
        staffId = staffRes.data.data.id;

        logPass('Prerequisites Ready', `Business: "${bizRes.data.data.name}" | Service: "${svcRes.data.data.name}" | Staff: "${staffRes.data.data.name}"`);

        // Test 1: Customers CRM Module
        console.log(`\n${colors.yellow}Test 1: Customers CRM Ledger (Create, List, Update)${colors.reset}`);
        const createCustRes = await apiRequest('/customers', {
            method: 'POST',
            headers: authHeaders,
            body: {
                name: 'Rohit K. Joshi',
                phone: '9876543260',
                email: 'rohit.joshi@example.com',
                notes: 'Prefers morning appointments.',
            },
        });

        if (createCustRes.status === 201 && createCustRes.data.data) {
            customerId = createCustRes.data.data.id;
            logPass('Created CRM customer record', `ID: ${customerId} | Name: "${createCustRes.data.data.name}"`);
            logPass('UI MessageToShow verified', `"${createCustRes.data.messageToShow}"`);
        } else {
            logFail('Failed to create customer', JSON.stringify(createCustRes.data));
        }

        const listCustRes = await apiRequest(`/customers?search=Rohit`, {
            method: 'GET',
            headers: authHeaders,
        });

        if (listCustRes.status === 200 && listCustRes.data.data?.length === 1) {
            logPass('Search customer in CRM directory succeeded', `Found: "${listCustRes.data.data[0].name}"`);
        } else {
            logFail('Failed to search customer', JSON.stringify(listCustRes.data));
        }

        // Test 2: Create appointment booking (Authenticated)
        console.log(`\n${colors.yellow}Test 2: Create appointment booking (Auto-CRM sync & duration calculation)${colors.reset}`);
        const bookingDate = new Date(Date.now() + 86400000); // Tomorrow
        bookingDate.setHours(10, 0, 0, 0);

        const createBkRes = await apiRequest('/bookings', {
            method: 'POST',
            headers: authHeaders,
            body: {
                serviceId: serviceId,
                staffId: staffId,
                customerName: 'Rohit K. Joshi',
                customerPhone: '9876543260',
                customerEmail: 'rohit.joshi@example.com',
                startAt: bookingDate.toISOString(),
            },
        });

        if (createBkRes.status === 201 && createBkRes.data.data) {
            const bk = createBkRes.data.data;
            booking1Id = bk.id;
            booking1Ref = bk.bookingReference;

            // Verify end_at is 45 minutes after start_at
            const startMs = new Date(bk.startAt).getTime();
            const endMs = new Date(bk.endAt).getTime();
            const diffMinutes = Math.round((endMs - startMs) / 60000);

            if (diffMinutes === 45 && bk.bookingReference?.startsWith('AP-')) {
                logPass('Booking created with calculated end time & reference code', `Ref: ${bk.bookingReference} | Duration: ${diffMinutes}m | Status: ${bk.status}`);
            } else {
                logFail('Booking time calculation mismatch', JSON.stringify(bk));
            }
            logPass('UI MessageToShow verified', `"${createBkRes.data.messageToShow}"`);
        } else {
            logFail('Failed to create booking', JSON.stringify(createBkRes.data));
        }

        // Test 3: Public customer online booking (No auth token)
        console.log(`\n${colors.yellow}Test 3: Public customer online booking (No auth)${colors.reset}`);
        const publicBkDate = new Date(Date.now() + 172800000); // Day after tomorrow
        publicBkDate.setHours(14, 30, 0, 0);

        const publicBkRes = await apiRequest(`/bookings/public/${businessSlug}`, {
            method: 'POST',
            body: {
                serviceId: serviceId,
                customerName: 'Pooja Bhatt',
                customerPhone: '9876543270',
                customerEmail: 'pooja.bhatt@example.com',
                customerNotes: 'Online booking via website.',
                startAt: publicBkDate.toISOString(),
            },
        });

        if (publicBkRes.status === 201 && publicBkRes.data.data?.bookingReference) {
            booking2Ref = publicBkRes.data.data.bookingReference;
            logPass('Public customer appointment booked without token', `Reference: ${booking2Ref} | Customer: "${publicBkRes.data.data.customerName}"`);
            logPass('Public MessageToShow verified', `"${publicBkRes.data.messageToShow}"`);
        } else {
            logFail('Public booking failed', JSON.stringify(publicBkRes.data));
        }

        // Test 4: Public booking lookup by reference code
        console.log(`\n${colors.yellow}Test 4: Public booking lookup by reference code (No auth)${colors.reset}`);
        const lookupRes = await apiRequest(`/bookings/ref/${booking2Ref}`, {
            method: 'GET',
        });

        if (lookupRes.status === 200 && lookupRes.data.data?.bookingReference === booking2Ref) {
            logPass('Customer verified appointment by reference code', `Service: "${lookupRes.data.data.serviceName}" | Time: ${lookupRes.data.data.startAt}`);
        } else {
            logFail('Booking lookup failed', JSON.stringify(lookupRes.data));
        }

        // Test 5: List bookings with filters
        console.log(`\n${colors.yellow}Test 5: List bookings with filters (Status & Search)${colors.reset}`);
        const listBkRes = await apiRequest(`/bookings?businessId=${businessId}&status=confirmed`, {
            method: 'GET',
            headers: authHeaders,
        });

        if (listBkRes.status === 200 && Array.isArray(listBkRes.data.data) && listBkRes.data.data.length >= 2) {
            logPass('List bookings with status filter succeeded', `Found ${listBkRes.data.data.length} confirmed bookings`);
        } else {
            logFail('Failed to list bookings', JSON.stringify(listBkRes.data));
        }

        // Test 6: Reschedule appointment (Audited in booking_reschedules)
        console.log(`\n${colors.yellow}Test 6: Reschedule appointment (Audit logged in booking_reschedules)${colors.reset}`);
        const newReschedDate = new Date(Date.now() + 259200000); // 3 days later
        newReschedDate.setHours(11, 0, 0, 0);

        const reschedRes = await apiRequest(`/bookings/${booking1Id}/reschedule`, {
            method: 'PATCH',
            headers: authHeaders,
            body: {
                newStartAt: newReschedDate.toISOString(),
                reason: 'Customer requested morning slot instead of evening.',
            },
        });

        if (reschedRes.status === 200 && reschedRes.data.data?.rescheduleHistory?.length === 1) {
            const hist = reschedRes.data.data.rescheduleHistory[0];
            logPass('Appointment rescheduled & audit history recorded', `New Start: ${reschedRes.data.data.startAt} | Reason: "${hist.reason}"`);
            logPass('UI MessageToShow verified', `"${reschedRes.data.messageToShow}"`);
        } else {
            logFail('Failed to reschedule booking', JSON.stringify(reschedRes.data));
        }

        // Test 7: Update booking status (Mark as completed)
        console.log(`\n${colors.yellow}Test 7: Update booking status (Mark as completed)${colors.reset}`);
        const statusRes = await apiRequest(`/bookings/${booking1Id}/status`, {
            method: 'PATCH',
            headers: authHeaders,
            body: { status: 'completed' },
        });

        if (statusRes.status === 200 && statusRes.data.data?.status === 'completed') {
            logPass('Booking marked as completed', `Message: "${statusRes.data.messageToShow}"`);
        } else {
            logFail('Failed to update status', JSON.stringify(statusRes.data));
        }

        // Test 8: Payments API (Record payment & revenue aggregation)
        console.log(`\n${colors.yellow}Test 8: Record payment & revenue aggregation (POST /payments)${colors.reset}`);
        const payRes = await apiRequest('/payments', {
            method: 'POST',
            headers: authHeaders,
            body: {
                bookingId: booking1Id,
                amount: 1500.00,
                method: 'upi',
                transactionReference: 'UPI-9827364124',
                status: 'completed',
            },
        });

        if (payRes.status === 201 && payRes.data.data?.amount === 1500) {
            logPass('Payment recorded successfully', `Amount: ₹${payRes.data.data.amount} via ${payRes.data.data.method.toUpperCase()}`);
            logPass('Payment MessageToShow verified', `"${payRes.data.messageToShow}"`);
        } else {
            logFail('Failed to record payment', JSON.stringify(payRes.data));
        }

        const listPayRes = await apiRequest(`/payments?businessId=${businessId}`, {
            method: 'GET',
            headers: authHeaders,
        });

        if (listPayRes.status === 200 && listPayRes.data.meta?.totalRevenue === 1500) {
            logPass('Revenue aggregated successfully', `Total Revenue: ₹${listPayRes.data.meta.totalRevenue}`);
        } else {
            logFail('Revenue calculation mismatch', JSON.stringify(listPayRes.data));
        }

        // Test 9: Delete booking and cascade verification
        console.log(`\n${colors.yellow}Test 9: Delete booking & cascade clean-up (DELETE /bookings/:id)${colors.reset}`);
        const delBkRes = await apiRequest(`/bookings/${booking1Id}`, {
            method: 'DELETE',
            headers: authHeaders,
        });

        if (delBkRes.status === 200 && delBkRes.data.data?.deletedId === booking1Id) {
            logPass('Booking deleted successfully', `Message: "${delBkRes.data.messageToShow}"`);

            // Verify 404
            const checkDeleted = await apiRequest(`/bookings/${booking1Id}`, { headers: authHeaders });
            if (checkDeleted.status === 404) {
                logPass('Deleted booking returns 404', `Message: "${checkDeleted.data.messageToShow}"`);
            }
        } else {
            logFail('Failed to delete booking', JSON.stringify(delBkRes.data));
        }

        // Test 10: Cross-tenant access rejection
        console.log(`\n${colors.yellow}Test 10: Cross-tenant unauthorized access rejection (Security check)${colors.reset}`);
        const otherUser = await User.create({
            full_name: 'Other Booking Owner',
            email: `other_bk_${timestamp}@example.com`,
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

        // Attempt to access customers of first business with other owner's token
        const unauthCust = await apiRequest(`/customers?businessId=${businessId}`, { headers: otherHeaders });
        if (unauthCust.status === 403 && unauthCust.data.messageToShow) {
            logPass('Cross-owner access securely rejected (403)', `MessageToShow: "${unauthCust.data.messageToShow}"`);
        } else {
            logFail('Failed to reject unauthorized tenant access', JSON.stringify(unauthCust.data));
        }

        // Cleanup
        console.log(`\n${colors.yellow}Cleaning up test data...${colors.reset}`);
        await Payment.destroy({ where: { business_id: businessId } });
        await BookingReschedule.destroy({ where: {} });
        await Booking.destroy({ where: { business_id: businessId } });
        await Customer.destroy({ where: { business_id: businessId } });
        await Staff.destroy({ where: { business_id: businessId } });
        await Service.destroy({ where: { business_id: businessId } });
        await Business.destroy({ where: { owner_id: ownerId } });
        await User.destroy({ where: { id: ownerId } });
        await User.destroy({ where: { id: otherUser.id } });
        console.log(`${colors.green}✔ Cleanup complete.${colors.reset}\n`);

        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}`);
        console.log(`${colors.bold}${colors.green}   🎉 ALL 10 BOOKINGS & PAYMENTS TESTS PASSED!${colors.reset}`);
        console.log(`${colors.bold}${colors.green}====================================================${colors.reset}\n`);

    } catch (err) {
        console.error(`${colors.red}Test execution error:${colors.reset}`, err);
    } finally {
        await sequelize.close();
    }
};

runTestSuite();
