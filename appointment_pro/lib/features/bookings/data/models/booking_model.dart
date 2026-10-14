import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  noShow;

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  String get displayLabel => displayName;

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return AppColors.warning;
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

  bool get isActive =>
      this == BookingStatus.pending || this == BookingStatus.confirmed;

  bool get isFinal =>
      this == BookingStatus.completed ||
      this == BookingStatus.cancelled ||
      this == BookingStatus.noShow;

  static BookingStatus fromString(String? value) {
    if (value == null) return BookingStatus.pending;
    return BookingStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BookingStatus.pending,
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
    this.status = BookingStatus.pending,
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

  bool get canConfirm => status == BookingStatus.pending;
  bool get canCancel =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;
  bool get canComplete => status == BookingStatus.confirmed;
  bool get canMarkNoShow => status == BookingStatus.confirmed;
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['createdAt'] as String,
      ),
      serviceName: json['serviceName'] as String?,
      staffName: json['staffName'] as String?,
    );
  }
}
