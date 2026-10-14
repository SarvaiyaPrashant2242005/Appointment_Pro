import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/availability/data/models/availability_model.dart';
import 'package:appointment_pro/features/availability/data/repositories/availability_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimeRange & DaySchedule Validation', () {
    test('TimeRange calculates duration and overlaps correctly', () {
      final range1 = TimeRange(startTime: '09:00', endTime: '12:00');
      final range2 = TimeRange(startTime: '11:30', endTime: '13:00');
      final range3 = TimeRange(startTime: '13:00', endTime: '14:00');

      expect(range1.durationMinutes, 180);
      expect(
        range1.overlaps(range2),
        isTrue,
      ); // 11:30 is between 09:00 and 12:00
      expect(range1.overlaps(range3), isFalse); // 13:00 starts after 12:00
    });

    test('TimeRange isWithin correctly verifies boundaries', () {
      final businessHours = TimeRange(startTime: '09:00', endTime: '18:00');
      final lunchBreak = TimeRange(startTime: '13:00', endTime: '14:00');
      final invalidEarlyBreak = TimeRange(startTime: '08:30', endTime: '09:30');
      final invalidLateBreak = TimeRange(startTime: '17:30', endTime: '18:30');

      expect(lunchBreak.isWithin(businessHours), isTrue);
      expect(invalidEarlyBreak.isWithin(businessHours), isFalse);
      expect(invalidLateBreak.isWithin(businessHours), isFalse);
    });

    test('DaySchedule validateBreaks catches invalid configurations', () {
      // 1. Closing time earlier than or equal to opening time
      final invalidHoursSchedule = const DaySchedule(
        dayOfWeek: 1,
        isOpen: true,
        openTime: '18:00',
        closeTime: '09:00',
      );
      expect(
        invalidHoursSchedule.validateBreaks(),
        'Opening time must be earlier than closing time.',
      );

      // 2. Break outside working hours
      final outOfBoundsSchedule = const DaySchedule(
        dayOfWeek: 2,
        isOpen: true,
        openTime: '09:00',
        closeTime: '17:00',
        breaks: [TimeRange(startTime: '17:00', endTime: '18:00')],
      );
      expect(
        outOfBoundsSchedule.validateBreaks(),
        contains('must be within working hours'),
      );

      // 3. Overlapping breaks
      final overlappingBreaksSchedule = const DaySchedule(
        dayOfWeek: 3,
        isOpen: true,
        openTime: '09:00',
        closeTime: '18:00',
        breaks: [
          TimeRange(startTime: '12:00', endTime: '13:30'),
          TimeRange(startTime: '13:00', endTime: '14:00'),
        ],
      );
      expect(overlappingBreaksSchedule.validateBreaks(), contains('overlap'));

      // 4. Valid schedule with non-overlapping breaks inside working hours
      final validSchedule = const DaySchedule(
        dayOfWeek: 4,
        isOpen: true,
        openTime: '09:00',
        closeTime: '19:00',
        breaks: [
          TimeRange(startTime: '12:00', endTime: '13:00'),
          TimeRange(startTime: '16:00', endTime: '16:30'),
        ],
      );
      expect(validSchedule.validateBreaks(), isNull);
    });
  });

  group('AvailabilityRepository & Multi-Business Scoping', () {
    late LocalStorageService storageService;
    late AvailabilityRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      repository = AvailabilityRepository(storageService);
    });

    test(
      'loads default schedule if none exists and persists modifications',
      () async {
        final initial = await repository.getBusinessAvailability('biz_test');
        expect(initial.businessId, 'biz_test');
        expect(initial.weeklySchedule.length, 7);
        expect(initial.weeklySchedule[1]!.isOpen, isTrue); // Monday open
        expect(
          initial.weeklySchedule[7]!.isOpen,
          isFalse,
        ); // Sunday closed by default

        // Modify Saturday hours and add a break
        final updatedMap = Map<int, DaySchedule>.from(initial.weeklySchedule);
        updatedMap[6] = updatedMap[6]!.copyWith(
          isOpen: true,
          openTime: '10:00',
          closeTime: '16:00',
          breaks: [const TimeRange(startTime: '12:30', endTime: '13:00')],
        );

        final modified = initial.copyWith(weeklySchedule: updatedMap);
        await repository.saveBusinessAvailability(modified);

        // Verify persistence across new repository instance
        final reloadedRepo = AvailabilityRepository(storageService);
        final reloaded = await reloadedRepo.getBusinessAvailability('biz_test');

        expect(reloaded.weeklySchedule[6]!.openTime, '10:00');
        expect(reloaded.weeklySchedule[6]!.closeTime, '16:00');
        expect(reloaded.weeklySchedule[6]!.breaks.length, 1);
        expect(reloaded.weeklySchedule[6]!.breaks.first.startTime, '12:30');
      },
    );

    test('saves, lists, and deletes holiday / time off records', () async {
      final holiday = TimeOffRecord(
        id: 'hol-1',
        businessId: 'biz_holiday',
        title: 'New Year Holiday',
        startDate: DateTime(2027, 1, 1),
        endDate: DateTime(2027, 1, 1, 23, 59, 59),
        isFullDay: true,
        note: 'All locations closed',
      );

      final staffLeave = TimeOffRecord(
        id: 'leave-1',
        businessId: 'biz_holiday',
        staffId: 'staff-99',
        title: 'Dr. John Annual Leave',
        startDate: DateTime(2027, 2, 10),
        endDate: DateTime(2027, 2, 15),
        isFullDay: true,
      );

      await repository.addTimeOff(holiday);
      await repository.addTimeOff(staffLeave);

      var records = await repository.getTimeOffRecords('biz_holiday');
      expect(records.length, 2);
      expect(records.any((r) => r.title == 'New Year Holiday'), isTrue);
      expect(records.any((r) => r.staffId == 'staff-99'), isTrue);

      // Delete the staff leave
      await repository.deleteTimeOff('biz_holiday', 'leave-1');
      records = await repository.getTimeOffRecords('biz_holiday');
      expect(records.length, 1);
      expect(records.first.id, 'hol-1');
    });

    test(
      'isolates availability and holidays across multiple businesses',
      () async {
        final bizAAvail = (await repository.getBusinessAvailability('biz_A'))
            .copyWith(
              weeklySchedule: {
                1: const DaySchedule(
                  dayOfWeek: 1,
                  isOpen: true,
                  openTime: '08:00',
                  closeTime: '20:00',
                ),
              },
            );
        final bizBAvail = (await repository.getBusinessAvailability('biz_B'))
            .copyWith(
              weeklySchedule: {
                1: const DaySchedule(
                  dayOfWeek: 1,
                  isOpen: true,
                  openTime: '11:00',
                  closeTime: '15:00',
                ),
              },
            );

        await repository.saveBusinessAvailability(bizAAvail);
        await repository.saveBusinessAvailability(bizBAvail);

        final a = await repository.getBusinessAvailability('biz_A');
        final b = await repository.getBusinessAvailability('biz_B');

        expect(a.weeklySchedule[1]!.openTime, '08:00');
        expect(b.weeklySchedule[1]!.openTime, '11:00');

        // Add holiday to biz_A
        await repository.addTimeOff(
          TimeOffRecord(
            id: 'h-a',
            businessId: 'biz_A',
            title: 'Biz A Founder Day',
            startDate: DateTime(2027, 3, 1),
            endDate: DateTime(2027, 3, 1),
          ),
        );

        final listA = await repository.getTimeOffRecords('biz_A');
        final listB = await repository.getTimeOffRecords('biz_B');

        expect(listA.length, 1);
        expect(listB, isEmpty);
      },
    );

    test(
      'applies one day schedule and breaks to all open days correctly',
      () async {
        final initial = await repository.getBusinessAvailability('biz_apply');
        // Setup Monday with custom hours and break
        final mondayBreaks = [
          const TimeRange(startTime: '13:00', endTime: '16:00'),
        ];
        final updatedMap = Map<int, DaySchedule>.from(initial.weeklySchedule);
        updatedMap[1] = updatedMap[1]!.copyWith(
          isOpen: true,
          openTime: '08:30',
          closeTime: '19:30',
          breaks: mondayBreaks,
        );
        // Ensure Tuesday is open, Sunday is closed
        updatedMap[2] = updatedMap[2]!.copyWith(isOpen: true);
        updatedMap[7] = updatedMap[7]!.copyWith(isOpen: false);

        final modified = initial.copyWith(weeklySchedule: updatedMap);
        await repository.saveBusinessAvailability(modified);

        // Apply Monday (dayOfWeek: 1) to all open days
        final source = modified.weeklySchedule[1]!;
        final appliedMap = Map<int, DaySchedule>.from(modified.weeklySchedule);
        for (final entry in modified.weeklySchedule.entries) {
          if (entry.key != 1 && entry.value.isOpen) {
            appliedMap[entry.key] = entry.value.copyWith(
              openTime: source.openTime,
              closeTime: source.closeTime,
              breaks: List<TimeRange>.from(source.breaks),
            );
          }
        }
        await repository.saveBusinessAvailability(
          modified.copyWith(weeklySchedule: appliedMap),
        );

        final result = await repository.getBusinessAvailability('biz_apply');

        // Tuesday (open) should now have Monday's hours and breaks
        expect(result.weeklySchedule[2]!.openTime, '08:30');
        expect(result.weeklySchedule[2]!.closeTime, '19:30');
        expect(result.weeklySchedule[2]!.breaks.length, 1);
        expect(result.weeklySchedule[2]!.breaks.first.startTime, '13:00');
        expect(result.weeklySchedule[2]!.breaks.first.endTime, '16:00');

        // Sunday (closed) should remain closed
        expect(result.weeklySchedule[7]!.isOpen, isFalse);
      },
    );
  });
}
