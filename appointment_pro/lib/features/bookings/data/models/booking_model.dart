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
  final String? customerId;
  final String? bookingReference;
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
    this.customerId,
    this.bookingReference,
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

  /// Human-friendly display ID that is clean, readable, and never an ugly raw UUID.
  String get displayId {
    if (bookingReference != null && bookingReference!.trim().isNotEmpty) {
      return bookingReference!.trim();
    }
    if (id.startsWith('AP-') || id.startsWith('BK-')) {
      return id;
    }
    // If id is a raw UUID (contains hyphens and length > 8), format it cleanly
    if (id.contains('-') && id.length >= 8) {
      final clean = id.replaceAll('-', '').toUpperCase();
      return 'AP-${clean.substring(0, 6)}';
    }
    return id.isEmpty ? 'AP-000000' : id;
  }

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
    String? customerId,
    String? bookingReference,
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
      customerId: customerId ?? this.customerId,
      bookingReference: bookingReference ?? this.bookingReference,
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
    'customerId': customerId,
    'bookingReference': bookingReference ?? displayId,
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
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final rawPrice = json['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0;

    final rawReschedule = json['rescheduleHistory'];
    List<RescheduleRecord> history = [];
    if (rawReschedule is List) {
      history = rawReschedule
          .map((e) => RescheduleRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final rawId = json['id']?.toString() ?? '';
    final rawRef = (json['bookingReference'] ??
            json['booking_reference'] ??
            json['bookingRef'])
        ?.toString();

    // Prefer human-friendly booking reference if available, fallback to id
    final cleanId = (rawRef != null && rawRef.isNotEmpty) ? rawRef : rawId;

    return BookingModel(
      id: cleanId,
      businessId:
          (json['businessId'] ?? json['business_id'])?.toString() ?? '',
      serviceId:
          (json['serviceId'] ?? json['service_id'])?.toString() ?? '',
      staffId: (json['staffId'] ?? json['staff_id'])?.toString(),
      customerId: (json['customerId'] ?? json['customer_id'])?.toString(),
      bookingReference: rawRef ?? (cleanId.startsWith('AP-') ? cleanId : null),
      customerName:
          (json['customerName'] ?? json['customer_name'])?.toString() ?? '',
      customerCountryCode: (json['customerCountryCode'] ??
              json['customer_country_code'])
          ?.toString() ??
          '+91',
      customerPhone:
          (json['customerPhone'] ?? json['customer_phone'])?.toString() ?? '',
      customerEmail:
          (json['customerEmail'] ?? json['customer_email'])?.toString(),
      customerNotes:
          (json['customerNotes'] ?? json['customer_notes'])?.toString(),
      startAt: parseDate(json['startAt'] ?? json['start_at']),
      endAt: parseDate(json['endAt'] ?? json['end_at']),
      price: parsedPrice,
      status: BookingStatus.fromString(json['status']?.toString()),
      cancellationReason: (json['cancellationReason'] ??
              json['cancellation_reason'])
          ?.toString(),
      cancelledAt: (json['cancelledAt'] ?? json['cancelled_at']) != null
          ? parseDate(json['cancelledAt'] ?? json['cancelled_at'])
          : null,
      rescheduleHistory: history,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(
        json['updatedAt'] ?? json['updated_at'] ?? json['createdAt'] ?? json['created_at'],
      ),
      serviceName:
          (json['serviceName'] ?? json['service_name'])?.toString(),
      staffName: (json['staffName'] ?? json['staff_name'])?.toString(),
    );
  }
}
