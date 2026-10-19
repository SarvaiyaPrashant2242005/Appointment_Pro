const path = require('path');
const fs = require('fs');
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

let isFirebaseInitialized = false;
let firebaseApp = null;

/**
 * Initializes Firebase Admin SDK using serviceAccountKey.json.
 * Handles both:
 * 1. Standard Firebase Service Account Key JSON (contains private_key, client_email)
 * 2. Client google-services.json (contains project_info.project_id)
 */
function initFirebase() {
    if (getApps().length > 0) {
        isFirebaseInitialized = true;
        firebaseApp = getApps()[0];
        return firebaseApp;
    }

    const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');

    if (!fs.existsSync(serviceAccountPath)) {
        console.warn('⚠️ Firebase: serviceAccountKey.json not found in Server directory. Push notifications will be skipped.');
        return null;
    }

    try {
        const rawContent = fs.readFileSync(serviceAccountPath, 'utf8');
        const config = JSON.parse(rawContent);

        // Case 1: Standard Firebase Admin Service Account Key (has private_key)
        if (config.private_key && config.client_email) {
            firebaseApp = initializeApp({
                credential: cert(config),
                projectId: config.project_id,
            });
            isFirebaseInitialized = true;
            console.log(`🔥 Firebase Admin SDK initialized successfully for project: "${config.project_id}"`);
        }
        // Case 2: Client configuration file (google-services.json format)
        else if (config.project_info && config.project_info.project_id) {
            const projectId = config.project_info.project_id;
            firebaseApp = initializeApp({
                projectId: projectId,
            });
            isFirebaseInitialized = true;
            console.log(`🔥 Firebase Admin SDK initialized with projectId: "${projectId}"`);
            console.warn('ℹ️ Note: serviceAccountKey.json currently contains client config (google-services.json).');
            console.warn('   To send push notifications from the server, please download the Service Account Private Key JSON:');
            console.warn('   Firebase Console -> Project Settings -> Service Accounts -> Generate new private key.');
        } else {
            console.warn('⚠️ Firebase: serviceAccountKey.json has an unrecognized structure.');
            return null;
        }

        return firebaseApp;
    } catch (err) {
        console.error('❌ Failed to initialize Firebase Admin SDK:', err.message);
        return null;
    }
}

// Initialize on module load
initFirebase();

/**
 * Sends a push notification to a single FCM device token
 */
async function sendPushNotification({ token, title, body, data = {} }) {
    if (!token || !isFirebaseInitialized) return null;

    const stringData = {};
    for (const [key, value] of Object.entries(data)) {
        stringData[key] = value !== null && value !== undefined ? String(value) : '';
    }

    const message = {
        token: token.trim(),
        notification: {
            title: title || 'AppointmentPro',
            body: body || '',
        },
        data: stringData,
        android: {
            priority: 'high',
            notification: {
                sound: 'default',
                channelId: 'appointment_pro_high_importance',
            },
        },
    };

    try {
        const messaging = getMessaging();
        const response = await messaging.send(message);
        console.log(`✅ FCM push sent to device: ${response}`);
        return { success: true, messageId: response };
    } catch (err) {
        console.error('❌ FCM push notification error:', err.message);
        return { success: false, error: err.message };
    }
}

/**
 * Sends a push notification to multiple FCM device tokens
 */
async function sendMulticastNotification({ tokens, title, body, data = {} }) {
    if (!tokens || !tokens.length || !isFirebaseInitialized) return null;

    const stringData = {};
    for (const [key, value] of Object.entries(data)) {
        stringData[key] = value !== null && value !== undefined ? String(value) : '';
    }

    const message = {
        tokens: tokens.map((t) => t.trim()),
        notification: {
            title: title || 'AppointmentPro',
            body: body || '',
        },
        data: stringData,
    };

    try {
        const messaging = getMessaging();
        const response = await messaging.sendEachForMulticast(message);
        console.log(`✅ FCM multicast sent: ${response.successCount} succeeded, ${response.failureCount} failed.`);
        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
        };
    } catch (err) {
        console.error('❌ FCM multicast notification error:', err.message);
        return { success: false, error: err.message };
    }
}


/**
 * Sends a push notification to an FCM topic (e.g. business_{businessId})
 */
async function sendTopicNotification({ topic, title, body, data = {} }) {
    if (!topic || !isFirebaseInitialized) return null;

    const stringData = {};
    for (const [key, value] of Object.entries(data)) {
        stringData[key] = value !== null && value !== undefined ? String(value) : '';
    }

    const cleanTopic = topic.trim().replace(/[^a-zA-Z0-9-_.~%]/g, '_');
    const message = {
        topic: cleanTopic,
        notification: {
            title: title || 'AppointmentPro',
            body: body || '',
        },
        data: stringData,
        android: {
            priority: 'high',
            notification: {
                sound: 'default',
                channelId: 'booking_alerts',
            },
        },
    };

    try {
        const messaging = getMessaging();
        const response = await messaging.send(message);
        console.log(`✅ FCM topic push sent to "${cleanTopic}": ${response}`);
        return { success: true, messageId: response };
    } catch (err) {
        console.warn(`⚠️ FCM topic notification notice for "${cleanTopic}": ${err.message}`);
        return { success: false, error: err.message };
    }
}

module.exports = {
    sendTopicNotification,
    getFirebaseApp: () => firebaseApp,
    isFirebaseInitialized: () => isFirebaseInitialized,
    sendPushNotification,
    sendMulticastNotification,
};
