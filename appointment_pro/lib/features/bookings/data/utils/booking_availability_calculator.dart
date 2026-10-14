import '../../../availability/data/models/availability_model.dart';
import '../../../services/data/models/service_model.dart';
import '../../../staff/data/models/staff_model.dart';
import '../models/booking_model.dart';
import '../models/booking_slot_model.dart';

class BookingAvailabilityCalculator {
  BookingAvailabilityCalculator._();

  /// Convenience method matching standard caller naming
  static List<BookingSlot> computeAvailableSlots({
    required String businessId,
    required ServiceModel service,
    required DateTime date,
    required BusinessAvailability businessAvailability,
    required List<StaffModel> eligibleStaff,
    required List<BookingModel> existingBookings,
    List<TimeOffRecord> timeOffList = const [],
    String? selectedStaffId,
  }) {
    return calculateAvailableSlots(
      date: date,
      service: service,
      availability: businessAvailability,
      timeOffList: timeOffList,
      eligibleStaff: eligibleStaff,
      existingBookings: existingBookings,
      requestedStaffId: selectedStaffId,
    );
  }

  /// Calculates all available booking slots for a given date, service, and staff constraint.
  static List<BookingSlot> calculateAvailableSlots({
    required DateTime date,
    required ServiceModel service,
    required BusinessAvailability availability,
    required List<TimeOffRecord> timeOffList,
    required List<StaffModel> eligibleStaff,
    required List<BookingModel> existingBookings,
    String? requestedStaffId,
    int stepMinutes = 15,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();

    // 1. Day of week schedule check (1 = Mon ... 7 = Sun)
    final dayOfWeek = date.weekday;
    final daySchedule = availability.weeklySchedule[dayOfWeek];
    if (daySchedule == null || !daySchedule.isOpen) {
      return [];
    }

    // 2. Business-wide holiday / time-off check
    final isHoliday = timeOffList.any((record) {
      if (!record.isBusinessWide) return false;
      return _isDateInRange(date, record.startDate, record.endDate);
    });

    if (isHoliday) {
      return [];
    }

    // 3. Operating hours
    final openMinutes = TimeRange.toMinutes(daySchedule.openTime);
    final closeMinutes = TimeRange.toMinutes(daySchedule.closeTime);
    final serviceDuration = service.durationMinutes;
    final bufferDuration = service.bufferMinutes;

    if (openMinutes >= closeMinutes || serviceDuration <= 0) {
      return [];
    }

    // 4. Candidate Staff: active staff assigned to this service
    final activeEligibleStaff = eligibleStaff.where((s) {
      if (!s.isActive) return false;
      if (!s.assignedServiceIds.contains(service.id)) return false;
      if (requestedStaffId != null && s.id != requestedStaffId) return false;
      return true;
    }).toList();

    if (activeEligibleStaff.isEmpty) {
      return [];
    }

    final slots = <BookingSlot>[];

    // 5. Iterate through time steps
    for (
      int m = openMinutes;
      m + serviceDuration + bufferDuration <= closeMinutes;
      m += stepMinutes
    ) {
      final slotStartMin = m;
      final slotEndMin = m + serviceDuration;
      final slotBufferEndMin = m + serviceDuration + bufferDuration;

      final slotTimeRange = TimeRange(
        startTime: TimeRange.fromMinutes(slotStartMin),
        endTime: TimeRange.fromMinutes(slotBufferEndMin),
      );

      // Check business breaks
      final overlapsBusinessBreak = daySchedule.breaks.any(
        (b) => slotTimeRange.overlaps(b),
      );
      if (overlapsBusinessBreak) {
        continue;
      }

      final slotStart = DateTime(
        date.year,
        date.month,
        date.day,
        slotStartMin ~/ 60,
        slotStartMin % 60,
      );
      final slotEnd = slotStart.add(Duration(minutes: serviceDuration));
      final slotBufferEnd = slotEnd.add(Duration(minutes: bufferDuration));

      // Skip past slots (giving 5-minute leeway)
      if (slotStart.isBefore(
        effectiveNow.subtract(const Duration(minutes: 5)),
      )) {
        continue;
      }

      // 6. Check eligible staff availability for this slot
      final availableStaffIds = <String>[];

      for (final staff in activeEligibleStaff) {
        // a) Staff personal time-off
        final staffOnLeave = timeOffList.any((t) {
          if (t.staffId != staff.id) return false;
          return _isDateInRange(date, t.startDate, t.endDate);
        });
        if (staffOnLeave) continue;

        // b) Staff custom schedule (if defined)
        if (staff.schedule != null && staff.schedule!.isNotEmpty) {
          final staffDay = staff.schedule![dayOfWeek];
          if (staffDay != null) {
            if (!staffDay.isOpen) continue;
            final staffOpen = TimeRange.toMinutes(staffDay.openTime);
            final staffClose = TimeRange.toMinutes(staffDay.closeTime);
            if (slotStartMin < staffOpen || slotEndMin > staffClose) continue;
            if (staffDay.breaks.any((b) => slotTimeRange.overlaps(b))) continue;
          }
        }

        // c) Conflict check against existing active bookings
        final hasConflict = existingBookings.any((booking) {
          if (booking.staffId != staff.id) return false;
          if (booking.status == BookingStatus.cancelled) return false;

          // Check interval overlap: [slotStart, slotBufferEnd) with [booking.startAt, booking.endAt)
          return slotStart.isBefore(booking.endAt) &&
              slotBufferEnd.isAfter(booking.startAt);
        });

        if (!hasConflict) {
          availableStaffIds.add(staff.id);
        }
      }

      // If at least one staff is available, slot is open!
      if (availableStaffIds.isNotEmpty) {
        slots.add(
          BookingSlot(
            startAt: slotStart,
            endAt: slotEnd,
            startTimeString: TimeRange.fromMinutes(slotStartMin),
            endTimeString: TimeRange.fromMinutes(slotEndMin),
            availableStaffIds: availableStaffIds,
            isAvailable: true,
          ),
        );
      }
    }

    return slots;
  }

  /// Re-validates that a proposed slot is still available right before saving.
  static bool isSlotStillAvailable({
    required DateTime startAt,
    required DateTime endAt,
    required int bufferMinutes,
    required String staffId,
    required List<BookingModel> existingBookings,
  }) {
    final bufferEnd = endAt.add(Duration(minutes: bufferMinutes));
    return !existingBookings.any((b) {
      if (b.staffId != staffId) return false;
      if (b.status == BookingStatus.cancelled) return false;
      return startAt.isBefore(b.endAt) && bufferEnd.isAfter(b.startAt);
    });
  }

  /// Selects the best staff member for automatic assignment ("Any Available").
  /// Chooses the staff member with the lowest number of appointments on that day.
  static String? selectBestStaffForSlot({
    required List<String> availableStaffIds,
    required List<BookingModel> existingBookingsForDay,
  }) {
    if (availableStaffIds.isEmpty) return null;
    if (availableStaffIds.length == 1) return availableStaffIds.first;

    // Count day appointments for each candidate
    final counts = <String, int>{for (final id in availableStaffIds) id: 0};
    for (final b in existingBookingsForDay) {
      if (b.staffId != null && counts.containsKey(b.staffId!)) {
        counts[b.staffId!] = counts[b.staffId!]! + 1;
      }
    }

    // Pick staff with minimum appointments
    String bestStaffId = availableStaffIds.first;
    int minCount = counts[bestStaffId] ?? 0;

    for (final id in availableStaffIds) {
      final c = counts[id] ?? 0;
      if (c < minCount) {
        minCount = c;
        bestStaffId = id;
      }
    }

    return bestStaffId;
  }

  static bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final target = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !target.isBefore(s) && !target.isAfter(e);
  }
}
