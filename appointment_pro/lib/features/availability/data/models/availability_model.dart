class TimeRange {
  final String startTime; // format: "HH:mm"
  final String endTime; // format: "HH:mm"

  const TimeRange({required this.startTime, required this.endTime});

  static int toMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  static String fromMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  int get startMinutes => toMinutes(startTime);
  int get endMinutes => toMinutes(endTime);

  bool get isValid => startMinutes < endMinutes;

  int get durationMinutes => endMinutes - startMinutes;

  bool overlaps(TimeRange other) {
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }

  bool isWithin(TimeRange parent) {
    return startMinutes >= parent.startMinutes &&
        endMinutes <= parent.endMinutes;
  }

  Map<String, dynamic> toJson() => {'startTime': startTime, 'endTime': endTime};

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    String formatTime(dynamic time, String def) {
      if (time == null) return def;
      final s = time.toString();
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    return TimeRange(
      startTime: formatTime(json['startTime'] ?? json['start_time'], '09:00'),
      endTime: formatTime(json['endTime'] ?? json['end_time'], '17:00'),
    );
  }
}

class DaySchedule {
  final int dayOfWeek; // 1 = Mon, 2 = Tue, ..., 7 = Sun
  final bool isOpen;
  final String openTime; // "HH:mm"
  final String closeTime; // "HH:mm"
  final List<TimeRange> breaks;

  const DaySchedule({
    required this.dayOfWeek,
    required this.isOpen,
    this.openTime = '09:00',
    this.closeTime = '18:00',
    this.breaks = const [],
  });

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Day $dayOfWeek';
    }
  }

  String get shortDayName {
    switch (dayOfWeek) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '$dayOfWeek';
    }
  }

  TimeRange get operatingHours =>
      TimeRange(startTime: openTime, endTime: closeTime);

  bool get areHoursValid => !isOpen || operatingHours.isValid;

  String? validateBreaks() {
    if (!isOpen) return null;
    final parent = operatingHours;
    if (!parent.isValid) {
      return 'Opening time must be earlier than closing time.';
    }

    for (int i = 0; i < breaks.length; i++) {
      final b = breaks[i];
      if (!b.isValid) {
        return 'Break #${i + 1} start must be before break end.';
      }
      if (!b.isWithin(parent)) {
        return 'Break #${i + 1} (${b.startTime}-${b.endTime}) must be within working hours ($openTime-$closeTime).';
      }
      for (int j = i + 1; j < breaks.length; j++) {
        if (b.overlaps(breaks[j])) {
          return 'Breaks #${i + 1} and #${j + 1} overlap.';
        }
      }
    }
    return null;
  }

  DaySchedule copyWith({
    int? dayOfWeek,
    bool? isOpen,
    String? openTime,
    String? closeTime,
    List<TimeRange>? breaks,
  }) {
    return DaySchedule(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      breaks: breaks ?? this.breaks,
    );
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'isOpen': isOpen,
    'openTime': openTime,
    'closeTime': closeTime,
    'breaks': breaks.map((b) => b.toJson()).toList(),
  };

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    final rawDay = json['dayOfWeek'] ?? json['day_of_week'];
    final dayOfWeek = rawDay is int
        ? rawDay
        : int.tryParse(rawDay?.toString() ?? '1') ?? 1;

    String formatTime(dynamic time, String def) {
      if (time == null) return def;
      final s = time.toString();
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    return DaySchedule(
      dayOfWeek: dayOfWeek,
      isOpen: json['isOpen'] ?? json['is_open'] ?? true,
      openTime: formatTime(json['openTime'] ?? json['open_time'], '09:00'),
      closeTime: formatTime(json['closeTime'] ?? json['close_time'], '18:00'),
      breaks:
          (json['breaks'] as List<dynamic>?)
              ?.map(
                (item) =>
                    TimeRange.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList() ??
          [],
    );
  }
}

class TimeOffRecord {
  final String id;
  final String businessId;
  final String? staffId; // null = entire business holiday
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool isFullDay;
  final String? note;
  final DateTime createdAt;

