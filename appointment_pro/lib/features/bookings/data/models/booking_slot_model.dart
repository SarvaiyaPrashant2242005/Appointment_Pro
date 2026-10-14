enum SlotPeriod {
  morning,
  afternoon,
  evening;

  String get displayName {
    switch (this) {
      case SlotPeriod.morning:
        return 'Morning';
      case SlotPeriod.afternoon:
        return 'Afternoon';
      case SlotPeriod.evening:
        return 'Evening';
    }
  }
}

class BookingSlot {
  final DateTime startAt;
  final DateTime endAt;
  final String startTimeString; // "HH:mm"
  final String endTimeString; // "HH:mm"
  final List<String> availableStaffIds;
  final bool isAvailable;
  final String? unavailableReason;

  const BookingSlot({
    required this.startAt,
    required this.endAt,
    required this.startTimeString,
    required this.endTimeString,
    this.availableStaffIds = const [],
    this.isAvailable = true,
    this.unavailableReason,
  });

  DateTime get start => startAt;
  DateTime get end => endAt;

  String get timeRangeLabel => '$startTimeString - $endTimeString';
  String get formattedTime => timeRangeLabel;

  SlotPeriod get period {
    final hour = startAt.hour;
    if (hour < 12) return SlotPeriod.morning;
    if (hour < 17) return SlotPeriod.afternoon;
    return SlotPeriod.evening;
  }

  String get periodName => period.displayName;

  BookingSlot copyWith({
    DateTime? startAt,
    DateTime? endAt,
    String? startTimeString,
    String? endTimeString,
    List<String>? availableStaffIds,
    bool? isAvailable,
    String? unavailableReason,
  }) {
    return BookingSlot(
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      startTimeString: startTimeString ?? this.startTimeString,
      endTimeString: endTimeString ?? this.endTimeString,
      availableStaffIds: availableStaffIds ?? this.availableStaffIds,
      isAvailable: isAvailable ?? this.isAvailable,
      unavailableReason: unavailableReason ?? this.unavailableReason,
    );
  }
}
