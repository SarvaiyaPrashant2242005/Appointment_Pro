import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final String messageToShow;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final bool requiresVerification;

  const AuthResponseModel({
    required this.success,
    required this.message,
    required this.messageToShow,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.requiresVerification = false,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    UserModel? user;
    if (data['user'] != null && data['user'] is Map<String, dynamic>) {
      user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } else if (data['id'] != null) {
      // In some endpoints data itself is the user
      user = UserModel.fromJson(data);
    }

    return AuthResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'Success',
      messageToShow: json['messageToShow'] as String? ?? json['message'] as String? ?? 'Success',
      user: user,
      accessToken: data['accessToken'] as String?,
      refreshToken: data['refreshToken'] as String?,
      requiresVerification: data['requiresVerification'] as bool? ?? false,
    );
  }
}