  TimeOffRecord({
    required this.id,
    required this.businessId,
    this.staffId,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.isFullDay = true,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isBusinessWide => staffId == null || staffId!.isEmpty;

  TimeOffRecord copyWith({
    String? id,
    String? businessId,
    String? staffId,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFullDay,
    String? note,
    DateTime? createdAt,
  }) {
    return TimeOffRecord(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      staffId: staffId ?? this.staffId,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isFullDay: isFullDay ?? this.isFullDay,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'staffId': staffId,
    'title': title,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'isFullDay': isFullDay,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TimeOffRecord.fromJson(Map<String, dynamic> json) {
    return TimeOffRecord(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      staffId: json['staffId'] as String?,
      title: json['title'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isFullDay: json['isFullDay'] as bool? ?? true,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class BusinessAvailability {
  final String businessId;
  final Map<int, DaySchedule> weeklySchedule;
  final String timezone;

  const BusinessAvailability({
    required this.businessId,
    required this.weeklySchedule,
    this.timezone = 'Asia/Kolkata',
  });

  static BusinessAvailability defaultFor(String businessId) {
    final schedule = <int, DaySchedule>{};
    for (int day = 1; day <= 7; day++) {
      if (day >= 1 && day <= 5) {
        // Mon-Fri: 9am - 6pm with 1pm - 2pm lunch break
        schedule[day] = DaySchedule(
          dayOfWeek: day,
          isOpen: true,
          openTime: '09:00',
          closeTime: '18:00',
          breaks: [const TimeRange(startTime: '13:00', endTime: '14:00')],
        );
      } else if (day == 6) {
        // Saturday: 10am - 4pm, no break
        schedule[day] = DaySchedule(
          dayOfWeek: day,
          isOpen: true,
          openTime: '10:00',
          closeTime: '16:00',
          breaks: [],
        );
      } else {
        // Sunday: Closed
        schedule[day] = DaySchedule(
          dayOfWeek: day,
          isOpen: false,
          openTime: '09:00',
          closeTime: '18:00',
          breaks: [],
        );
      }
    }
    return BusinessAvailability(
      businessId: businessId,
      weeklySchedule: schedule,
    );
  }

  BusinessAvailability copyWith({
    String? businessId,
    Map<int, DaySchedule>? weeklySchedule,
    String? timezone,
  }) {
    return BusinessAvailability(
      businessId: businessId ?? this.businessId,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      timezone: timezone ?? this.timezone,
    );
  }

  Map<String, dynamic> toJson() => {
    'businessId': businessId,
    'weeklySchedule': weeklySchedule.map(
      (k, v) => MapEntry(k.toString(), v.toJson()),
    ),
    'timezone': timezone,
  };

  factory BusinessAvailability.fromJson(Map<String, dynamic> json) {
    final schedule = <int, DaySchedule>{};

    final rawSchedule = json['weeklySchedule'];
    if (rawSchedule is Map) {
      rawSchedule.forEach((key, val) {
        final day = int.tryParse(key.toString());
        if (day != null && val is Map) {
          schedule[day] = DaySchedule.fromJson(Map<String, dynamic>.from(val));
        }
      });
    } else if (rawSchedule is List) {
      for (final item in rawSchedule) {
        if (item is Map) {
          final ds = DaySchedule.fromJson(Map<String, dynamic>.from(item));
          schedule[ds.dayOfWeek] = ds;
        }
      }
    }

    final rawOperatingHours = json['operatingHours'];
    if (rawOperatingHours is List) {
      for (final item in rawOperatingHours) {
        if (item is Map) {
          final ds = DaySchedule.fromJson(Map<String, dynamic>.from(item));
          schedule[ds.dayOfWeek] = ds;
        }
      }
    }

    return BusinessAvailability(
      businessId:
          (json['businessId'] ?? json['business_id'])?.toString() ?? '',
      weeklySchedule: schedule,
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
    );
  }
}
