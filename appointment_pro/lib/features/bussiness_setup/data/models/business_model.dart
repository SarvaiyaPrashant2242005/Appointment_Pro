import '../../../../core/constants/api_endpoints.dart';

class BusinessModel {
  final String id;
  final String? ownerId;
  final String name;
  final String? slug;
  final String type;
  final String? otherType;
  final String? logoPath;
  final String? email;
  final String countryCode;
  final String? phone;
  final String currency;
  final String timezone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BusinessModel({
    required this.id,
    this.ownerId,
    required this.name,
    this.slug,
    required this.type,
    this.otherType,
    this.logoPath,
    this.email,
    this.countryCode = '+91',
    this.phone,
    this.currency = 'INR',
    this.timezone = 'Asia/Kolkata',
    this.isActive = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Resolves logo URL (prepending server origin if it's a relative uploads path)
  String? get fullLogoUrl {
    if (logoPath == null || logoPath!.trim().isEmpty) return null;
    final path = logoPath!.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '${ApiEndpoints.baseOrigin}$path';
    }
    return path;
  }

  BusinessModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? slug,
    String? type,
    String? otherType,
    String? logoPath,
    String? email,
    String? countryCode,
    String? phone,
    String? currency,
    String? timezone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      type: type ?? this.type,
      otherType: otherType ?? this.otherType,
      logoPath: logoPath ?? this.logoPath,
      email: email ?? this.email,
      countryCode: countryCode ?? this.countryCode,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'slug': slug,
    'type': type,
    'otherType': otherType,
    'logoPath': logoPath,
    'email': email,
    'countryCode': countryCode,
    'phone': phone,
    'currency': currency,
    'timezone': timezone,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  /// Prepares map payload for API create/update requests
  Map<String, dynamic> toApiMap() => {
    'name': name,
    'type': type,
    if (otherType != null && otherType!.isNotEmpty) 'otherType': otherType,
    if (email != null && email!.isNotEmpty) 'email': email,
    'countryCode': countryCode,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    'currency': currency,
    'timezone': timezone,
    'isActive': isActive,
  };

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: (json['id'] ?? '').toString(),
      ownerId: (json['ownerId'] ?? json['owner_id']) as String?,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      otherType: (json['otherType'] ?? json['other_type']) as String?,
      logoPath: (json['logoPath'] ?? json['logo_url']) as String?,
      email: json['email'] as String?,
      countryCode:
          (json['countryCode'] ?? json['country_code'] ?? '+91') as String,
      phone: json['phone'] as String?,
      currency: (json['currency'] ?? 'INR') as String,
      timezone: (json['timezone'] ?? 'Asia/Kolkata') as String,
      isActive: json['isActive'] == true || json['is_active'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : (json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null),
    );
  }
}
