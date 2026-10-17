import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  /// Configurable base URL. Defaults dynamically based on platform:
  /// - Android Emulator: http://10.0.2.2:5000/api/v1
  /// - iOS Simulator / Desktop / Web: http://localhost:5000/api/v1
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

  // Businesses endpoints
  static const String businesses = '/businesses';

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
}
