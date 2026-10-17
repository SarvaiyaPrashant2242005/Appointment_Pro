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
      return 'http://192.168.1.5:5000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://192.168.1.5:5000/api/v1';
    }
    return 'http://192.168.1.5:5000/api/v1';
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

  // Businesses endpoints
  static const String businesses = '/businesses';
  static String businessById(String id) => '/businesses/$id';
  static String businessActivate(String id) => '/businesses/$id/activate';
  static String businessPublic(String slug) => '/businesses/public/$slug';

  // Services endpoints
  static const String services = '/services';

  // Staff endpoints
  static const String staff = '/staff';

  // Availability endpoints
  static const String availability = '/availability';

  // Bookings endpoints
  static const String bookings = '/bookings';

  // Customers endpoints
  static const String customers = '/customers';

  // Payments endpoints
  static const String payments = '/payments';

  // Notifications & FCM endpoints
  static const String notifications = '/notifications';
  static const String fcmToken = '/notifications/fcm-token';
  static const String sendTestNotification = '/notifications/send-test';
}
