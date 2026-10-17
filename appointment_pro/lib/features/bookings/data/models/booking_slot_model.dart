import 'package:intl/intl.dart';

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
  final String startTimeString; // "HH:mm" (internal 24h format for calculator)
  final String endTimeString; // "HH:mm" (internal 24h format for calculator)
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

  /// Helper to format DateTime to 12-hour format "h:mm a" (e.g. "9:00 AM", "2:30 PM")
  static String format12Hour(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  /// 12-hour formatted start time (e.g. "9:00 AM", "2:30 PM")
  String get startTime12 => format12Hour(startAt);

  /// 12-hour formatted end time (e.g. "9:45 AM", "3:15 PM")
  String get endTime12 => format12Hour(endAt);

  /// 12-hour formatted time range label (e.g. "9:00 AM - 9:45 AM", "2:00 PM - 2:45 PM")
  String get timeRangeLabel => '$startTime12 - $endTime12';

  /// Primary display format in 12-hour format for slot chips and screens
  String get formattedTime => timeRangeLabel;

  /// Shorter 12-hour start time display
  String get formattedStartTime => startTime12;

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
