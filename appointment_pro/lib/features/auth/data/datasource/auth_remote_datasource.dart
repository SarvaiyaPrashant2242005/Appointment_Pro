import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/register_model.dart';
import '../models/user_model.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient);
});

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<AuthResponseModel> register(RegisterModel model) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: model.toJson(),
    );
    return AuthResponseModel.fromJson(response);
  }

  Future<AuthResponseModel> verifyEmail({
    required String email,
    required String otp,
    String? fcmToken,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyEmail,
      data: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      },
    );
    return AuthResponseModel.fromJson(response);
  }

  Future<String> resendVerification({required String email}) async {
    final response = await _apiClient.post(
      ApiEndpoints.resendVerification,
      data: {'email': email.trim().toLowerCase()},
    );
    return response['messageToShow'] as String? ??
        response['message'] as String? ??
        'Verification code resent successfully.';
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      },
    );
    return AuthResponseModel.fromJson(response);
  }

  Future<void> saveFcmToken(String fcmToken) async {
    try {
      await _apiClient.post(
        ApiEndpoints.fcmToken,
        data: {'fcmToken': fcmToken, 'deviceType': 'android'},
      );
    } catch (_) {}
  }

  Future<void> removeFcmToken(String fcmToken) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.fcmToken,
        data: {'fcmToken': fcmToken},
      );
    } catch (_) {}
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.me);
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    final userData = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;
    return UserModel.fromJson(userData);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Gracefully ignore network errors on logout
    }
  }
}
