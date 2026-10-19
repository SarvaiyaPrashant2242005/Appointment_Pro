import 'dart:convert';

enum NotificationType {
  newBooking,
  bookingCancelled,
  bookingRescheduled;

  String get value {
    switch (this) {
      case NotificationType.newBooking:
        return 'new_booking';
      case NotificationType.bookingCancelled:
        return 'booking_cancelled';
      case NotificationType.bookingRescheduled:
        return 'booking_rescheduled';
    }
  }

  static NotificationType fromString(String? val) {
    switch (val) {
      case 'new_booking':
      case 'newBooking':
        return NotificationType.newBooking;
      case 'booking_cancelled':
      case 'bookingCancelled':
        return NotificationType.bookingCancelled;
      case 'booking_rescheduled':
      case 'bookingRescheduled':
        return NotificationType.bookingRescheduled;
      default:
        return NotificationType.newBooking;
    }
  }
}

class AppNotificationModel {
  final String id;
  final String businessId;
  final String bookingId;
  final NotificationType type;
  final String title;
  final String body;
  final String customerName;
  final String serviceName;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> metadata;

  const AppNotificationModel({
    required this.id,
    required this.businessId,
    required this.bookingId,
    required this.type,
    required this.title,
    required this.body,
    required this.customerName,
    required this.serviceName,
    this.startAt,
    this.endAt,
    this.cancellationReason,
    required this.createdAt,
    this.isRead = false,
    this.metadata = const {},
  });

  AppNotificationModel copyWith({
    String? id,
    String? businessId,
    String? bookingId,
    NotificationType? type,
    String? title,
    String? body,
    String? customerName,
    String? serviceName,
    DateTime? startAt,
    DateTime? endAt,
    String? cancellationReason,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      customerName: customerName ?? this.customerName,
      serviceName: serviceName ?? this.serviceName,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'bookingId': bookingId,
      'type': type.value,
      'title': title,
      'body': body,
      'customerName': customerName,
      'serviceName': serviceName,
      'startAt': startAt?.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id']?.toString() ?? '',
      businessId: map['businessId']?.toString() ?? '',
      bookingId: map['bookingId']?.toString() ?? '',
      type: NotificationType.fromString(map['type']?.toString()),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? '',
      startAt: map['startAt'] != null
          ? DateTime.tryParse(map['startAt'].toString())
          : null,
      endAt: map['endAt'] != null
          ? DateTime.tryParse(map['endAt'].toString())
          : null,
      cancellationReason: map['cancellationReason']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] == true,
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotificationModel.fromJson(String source) =>
      AppNotificationModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
