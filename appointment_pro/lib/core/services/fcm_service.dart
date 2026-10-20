import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notification_service.dart';

/// Top-level background message handler required by Firebase Messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Background Firebase init: $e');
  }
  debugPrint('FCM Background message received: ${message.messageId}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  String? _subscribedBusinessTopic;
  bool _initialized = false;

  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageController.stream;

  final _bookingTapController = StreamController<String>.broadcast();
  Stream<String> get onBookingTap => _bookingTapController.stream;

  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get onTokenRefresh => _tokenController.stream;
  void Function(String token)? onTokenRefreshCallback;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    if (Firebase.apps.isEmpty) {
      debugPrint('Firebase is not initialized. FCM will run in offline/fallback mode.');
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;

      // 1. Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request permissions (crucial for iOS and Android 13+)
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('FCM Notification permission status: ${settings.authorizationStatus}');

      // 3. Set foreground presentation options (for iOS / macOS)
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Retrieve FCM token
      try {
        _fcmToken = await _messaging!.getToken();
        debugPrint('FCM Registration Token: $_fcmToken');
        if (_fcmToken != null) {
          try {
            onTokenRefreshCallback?.call(_fcmToken!);
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // 5. Listen for token refreshes
      _messaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        _tokenController.add(newToken);
        try {
          onTokenRefreshCallback?.call(newToken);
        } catch (e) {
          debugPrint('Error in onTokenRefreshCallback: $e');
        }
      });

      // 6. Listen for incoming foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title}');
        _messageController.add(message);

        final notification = message.notification;
        final title = notification?.title ?? message.data['title']?.toString();
        final body = notification?.body ?? message.data['body']?.toString();
        final bookingId = message.data['bookingId']?.toString();

        if (title != null && title.isNotEmpty) {
          LocalNotificationService.instance.showBookingNotification(
            bookingId: bookingId ?? 'fcm_booking',
            title: title,
            body: body ?? '',
            payload: bookingId,
          );
        }
      });

      // 7. Notification tapped when app in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final bookingId = message.data['bookingId']?.toString();
        if (bookingId != null && bookingId.isNotEmpty) {
          _bookingTapController.add(bookingId);
        }
      });

      // 8. Notification opened from terminated state
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        final bookingId = initialMessage.data['bookingId']?.toString();
        if (bookingId != null && bookingId.isNotEmpty) {
          _bookingTapController.add(bookingId);
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error during FCM initialization: $e');
    }
  }

  /// Subscribes to the specific business topic: `business_{businessId}`
  /// Ensures the owner device receives notifications for this business.
  Future<void> subscribeToBusiness(String businessId) async {
    if (_messaging == null || businessId.isEmpty) return;

    final sanitizedTopic = _sanitizeTopic('business_$businessId');

    // Unsubscribe from old topic if different
    if (_subscribedBusinessTopic != null &&
        _subscribedBusinessTopic != sanitizedTopic) {
      try {
        await _messaging!.unsubscribeFromTopic(_subscribedBusinessTopic!);
      } catch (e) {
        debugPrint('Failed to unsubscribe from topic $_subscribedBusinessTopic: $e');
      }
    }

    try {
      await _messaging!.subscribeToTopic(sanitizedTopic);
      _subscribedBusinessTopic = sanitizedTopic;
      debugPrint('Successfully subscribed to FCM topic: $sanitizedTopic');

      // Also register device token under business in Firestore if available
      if (_fcmToken != null && Firebase.apps.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('businesses')
              .doc(businessId)
              .collection('devices')
              .doc(_fcmToken!)
              .set({
            'token': _fcmToken,
            'updatedAt': FieldValue.serverTimestamp(),
            'platform': defaultTargetPlatform.name,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore device token update skipped: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to subscribe to FCM topic $sanitizedTopic: $e');
    }
  }

  /// Unsubscribes from business topic
  Future<void> unsubscribeFromBusiness(String businessId) async {
    if (_messaging == null || businessId.isEmpty) return;

    final sanitizedTopic = _sanitizeTopic('business_$businessId');
    try {
      await _messaging!.unsubscribeFromTopic(sanitizedTopic);
      if (_subscribedBusinessTopic == sanitizedTopic) {
        _subscribedBusinessTopic = null;
      }
      debugPrint('Unsubscribed from FCM topic: $sanitizedTopic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $sanitizedTopic: $e');
    }
  }

  /// Topic names must match [a-zA-Z0-9-_.~%]+
  String _sanitizeTopic(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
  }

  void dispose() {
    _messageController.close();
    _bookingTapController.close();
    _tokenController.close();
  }
}
