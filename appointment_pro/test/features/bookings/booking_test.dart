import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/availability/data/models/availability_model.dart';
import 'package:appointment_pro/features/bussiness_setup/data/models/business_model.dart';
import 'package:appointment_pro/features/bookings/data/datasources/booking_local_datasource.dart';
import 'package:appointment_pro/features/bookings/data/models/booking_model.dart';
import 'package:appointment_pro/features/bookings/data/repositories/booking_repository.dart';
import 'package:appointment_pro/features/bookings/data/utils/booking_availability_calculator.dart';
import 'package:appointment_pro/features/bookings/data/utils/booking_slug_helper.dart';
import 'package:appointment_pro/features/services/data/models/service_model.dart';
import 'package:appointment_pro/features/staff/data/models/staff_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookingModel & Validation', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime(2026, 10, 15, 10, 0);
      final booking = BookingModel(
        id: 'bk_101',
        businessId: 'biz_glow',
        serviceId: 'srv_haircut',
        staffId: 'stf_alex',
        customerName: 'Jane Doe',
        customerCountryCode: '+1',
        customerPhone: '5551234567',
        customerEmail: 'jane@example.com',
        customerNotes: 'Prefers quiet session',
        startAt: now,
        endAt: now.add(const Duration(minutes: 45)),
        price: 45.0,
        status: BookingStatus.confirmed,
        createdAt: now,
      );

      final json = booking.toJson();
      final fromJson = BookingModel.fromJson(json);

      expect(fromJson.id, 'bk_101');
      expect(fromJson.businessId, 'biz_glow');
      expect(fromJson.serviceId, 'srv_haircut');
      expect(fromJson.staffId, 'stf_alex');
      expect(fromJson.customerName, 'Jane Doe');
      expect(fromJson.fullPhoneNumber, '+1 5551234567');
      expect(fromJson.price, 45.0);
      expect(fromJson.durationMinutes, 45);
      expect(fromJson.status, BookingStatus.confirmed);
      expect(fromJson.canComplete, isTrue);
      expect(fromJson.canConfirm, isFalse);
    });

    test('validates status transitions properly', () {
      final now = DateTime(2026, 10, 15, 14, 0);
      final pendingBooking = BookingModel(
        id: 'bk_201',
        businessId: 'biz_glow',
        serviceId: 'srv_1',
        customerName: 'Mark',
        customerPhone: '1234567',
        startAt: now,
        endAt: now.add(const Duration(minutes: 30)),
        price: 30.0,
        status: BookingStatus.pending,
      );

      // Pending can confirm or cancel, cannot complete directly
      expect(pendingBooking.canConfirm, isTrue);
      expect(pendingBooking.canCancel, isTrue);
      expect(pendingBooking.canComplete, isFalse);

      final confirmedBooking = pendingBooking.copyWith(
        status: BookingStatus.confirmed,
      );
      expect(confirmedBooking.canConfirm, isFalse);
      expect(confirmedBooking.canComplete, isTrue);
      expect(confirmedBooking.canMarkNoShow, isTrue);
      expect(confirmedBooking.canCancel, isTrue);

      final completedBooking = confirmedBooking.copyWith(
        status: BookingStatus.completed,
      );
      expect(completedBooking.canConfirm, isFalse);
      expect(completedBooking.canCancel, isFalse);
      expect(completedBooking.canComplete, isFalse);
      expect(completedBooking.isCompleted, isTrue);

      final cancelledBooking = pendingBooking.copyWith(
        status: BookingStatus.cancelled,
      );
      expect(cancelledBooking.canConfirm, isFalse);
      expect(cancelledBooking.canCancel, isFalse);
      expect(cancelledBooking.canComplete, isFalse);
      expect(cancelledBooking.isCancelled, isTrue);
    });
  });

  group('BookingSlugHelper & Link Generation', () {
    final business = BusinessModel(
      id: 'biz-1791',
      name: 'Glow Beauty & Spa!',
      type: 'Salon & Beauty',
      createdAt: DateTime.now(),
    );

    test('generates URL-safe and unique business slugs', () {
      final slug = BookingSlugHelper.generateSlug(business);
      expect(slug, contains('glow-beauty-spa'));
      expect(slug, contains('1791')); // includes ID suffix for uniqueness
      expect(slug.contains(' '), isFalse);
      expect(slug.contains('!'), isFalse);
      expect(slug.contains('&'), isFalse);
    });

    test('builds full shareable booking URL', () {
      final url = BookingSlugHelper.buildBookingUrl(business);
      expect(url, startsWith(BookingSlugHelper.publicBookingBaseUrl));
      expect(url, contains('glow-beauty-spa-1791'));
    });

    test('matches business by exact id or slug correctly', () {
      final slug = BookingSlugHelper.generateSlug(business);
      expect(BookingSlugHelper.matchesSlugOrId(business, 'biz-1791'), isTrue);
      expect(BookingSlugHelper.matchesSlugOrId(business, slug), isTrue);
      expect(
        BookingSlugHelper.matchesSlugOrId(business, 'glow-beauty-spa'),
        isTrue,
      );
      expect(
        BookingSlugHelper.matchesSlugOrId(business, 'unrelated-slug'),
        isFalse,
      );
    });
  });

  group('Booking Availability & Double-Booking Prevention', () {
    final service = ServiceModel(
      id: 'srv_massage',
      businessId: 'biz_spa',
      name: 'Swedish Massage',
      price: 60.0,
      durationMinutes: 45,
      bufferMinutes: 15, // Total required interval = 60 min
    );

    final staff1 = StaffModel(
      id: 'stf_1',
      businessId: 'biz_spa',
      name: 'Alice',
      assignedServiceIds: ['srv_massage'],
    );

    final staff2 = StaffModel(
      id: 'stf_2',
      businessId: 'biz_spa',
      name: 'Bob',
      assignedServiceIds: ['srv_massage'],
    );

    // Business open 09:00 to 12:00 (for test brevity)
    final schedule = <int, DaySchedule>{};
    for (int i = 1; i <= 7; i++) {
      schedule[i] = DaySchedule(
        dayOfWeek: i,
        isOpen: true,
        openTime: '09:00',
        closeTime: '12:00',
        breaks: const [
          TimeRange(startTime: '10:00', endTime: '10:30'),
        ], // Break
      );
    }
    final availability = BusinessAvailability(
      businessId: 'biz_spa',
      weeklySchedule: schedule,
    );

    test('calculates available slots respecting duration, buffer, and breaks', () {
      // Future date
      final date = DateTime(2027, 5, 10);
      final slots = BookingAvailabilityCalculator.calculateAvailableSlots(
        date: date,
        service: service,
        availability: availability,
        timeOffList: [],
        eligibleStaff: [staff1, staff2],
        existingBookings: [],
        now: DateTime(2027, 5, 1, 8, 0), // before date
      );

      // 09:00 to 09:45 + 15 min buffer = ends at 10:00. This fits before 10:00 break!
      expect(slots.any((s) => s.startTimeString == '09:00'), isTrue);

      // 09:30 to 10:15 + 15 min buffer overlaps the break (10:00 - 10:30), so must NOT be available!
      expect(slots.any((s) => s.startTimeString == '09:30'), isFalse);

      // 10:30 to 11:15 + 15 min buffer = 11:30. Fits after break!
      expect(slots.any((s) => s.startTimeString == '10:30'), isTrue);

      // 11:15 to 12:00 + 15 min buffer = 12:15, which exceeds 12:00 closing time. Must NOT be available!
      expect(slots.any((s) => s.startTimeString == '11:15'), isFalse);
    });

    test('rejects past slots for today', () {
      final today = DateTime(2026, 10, 15);
      final slots = BookingAvailabilityCalculator.calculateAvailableSlots(
        date: today,
        service: service,
        availability: availability,
        timeOffList: [],
        eligibleStaff: [staff1],
        existingBookings: [],
        now: DateTime(2026, 10, 15, 10, 45), // current time is 10:45 AM
      );

      // 09:00 is in the past, must be rejected
      expect(slots.any((s) => s.startTimeString == '09:00'), isFalse);
      // 10:30 is in the past, must be rejected
      expect(slots.any((s) => s.startTimeString == '10:30'), isFalse);
    });

    test('double-booking prevention: excludes conflicting staff slots', () {
      final date = DateTime(2027, 5, 10);

      // Existing booking for staff1 from 09:00 to 09:45
      final existingBooking = BookingModel(
        id: 'bk_conflict',
        businessId: 'biz_spa',
        serviceId: 'srv_massage',
        staffId: 'stf_1',
        customerName: 'Sam',
        customerPhone: '111222333',
        startAt: DateTime(2027, 5, 10, 9, 0),
        endAt: DateTime(2027, 5, 10, 9, 45),
        price: 60.0,
        status: BookingStatus.confirmed,
      );

      // When specifically requesting staff1: 09:00 must NOT be available
      final slotsForStaff1 =
          BookingAvailabilityCalculator.calculateAvailableSlots(
            date: date,
            service: service,
            availability: availability,
            timeOffList: [],
            eligibleStaff: [staff1],
            existingBookings: [existingBooking],
            requestedStaffId: 'stf_1',
            now: DateTime(2027, 5, 1, 8, 0),
          );
      expect(slotsForStaff1.any((s) => s.startTimeString == '09:00'), isFalse);

      // But when staff2 is also eligible ("Any Available"), 09:00 IS available because staff2 is free!
      final slotsAny = BookingAvailabilityCalculator.calculateAvailableSlots(
        date: date,
        service: service,
        availability: availability,
        timeOffList: [],
        eligibleStaff: [staff1, staff2],
        existingBookings: [existingBooking],
        now: DateTime(2027, 5, 1, 8, 0),
      );
      expect(slotsAny.any((s) => s.startTimeString == '09:00'), isTrue);

      final slotAt9 = slotsAny.firstWhere((s) => s.startTimeString == '09:00');
      // Only staff2 should be listed as available for 09:00
      expect(slotAt9.availableStaffIds, ['stf_2']);
    });

    test('isSlotStillAvailable rejects overlapping booking before saving', () {
      final existing = [
        BookingModel(
          id: 'bk_active',
          businessId: 'biz_spa',
          serviceId: 'srv_massage',
          staffId: 'stf_1',
          customerName: 'John',
          customerPhone: '999888777',
          startAt: DateTime(2027, 5, 10, 10, 30),
          endAt: DateTime(2027, 5, 10, 11, 15),
          price: 60.0,
          status: BookingStatus.confirmed,
        ),
      ];

      // Exact same interval -> unavailable
      final isAvailable1 = BookingAvailabilityCalculator.isSlotStillAvailable(
        startAt: DateTime(2027, 5, 10, 10, 30),
        endAt: DateTime(2027, 5, 10, 11, 15),
        bufferMinutes: 15,
        staffId: 'stf_1',
        existingBookings: existing,
      );
      expect(isAvailable1, isFalse);

      // Overlapping start -> unavailable
      final isAvailable2 = BookingAvailabilityCalculator.isSlotStillAvailable(
        startAt: DateTime(2027, 5, 10, 10, 0),
        endAt: DateTime(2027, 5, 10, 10, 45),
        bufferMinutes: 15,
        staffId: 'stf_1',
        existingBookings: existing,
      );
      expect(isAvailable2, isFalse);

      // Cancelled booking doesn't cause conflict -> available
      final cancelled = [
        existing.first.copyWith(status: BookingStatus.cancelled),
      ];
      final isAvailableCancelled =
          BookingAvailabilityCalculator.isSlotStillAvailable(
            startAt: DateTime(2027, 5, 10, 10, 30),
            endAt: DateTime(2027, 5, 10, 11, 15),
            bufferMinutes: 15,
            staffId: 'stf_1',
            existingBookings: cancelled,
          );
      expect(isAvailableCancelled, isTrue);
    });

    test('auto staff assignment picks specialist with lowest appointments', () {
      final dayBookings = [
        BookingModel(
          id: 'bk_1',
          businessId: 'biz_spa',
          serviceId: 'srv_1',
          staffId: 'stf_1', // staff1 already has 1 booking
          customerName: 'Client 1',
          customerPhone: '111',
          startAt: DateTime(2027, 5, 10, 14, 0),
          endAt: DateTime(2027, 5, 10, 14, 30),
          price: 30.0,
        ),
      ];

      final assignedStaffId =
          BookingAvailabilityCalculator.selectBestStaffForSlot(
            availableStaffIds: ['stf_1', 'stf_2'],
            existingBookingsForDay: dayBookings,
          );

      // staff2 has 0 bookings today, so staff2 must be chosen
      expect(assignedStaffId, 'stf_2');
    });
  });

  group('BookingRepository & Multi-Business Scoping', () {
    late LocalStorageService storage;
    late BookingRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorageService();
      repository = BookingRepository(BookingLocalDataSource(storage));
    });

    test(
      'creates and retrieves bookings scoped strictly to active business',
      () async {
        const bizA = 'biz_A';
        const bizB = 'biz_B';

        final bookingA = BookingModel(
          id: 'bk_A1',
          businessId: bizA,
          serviceId: 'srv_1',
          staffId: 'stf_1',
          customerName: 'Customer A',
          customerPhone: '12345678',
          startAt: DateTime(2026, 10, 20, 10, 0),
          endAt: DateTime(2026, 10, 20, 10, 45),
          price: 50.0,
        );

        final bookingB = BookingModel(
          id: 'bk_B1',
          businessId: bizB,
          serviceId: 'srv_2',
          staffId: 'stf_2',
          customerName: 'Customer B',
          customerPhone: '87654321',
          startAt: DateTime(2026, 10, 20, 11, 0),
          endAt: DateTime(2026, 10, 20, 11, 45),
          price: 75.0,
        );

        await repository.createBooking(bookingA);
        await repository.createBooking(bookingB);

        // Business A only sees booking A
        final listA = await repository.getBookings(bizA);
        expect(listA.length, 1);
        expect(listA.first.id, 'bk_A1');
        expect(listA.first.customerName, 'Customer A');

        // Business B only sees booking B
        final listB = await repository.getBookings(bizB);
        expect(listB.length, 1);
        expect(listB.first.id, 'bk_B1');
        expect(listB.first.customerName, 'Customer B');
      },
    );

    test('persists bookings across repository restarts', () async {
      final booking = BookingModel(
        id: 'bk_persist',
        businessId: 'biz_persist',
        serviceId: 'srv_p',
        customerName: 'Persistent User',
        customerPhone: '99988811',
        startAt: DateTime(2026, 10, 22, 9, 0),
        endAt: DateTime(2026, 10, 22, 9, 30),
        price: 40.0,
      );

      await repository.createBooking(booking);

      // Simulate app restart by instantiating new repository from same storage
      final newRepo = BookingRepository(BookingLocalDataSource(storage));
      final reloaded = await newRepo.getBookings('biz_persist');

      expect(reloaded.length, 1);
      expect(reloaded.first.id, 'bk_persist');
      expect(reloaded.first.customerName, 'Persistent User');
    });

    test('updates status and rejects illegal status transitions', () async {
      final booking = BookingModel(
        id: 'bk_status',
        businessId: 'biz_test',
        serviceId: 'srv_1',
        customerName: 'Status User',
        customerPhone: '12345678',
        startAt: DateTime(2026, 10, 25, 10, 0),
        endAt: DateTime(2026, 10, 25, 10, 30),
        price: 50.0,
        status: BookingStatus.pending,
      );

      await repository.createBooking(booking);

      // 1. Confirm pending booking -> success
      final confirmed = await repository.updateBookingStatus(
        'bk_status',
        BookingStatus.confirmed,
      );
      expect(confirmed.status, BookingStatus.confirmed);

      // 2. Complete confirmed booking -> success
      final completed = await repository.updateBookingStatus(
        'bk_status',
        BookingStatus.completed,
      );
      expect(completed.status, BookingStatus.completed);

      // 3. Attempting to modify completed booking must throw
      expect(
        () => repository.updateBookingStatus(
          'bk_status',
          BookingStatus.cancelled,
        ),
        throwsException,
      );
    });
  });
}
