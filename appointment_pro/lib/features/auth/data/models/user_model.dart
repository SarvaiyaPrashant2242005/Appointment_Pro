import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.role = 'owner',
    this.avatarUrl,
    this.isActive = true,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Resolves avatar URL (prepending server origin if relative server path, or returning local path if it exists on disk)
  String? get fullAvatarUrl {
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) return null;
    final path = avatarUrl!.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final file = File(path);
    if (file.existsSync()) {
      return path;
    }
    if (path.startsWith('/')) {
      return '${ApiEndpoints.baseOrigin}$path';
    }
    return '${ApiEndpoints.baseOrigin}/$path';
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? avatarUrl,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'avatarUrl': avatarUrl,
    'isActive': isActive,
    'isEmailVerified': isEmailVerified,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      role: (json['role'] ?? 'owner') as String,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
      isEmailVerified:
          (json['isEmailVerified'] ?? json['is_email_verified'] ?? false) as bool,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}
