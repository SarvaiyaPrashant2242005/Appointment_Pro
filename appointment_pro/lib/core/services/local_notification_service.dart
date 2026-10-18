import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service responsible for displaying real device OS system tray notifications,
/// heads-up banners with sound, vibration, and handling tap actions.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void Function(String? payload)? _onTapCallback;

  static const String bookingChannelId = 'booking_alerts';
  static const String bookingChannelName = 'Booking Alerts';
  static const String bookingChannelDesc =
      'High-priority notifications for appointments, bookings, reschedules, and cancellations';

  static const String generalChannelId = 'general_alerts';
  static const String generalChannelName = 'General Alerts';
  static const String generalChannelDesc = 'General updates and reminders';

  /// Initializes local notifications with platform-specific channel setup
  Future<void> initialize({void Function(String? payload)? onNotificationTap}) async {
    if (_isInitialized) return;
    _onTapCallback = onNotificationTap;

    try {
      // 1. Android initialization
      // Uses the app launcher icon as the small notification icon
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

      // 2. iOS / macOS initialization
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // 3. Linux initialization
      final linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          debugPrint('[LocalNotificationService] Notification tapped: payload=$payload');
          _onTapCallback?.call(payload);
        },
      );

      // 4. Create Android notification channels
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        const bookingChannel = AndroidNotificationChannel(
          bookingChannelId,
          bookingChannelName,
          description: bookingChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        const generalChannel = AndroidNotificationChannel(
          generalChannelId,
          generalChannelName,
          description: generalChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await androidPlugin.createNotificationChannel(bookingChannel);
        await androidPlugin.createNotificationChannel(generalChannel);

        // Request notification permission for Android 13+
        await androidPlugin.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('[LocalNotificationService] Initialized successfully.');
    } catch (e) {
      debugPrint('[LocalNotificationService] Note: Notification init warning: $e');
    }
  }

  /// Sets or updates the tap callback
  void setOnTapCallback(void Function(String? payload) callback) {
    _onTapCallback = callback;
  }

  /// Explicitly requests notification permissions from the OS
  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] Request permission note: $e');
    }
    return false;
  }

  /// Displays a real OS system tray notification for a booking event
  Future<void> showBookingNotification({
    required String bookingId,
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    if (!_isInitialized) {
      debugPrint('[LocalNotificationService] Plugin not initialized, skipping showBookingNotification.');
      return;
    }

    final id = notificationId ??
        (bookingId.hashCode.abs() % 100000) + (DateTime.now().millisecond);

    final resolvedPayload = payload ?? bookingId;

    const androidDetails = AndroidNotificationDetails(
      bookingChannelId,
      bookingChannelName,
      channelDescription: bookingChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Appointment Alert',
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(''),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: resolvedPayload,
      );
      debugPrint('[LocalNotificationService] Real system notification posted: id=$id title="$title"');
    } catch (e) {
      debugPrint('[LocalNotificationService] Show notification error: $e');
    }
  }

  /// Shows a general alert notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      generalChannelId,
      generalChannelName,
      channelDescription: generalChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(''),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[LocalNotificationService] Show notification error: $e');
    }
  }

  /// Cancels a specific notification by ID
  Future<void> cancel(int id) async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  /// Cancels all active notifications
  Future<void> cancelAll() async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }
}
