import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

enum BookingStatus {
  confirmed,
  completed,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  String get displayLabel => displayName;

  Color get color {
    switch (this) {
      case BookingStatus.confirmed:
        return AppColors.accent;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
      case BookingStatus.noShow:
        return AppColors.textSecondary;
    }
  }

  bool get isActive => this == BookingStatus.confirmed;

  bool get isFinal =>
      this == BookingStatus.completed ||
      this == BookingStatus.cancelled ||
      this == BookingStatus.noShow;

  static BookingStatus fromString(String? value) {
    if (value == null || value.toLowerCase() == 'pending') {
      return BookingStatus.confirmed;
    }
    return BookingStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BookingStatus.confirmed,
    );
  }
}

class RescheduleRecord {
  final DateTime previousStartAt;
  final DateTime previousEndAt;
  final DateTime newStartAt;
  final DateTime newEndAt;
  final DateTime rescheduledAt;
  final String? previousStaffId;
  final String? newStaffId;
  final String? reason;

  const RescheduleRecord({
    required this.previousStartAt,
    required this.previousEndAt,
    required this.newStartAt,
    required this.newEndAt,
    required this.rescheduledAt,
    this.previousStaffId,
    this.newStaffId,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'previousStartAt': previousStartAt.toIso8601String(),
    'previousEndAt': previousEndAt.toIso8601String(),
    'newStartAt': newStartAt.toIso8601String(),
    'newEndAt': newEndAt.toIso8601String(),
    'rescheduledAt': rescheduledAt.toIso8601String(),
    'previousStaffId': previousStaffId,
    'newStaffId': newStaffId,
    'reason': reason,
  };

  factory RescheduleRecord.fromJson(Map<String, dynamic> json) {
    return RescheduleRecord(
      previousStartAt: DateTime.parse(json['previousStartAt'] as String),
      previousEndAt: DateTime.parse(json['previousEndAt'] as String),
      newStartAt: DateTime.parse(json['newStartAt'] as String),
      newEndAt: DateTime.parse(json['newEndAt'] as String),
      rescheduledAt: DateTime.parse(json['rescheduledAt'] as String),
      previousStaffId: json['previousStaffId'] as String?,
      newStaffId: json['newStaffId'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

class BookingModel {
  final String id;
  final String businessId;
  final String serviceId;
  final String? staffId; // null when unassigned
  final String customerName;
  final String customerCountryCode;
  final String customerPhone;
  final String? customerEmail;
  final String? customerNotes;
  final DateTime startAt;
  final DateTime endAt;
  final double price;
  final BookingStatus status;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final List<RescheduleRecord> rescheduleHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Cached display names for convenience when viewing disconnected lists
  final String? serviceName;
  final String? staffName;

  BookingModel({
    required this.id,
    required this.businessId,
    required this.serviceId,
    this.staffId,
    required this.customerName,
    this.customerCountryCode = '+91',
    required this.customerPhone,
    this.customerEmail,
    this.customerNotes,
    required this.startAt,
    required this.endAt,
    required this.price,
    this.status = BookingStatus.confirmed,
    this.cancellationReason,
    this.cancelledAt,
    this.rescheduleHistory = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.serviceName,
    this.staffName,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  int get durationMinutes => endAt.difference(startAt).inMinutes;

  String get fullPhoneNumber {
    final code = customerCountryCode.trim();
    final phone = customerPhone.trim();
    if (code.isEmpty) return phone;
    return '$code $phone';
  }

  bool get canConfirm => false;
  bool get canCancel => status == BookingStatus.confirmed;
  bool get canComplete => status == BookingStatus.confirmed;
  bool get canMarkNoShow => status == BookingStatus.confirmed;
  bool get canReschedule => status == BookingStatus.confirmed;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;

  BookingModel copyWith({
    String? id,
    String? businessId,
    String? serviceId,
    String? staffId,
    String? customerName,
    String? customerCountryCode,
    String? customerPhone,
    String? customerEmail,
    String? customerNotes,
    DateTime? startAt,
    DateTime? endAt,
    double? price,
    BookingStatus? status,
    String? cancellationReason,
    DateTime? cancelledAt,
    List<RescheduleRecord>? rescheduleHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serviceName,
    String? staffName,
  }) {
    return BookingModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      serviceId: serviceId ?? this.serviceId,
      staffId: staffId ?? this.staffId,
      customerName: customerName ?? this.customerName,
      customerCountryCode: customerCountryCode ?? this.customerCountryCode,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      customerNotes: customerNotes ?? this.customerNotes,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      price: price ?? this.price,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      rescheduleHistory: rescheduleHistory ?? this.rescheduleHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceName: serviceName ?? this.serviceName,
      staffName: staffName ?? this.staffName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'serviceId': serviceId,
    'staffId': staffId,
    'customerName': customerName,
    'customerCountryCode': customerCountryCode,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'customerNotes': customerNotes,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
    'price': price,
    'status': status.name,
    'cancellationReason': cancellationReason,
    'cancelledAt': cancelledAt?.toIso8601String(),
    'rescheduleHistory': rescheduleHistory.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'serviceName': serviceName,
    'staffName': staffName,
  };

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      serviceId: json['serviceId'] as String,
      staffId: json['staffId'] as String?,
      customerName: json['customerName'] as String,
      customerCountryCode: json['customerCountryCode'] as String? ?? '+91',
      customerPhone: json['customerPhone'] as String,
      customerEmail: json['customerEmail'] as String?,
      customerNotes: json['customerNotes'] as String?,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      price: (json['price'] as num).toDouble(),
      status: BookingStatus.fromString(json['status'] as String?),
      cancellationReason: json['cancellationReason'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      rescheduleHistory:
          (json['rescheduleHistory'] as List<dynamic>?)
              ?.map((e) => RescheduleRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['createdAt'] as String,
      ),
      serviceName: json['serviceName'] as String?,
      staffName: json['staffName'] as String?,
    );
  }
}
