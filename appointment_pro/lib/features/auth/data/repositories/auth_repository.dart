import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../datasource/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/register_model.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final storage = ref.watch(localStorageServiceProvider);
  return AuthRepository(remote, storage);
});

class AuthRepository {
  final AuthRemoteDataSource _remote;
  final LocalStorageService _storage;

  AuthRepository(this._remote, this._storage);

  Future<AuthResponseModel> register(RegisterModel model) async {
    final response = await _remote.register(model);

    // Save initial registration details locally for offline fallback
    if (response.user != null) {
      await _storage.saveUserProfile(jsonEncode(response.user!.toJson()));
    } else {
      await _storage.saveUserProfile(jsonEncode(model.toJson()));
    }

    return response;
  }

  Future<AuthResponseModel> verifyEmail({
    required String email,
    required String otp,
    String? fcmToken,
  }) async {
    final response = await _remote.verifyEmail(
      email: email,
      otp: otp,
      fcmToken: fcmToken,
    );

    if (response.accessToken != null &&
        response.refreshToken != null &&
        response.user != null) {
      await _storage.saveAuthSession(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken!,
        user: response.user!.toJson(),
      );
    }

    return response;
  }

  Future<String> resendVerification({required String email}) async {
    return await _remote.resendVerification(email: email);
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final response = await _remote.login(
      email: email,
      password: password,
      fcmToken: fcmToken,
    );

    if (response.accessToken != null &&
        response.refreshToken != null &&
        response.user != null) {
      await _storage.saveAuthSession(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken!,
        user: response.user!.toJson(),
      );
    }

    return response;
  }

  Future<void> saveFcmToken(String fcmToken) async {
    await _remote.saveFcmToken(fcmToken);
  }

  Future<void> removeFcmToken(String fcmToken) async {
    await _remote.removeFcmToken(fcmToken);
  }

  Future<UserModel?> getCurrentUser() async {
    final profileJson = await _storage.getUserProfile();
    if (profileJson == null || profileJson.isEmpty) return null;
    try {
      final map = jsonDecode(profileJson) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout([String? fcmToken]) async {
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await _remote.removeFcmToken(fcmToken);
    }
    await _remote.logout();
    await _storage.clearAuth();
  }
}
