class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String messageToShow;
  final bool requiresVerification;
  final String? email;
  final List<dynamic>? errors;

  ApiException({
    this.statusCode,
    required this.message,
    required this.messageToShow,
    this.requiresVerification = false,
    this.email,
    this.errors,
  });

  factory ApiException.fromResponse(Map<String, dynamic> data, {int? statusCode}) {
    final message = data['message'] as String? ?? 'An unexpected error occurred.';
    final messageToShow = data['messageToShow'] as String? ?? message;
    final rawRequiresVerification = data['requiresVerification'];
    final bool requiresVerification = rawRequiresVerification == true ||
        rawRequiresVerification == 'true' ||
        message.toLowerCase().contains('not verified') ||
        messageToShow.toLowerCase().contains('not verified');
    final email = data['email'] as String?;
    final errors = data['errors'] as List<dynamic>?;

    return ApiException(
      statusCode: statusCode,
      message: message,
      messageToShow: messageToShow,
      requiresVerification: requiresVerification,
      email: email,
      errors: errors,
    );
  }

  factory ApiException.networkError([String? details]) {
    return ApiException(
      statusCode: 0,
      message: 'Network connection failed: $details',
      messageToShow:
          'Unable to reach AppointmentPro server. Please check your internet connection or server status.',
    );
  }

  factory ApiException.timeout() {
    return ApiException(
      statusCode: 408,
      message: 'Connection timed out',
      messageToShow:
          'Server is taking too long to respond. Please try again.',
    );
  }

  @override
  String toString() => messageToShow;
}
