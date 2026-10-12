class RegisterModel {
  final String fullName;
  final String email;
  final String phone;
  final String? password;

  const RegisterModel({
    required this.fullName,
    required this.email,
    required this.phone,
    this.password,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    if (password != null) 'password': password,
  };

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      password: json['password'] as String?,
    );
  }
}
