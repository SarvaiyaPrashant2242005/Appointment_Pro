class ServiceModel {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final int bufferMinutes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    this.bufferMinutes = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  ServiceModel copyWith({
    String? id,
    String? businessId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    int? bufferMinutes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'name': name,
    'description': description,
    'price': price,
    'durationMinutes': durationMinutes,
    'bufferMinutes': bufferMinutes,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final rawPrice = json['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0;

    final rawDuration = json['durationMinutes'] ?? json['duration_minutes'];
    final parsedDuration = rawDuration is num
        ? rawDuration.toInt()
        : int.tryParse(rawDuration?.toString() ?? '30') ?? 30;

    final rawBuffer = json['bufferMinutes'] ?? json['buffer_minutes'];
    final parsedBuffer = rawBuffer is num
        ? rawBuffer.toInt()
        : int.tryParse(rawBuffer?.toString() ?? '0') ?? 0;

    return ServiceModel(
      id: json['id']?.toString() ?? '',
      businessId:
          (json['businessId'] ?? json['business_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: parsedPrice,
      durationMinutes: parsedDuration,
      bufferMinutes: parsedBuffer,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(
        json['updatedAt'] ?? json['updated_at'] ?? json['createdAt'] ?? json['created_at'],
      ),
    );
  }
}
