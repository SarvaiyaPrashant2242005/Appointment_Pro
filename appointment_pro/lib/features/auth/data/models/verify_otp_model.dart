class VerifyOtpModel {
  final String email;
  final String otp;

  const VerifyOtpModel({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'otp': otp.trim(),
  };

  factory VerifyOtpModel.fromJson(Map<String, dynamic> json) {
    return VerifyOtpModel(
      email: json['email'] as String? ?? '',
      otp: json['otp'] as String? ?? '',
    );
  }
}
