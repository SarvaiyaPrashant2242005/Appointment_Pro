class BusinessModel {
  final String id;
  final String name;
  final String type;
  final String? otherType;
  final String? logoPath;
  final String? email;
  final String? countryCode;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;

  const BusinessModel({
    required this.id,
    required this.name,
    required this.type,
    this.otherType,
    this.logoPath,
    this.email,
    this.countryCode = '+91',
    this.phone,
    this.isActive = false,
    required this.createdAt,
  });

  BusinessModel copyWith({
    String? id,
    String? name,
    String? type,
    String? otherType,
    String? logoPath,
    String? email,
    String? countryCode,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      otherType: otherType ?? this.otherType,
      logoPath: logoPath ?? this.logoPath,
      email: email ?? this.email,
      countryCode: countryCode ?? this.countryCode,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'otherType': otherType,
    'logoPath': logoPath,
    'email': email,
    'countryCode': countryCode,
    'phone': phone,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      otherType: json['otherType'] as String?,
      logoPath: json['logoPath'] as String?,
      email: json['email'] as String?,
      countryCode: json['countryCode'] as String? ?? '+91',
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
