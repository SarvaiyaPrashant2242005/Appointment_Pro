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
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    Map<int, DaySchedule>? parsedSchedule;
    final rawSchedule = json['schedule'];
    if (rawSchedule != null && rawSchedule is Map) {
      final raw = Map<String, dynamic>.from(rawSchedule);
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

    final rawServices = json['assignedServiceIds'] ?? json['services'];
    List<String> serviceIds = [];
    if (rawServices is List) {
      serviceIds = rawServices.map((e) {
        if (e is Map && e['id'] != null) return e['id'].toString();
        return e.toString();
      }).toList();
    }

    return StaffModel(
      id: json['id']?.toString() ?? '',
      businessId:
          (json['businessId'] ?? json['business_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      avatarPath: (json['avatarPath'] ?? json['avatar_url'])?.toString(),
      assignedServiceIds: serviceIds,
      schedule: parsedSchedule,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(
        json['updatedAt'] ?? json['updated_at'] ?? json['createdAt'] ?? json['created_at'],
      ),
    );
  }
}
