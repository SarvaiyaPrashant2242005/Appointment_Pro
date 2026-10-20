import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';

/// Provider for the singleton NetworkService
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

/// Service managing real-time internet connectivity checks
class NetworkService {
  /// Verifies whether the device currently has active internet connectivity.
  /// Performs DNS query with fallbacks to public DNS and backend host.
  Future<bool> hasInternetConnection({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (kIsWeb) {
      // In web browser environment, assume online if executing
      return true;
    }

    // 1. Primary check: DNS lookup to google.com
    try {
      final addresses = await InternetAddress.lookup('google.com')
          .timeout(timeout);
      if (addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    // 2. Secondary check: DNS lookup to hosted backend server domain
    try {
      final host = Uri.parse(ApiEndpoints.baseOrigin).host;
      if (host.isNotEmpty && host != 'google.com') {
        final addresses = await InternetAddress.lookup(host).timeout(timeout);
        if (addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty) {
          return true;
        }
      }
    } catch (_) {}

    // 3. Fallback check: Direct TCP socket connection to Google Public DNS (8.8.8.8:53)
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: timeout,
      );
      socket.destroy();
      return true;
    } catch (_) {}

    // 4. Fallback check: Direct TCP socket connection to Cloudflare DNS (1.1.1.1:53)
    try {
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: timeout,
      );
      socket.destroy();
      return true;
    } catch (_) {}

    return false;
  }
}
