enum ReportPeriod {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  allTime;

  String get label {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.thisYear:
        return 'This Year';
      case ReportPeriod.allTime:
        return 'All Time';
    }
  }

  /// Calculates the start and end DateTime boundaries for this period.
  DateTimeRange getDateRange() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (this) {
      case ReportPeriod.today:
        return DateTimeRange(start: todayStart, end: todayEnd);

      case ReportPeriod.thisWeek:
        // Week starts Monday (1)
        final weekday = now.weekday;
        final monday = todayStart.subtract(Duration(days: weekday - 1));
        final sunday = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
        return DateTimeRange(start: monday, end: sunday);

      case ReportPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final endOfMonth = nextMonth.subtract(const Duration(milliseconds: 1));
        return DateTimeRange(start: startOfMonth, end: endOfMonth);

      case ReportPeriod.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return DateTimeRange(start: startOfYear, end: endOfYear);

      case ReportPeriod.allTime:
        return DateTimeRange(
          start: DateTime.fromMillisecondsSinceEpoch(0),
          end: DateTime(2100, 1, 1),
        );
    }
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }
}
