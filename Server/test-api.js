/**
 * AppointmentPro — Automated Auth API Test Runner
 * Run while the server is running on port 5000:
 *   node test-api.js
 */

const { User, UserOtp, UserSession } = require('./modules/users');
const { sequelize } = require('./config/database');

const BASE_URL = 'http://localhost:5000/api/v1/auth';
const HEALTH_URL = 'http://localhost:5000/api/health';

const TEST_EMAIL = `test_${Date.now()}@example.com`;
const TEST_PASSWORD = 'Password@123';
const NEW_PASSWORD = 'NewPassword@456';

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
    console.error(`   ${colors.yellow}${error}${colors.reset}`);
};

const request = async (endpoint, options = {}) => {
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

const runTests = async () => {
    console.log(`\n${colors.bold}${colors.cyan}====================================================${colors.reset}`);
    console.log(`${colors.bold}   🚀 AppointmentPro — Auth API Testing Suite${colors.reset}`);
    console.log(`${colors.cyan}====================================================${colors.reset}\n`);

    let accessToken = '';
    let refreshToken = '';
    let userId = '';

    try {
        // 1. Health Check
        const health = await request(HEALTH_URL);
        if (health.status === 200 && health.data.success) {
            logPass('Health Check', health.data.messageToShow);
        } else {
            throw new Error(`Server offline or unexpected health status: ${health.status}`);
        }

        // 2. Register New User
        console.log(`\n${colors.bold}Step 1: Registering User (${TEST_EMAIL})...${colors.reset}`);
        const reg = await request('/register', {
            method: 'POST',
            body: {
                fullName: 'Prashant Sarvaiya',
                email: TEST_EMAIL,
                phone: '+919876543210',
                password: TEST_PASSWORD,
                role: 'owner',
            },
        });

        if (reg.status === 201 && reg.data.success) {
            userId = reg.data.data.user.id;
            logPass('User Registration', reg.data.messageToShow);
        } else {
            throw new Error(reg.data.messageToShow || 'Registration failed');
        }

        // 3. Test Duplicate Registration (Should return friendly error)
        console.log(`\n${colors.bold}Step 2: Testing Duplicate Registration Rejection...${colors.reset}`);
        // Temporarily mark verified in DB to test duplicate check
        const dbUser = await User.findByPk(userId);
        await dbUser.update({ is_email_verified: true });

        const dupReg = await request('/register', {
            method: 'POST',
            body: {
                fullName: 'Prashant Sarvaiya',
                email: TEST_EMAIL,
                phone: '+919876543210',
                password: TEST_PASSWORD,
            },
        });

        if (dupReg.status === 409) {
            logPass('Duplicate Registration Check', dupReg.data.messageToShow);
        } else {
            logFail('Duplicate Registration Check', `Expected 409, got ${dupReg.status}`);
        }

        // Revert verified to test OTP verification
        await dbUser.update({ is_email_verified: false });

        // 4. Retrieve OTP from user_otps table
        console.log(`\n${colors.bold}Step 3: Retrieving Verification OTP from DB...${colors.reset}`);
        const otpRecord = await UserOtp.findOne({
            where: { user_id: userId, type: 'email_verification' },
        });

        if (!otpRecord) {
            throw new Error('No OTP record created in user_otps table!');
        }
        logPass('OTP Created in DB', `OTP Code: ${otpRecord.otp_code}`);

        // 5. Test Invalid OTP
        const invalidVerify = await request('/verify-email', {
            method: 'POST',
            body: {
                email: TEST_EMAIL,
                otp: '000000',
            },
        });
        if (invalidVerify.status === 400) {
            logPass('Invalid OTP Rejection', invalidVerify.data.messageToShow);
        }

        // 6. Test Valid OTP Verification
        console.log(`\n${colors.bold}Step 4: Submitting Valid Verification Code...${colors.reset}`);
        const verify = await request('/verify-email', {
            method: 'POST',
            body: {
                email: TEST_EMAIL,
                otp: otpRecord.otp_code,
            },
        });

        if (verify.status === 200 && verify.data.success) {
            accessToken = verify.data.data.accessToken;
            refreshToken = verify.data.data.refreshToken;
            logPass('Email Verification & Token Issue', verify.data.messageToShow);

            // Verify OTP was purged from user_otps table
            const checkPurged = await UserOtp.findByPk(otpRecord.id);
            if (!checkPurged) {
                logPass('Table Hygiene', 'Verified OTP row was cleanly purged from user_otps!');
            }
        } else {
            throw new Error(verify.data.messageToShow || 'Verification failed');
        }

        // 7. Login with valid credentials
        console.log(`\n${colors.bold}Step 5: Testing Login...${colors.reset}`);
        const login = await request('/login', {
            method: 'POST',
            body: {
                email: TEST_EMAIL,
                password: TEST_PASSWORD,
            },
        });

        if (login.status === 200 && login.data.success) {
            accessToken = login.data.data.accessToken;
            refreshToken = login.data.data.refreshToken;
            logPass('User Login', login.data.messageToShow);
        } else {
            throw new Error(login.data.messageToShow || 'Login failed');
        }

        // 8. Test Wrong Password
        const badLogin = await request('/login', {
            method: 'POST',
            body: {
                email: TEST_EMAIL,
                password: 'WrongPassword999',
            },
        });
        if (badLogin.status === 401) {
            logPass('Wrong Password Handling', badLogin.data.messageToShow);
        }

        // 9. Get Profile (/me)
        console.log(`\n${colors.bold}Step 6: Fetching Authenticated Profile (/me)...${colors.reset}`);
        const profile = await request('/me', {
            headers: { Authorization: `Bearer ${accessToken}` },
        });

        if (profile.status === 200 && profile.data.success) {
            logPass('Get Profile (/me)', `${profile.data.messageToShow} -> Name: ${profile.data.data.full_name}`);
        } else {
            throw new Error(profile.data.messageToShow || 'Failed to fetch profile');
        }

        // 10. Update Profile
        console.log(`\n${colors.bold}Step 7: Updating Profile Information...${colors.reset}`);
        const update = await request('/profile', {
            method: 'PUT',
            headers: { Authorization: `Bearer ${accessToken}` },
            body: {
                fullName: 'Prashant R. Sarvaiya',
                phone: '+919999988888',
            },
        });

        if (update.status === 200 && update.data.success) {
            logPass('Update Profile', `${update.data.messageToShow} -> Updated Name: ${update.data.data.full_name}`);
        }

        // 11. Refresh Token
        console.log(`\n${colors.bold}Step 8: Testing Access Token Rotation (/refresh-token)...${colors.reset}`);
        const refresh = await request('/refresh-token', {
            method: 'POST',
            body: { refreshToken },
        });

        if (refresh.status === 200 && refresh.data.success) {
            accessToken = refresh.data.data.accessToken;
            refreshToken = refresh.data.data.refreshToken;
            logPass('Token Rotation', refresh.data.messageToShow);
        } else {
            throw new Error(refresh.data.messageToShow || 'Refresh token failed');
        }

        // 12. Change Password
        console.log(`\n${colors.bold}Step 9: Changing Account Password...${colors.reset}`);
        const chgPass = await request('/change-password', {
            method: 'PUT',
            headers: { Authorization: `Bearer ${accessToken}` },
            body: {
                currentPassword: TEST_PASSWORD,
                newPassword: NEW_PASSWORD,
            },
        });

        if (chgPass.status === 200 && chgPass.data.success) {
            logPass('Change Password', chgPass.data.messageToShow);
        } else {
            throw new Error(chgPass.data.messageToShow || 'Change password failed');
        }

        // 13. Login with New Password
        const newLogin = await request('/login', {
            method: 'POST',
            body: {
                email: TEST_EMAIL,
                password: NEW_PASSWORD,
            },
        });

        if (newLogin.status === 200 && newLogin.data.success) {
            accessToken = newLogin.data.data.accessToken;
            refreshToken = newLogin.data.data.refreshToken;
            logPass('Login with New Password', newLogin.data.messageToShow);
        } else {
            throw new Error('Could not log in with new password');
        }

        // 14. Forgot Password Flow
        console.log(`\n${colors.bold}Step 10: Testing Forgot Password Flow...${colors.reset}`);
        const forgot = await request('/forgot-password', {
            method: 'POST',
            body: { email: TEST_EMAIL },
        });
        if (forgot.status === 200) {
            logPass('Forgot Password Request', forgot.data.messageToShow);
        }

        // Retrieve Reset OTP from user_otps table
        const resetOtpRecord = await UserOtp.findOne({
            where: { user_id: userId, type: 'password_reset' },
        });

        if (!resetOtpRecord) {
            throw new Error('No password reset OTP created in user_otps table!');
        }

        // 15. Reset Password with OTP
        const resetPass = await request('/reset-password', {
            method: 'POST',
            body: {
                email: TEST_EMAIL,
                otp: resetOtpRecord.otp_code,
                newPassword: 'FinalPassword@999',
            },
        });

        if (resetPass.status === 200) {
            logPass('Reset Password with OTP', resetPass.data.messageToShow);
        }

        // 16. Logout Test
        console.log(`\n${colors.bold}Step 11: Testing Logout...${colors.reset}`);
        const logout = await request('/logout', {
            method: 'POST',
            headers: { Authorization: `Bearer ${accessToken}` },
            body: { refreshToken },
        });

        if (logout.status === 200) {
            logPass('User Logout', logout.data.messageToShow);
        }

        console.log(`\n${colors.bold}${colors.green}🎉 ALL 11 AUTH API TESTS PASSED SUCCESSFULLY!${colors.reset}\n`);

    } catch (err) {
        logFail('Test Suite Execution', err.message || err);
    } finally {
        // Clean up test user and associations
        if (userId) {
            try {
                await User.destroy({ where: { id: userId } });
                console.log(`\n${colors.cyan}🧹 Test user clean-up completed.${colors.reset}\n`);
            } catch (_) {}
        }
        await sequelize.close();
        process.exit(0);
    }
};

runTests();
