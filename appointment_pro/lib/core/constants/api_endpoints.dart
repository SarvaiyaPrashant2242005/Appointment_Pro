import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String? _customBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'https://appointment-pro.rishvi.app/api/v1';
    }
    if (Platform.isAndroid) {
      return 'https://appointment-pro.rishvi.app/api/v1';
    }
    return 'https://appointment-pro.rishvi.app/api/v1';
  }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String profile = '/auth/profile';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';

  static String get baseOrigin {
    try {
      final uri = Uri.parse(baseUrl);
      return uri.origin;
    } catch (_) {
      return baseUrl.replaceAll('/api/v1', '');
    }
  }

  static String get wsUrl {
    final origin = baseOrigin;
    if (origin.startsWith('https://')) {
      return '${origin.replaceFirst('https://', 'wss://')}/ws';
    } else if (origin.startsWith('http://')) {
      return '${origin.replaceFirst('http://', 'ws://')}/ws';
    }
    return 'ws://192.168.1.5:5000/ws';
  }

  // Businesses endpoints
  static const String businesses = '/businesses';
  static String businessById(String id) => '/businesses/$id';
  static String businessActivate(String id) => '/businesses/$id/activate';
  static String businessPublic(String slug) => '/businesses/public/$slug';

  // Services endpoints
  static const String services = '/services';
  static String serviceById(String id) => '/services/$id';
  static String serviceToggle(String id) => '/services/$id/toggle-status';
  static String servicesPublic(String slug) => '/services/public/$slug';

  // Staff endpoints
  static const String staff = '/staff';
  static String staffById(String id) => '/staff/$id';
  static String staffToggle(String id) => '/staff/$id/toggle-status';
  static String staffPublic(String slug) => '/staff/public/$slug';

  // Availability endpoints
  static const String availability = '/availability';
  static const String operatingHours = '/availability/operating-hours';
  static String availabilityToggle(int dayOfWeek) =>
      '/availability/operating-hours/$dayOfWeek/toggle';
  static String availabilityPublic(String slug) => '/availability/public/$slug';

  // Bookings endpoints
  static const String bookings = '/bookings';
  static String bookingById(String id) => '/bookings/$id';
  static String bookingStatus(String id) => '/bookings/$id/status';
  static String bookingReschedule(String id) => '/bookings/$id/reschedule';
  static String bookingByRef(String ref) => '/bookings/ref/$ref';
  static String bookingPublic(String slug) => '/bookings/public/$slug';
  static String bookingPublicReschedule(String id) =>
      '/bookings/public-reschedule/$id';
  static String bookingPublicCancel(String id) => '/bookings/public-cancel/$id';

  // Customers endpoints
  static const String customers = '/customers';
  static String customerById(String id) => '/customers/$id';

  // Payments endpoints
  static const String payments = '/payments';

  // Notifications & FCM endpoints
  static const String notifications = '/notifications';
  static const String fcmToken = '/notifications/fcm-token';
  static const String sendTestNotification = '/notifications/send-test';
}
