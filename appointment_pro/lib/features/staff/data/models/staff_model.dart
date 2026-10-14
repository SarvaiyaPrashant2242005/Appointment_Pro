import '../../../availability/data/models/availability_model.dart';

class StaffModel {
  final String id;
  final String businessId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final List<String> assignedServiceIds;
  final Map<int, DaySchedule>? schedule;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.email,
    this.phone,
    this.avatarPath,
    this.assignedServiceIds = const [],
    this.schedule,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  StaffModel copyWith({
    String? id,
    String? businessId,
    String? name,
    String? email,
    String? phone,
    String? avatarPath,
    List<String>? assignedServiceIds,
    Map<int, DaySchedule>? schedule,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      assignedServiceIds: assignedServiceIds ?? this.assignedServiceIds,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'name': name,
    'email': email,
    'phone': phone,
    'avatarPath': avatarPath,
    'assignedServiceIds': assignedServiceIds,
    'schedule': schedule?.map((k, v) => MapEntry(k.toString(), v.toJson())),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    Map<int, DaySchedule>? parsedSchedule;
    if (json['schedule'] != null && json['schedule'] is Map) {
      final raw = json['schedule'] as Map<String, dynamic>;
      parsedSchedule = {};
      raw.forEach((k, v) {
        final day = int.tryParse(k);
        if (day != null && v is Map) {
          parsedSchedule![day] = DaySchedule.fromJson(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }

    return StaffModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarPath: json['avatarPath'] as String?,
      assignedServiceIds:
          (json['assignedServiceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      schedule: parsedSchedule,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['createdAt'] as String,
      ),
    );
  }
}
