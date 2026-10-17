class CustomerModel {
  final String id;
  final String businessId;
  final String name;
  final String countryCode;
  final String phone;
  final String? email;
  final String? notes;
  final int totalBookings;
  final DateTime? lastBookingAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.countryCode = '+91',
    required this.phone,
    this.email,
    this.notes,
    this.totalBookings = 0,
    this.lastBookingAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get formattedPhone =>
      phone.startsWith('+') ? phone : '$countryCode $phone';

  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  CustomerModel copyWith({
    String? id,
    String? businessId,
    String? name,
    String? countryCode,
    String? phone,
    String? email,
    String? notes,
    int? totalBookings,
    DateTime? lastBookingAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      totalBookings: totalBookings ?? this.totalBookings,
      lastBookingAt: lastBookingAt ?? this.lastBookingAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'name': name,
        'countryCode': countryCode,
        'phone': phone,
        'email': email,
        'notes': notes,
        'totalBookings': totalBookings,
        'lastBookingAt': lastBookingAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    final rawBookingsCount =
        json['totalBookings'] ?? json['total_bookings'] ?? json['bookingsCount'];
    final parsedBookingsCount = rawBookingsCount is num
        ? rawBookingsCount.toInt()
        : int.tryParse(rawBookingsCount?.toString() ?? '0') ?? 0;

    return CustomerModel(
      id: json['id']?.toString() ?? '',
      businessId:
          (json['businessId'] ?? json['business_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      countryCode:
          (json['countryCode'] ?? json['country_code'])?.toString() ?? '+91',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      notes: json['notes']?.toString(),
      totalBookings: parsedBookingsCount,
      lastBookingAt: parseNullableDate(
        json['lastBookingAt'] ?? json['last_booking_at'],
      ),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(
        json['updatedAt'] ??
            json['updated_at'] ??
            json['createdAt'] ??
            json['created_at'],
      ),
    );
  }
}
