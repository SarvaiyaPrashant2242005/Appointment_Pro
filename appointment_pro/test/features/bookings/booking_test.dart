import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/availability/data/models/availability_model.dart';
import 'package:appointment_pro/features/bussiness_setup/data/models/business_model.dart';
import 'package:appointment_pro/features/bookings/data/datasources/booking_local_datasource.dart';
import 'package:appointment_pro/features/bookings/data/models/booking_model.dart';
import 'package:appointment_pro/features/bookings/data/models/booking_slot_model.dart';
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

    test('human-friendly booking ID display prevents raw UUID and overflow', () {
      final now = DateTime(2026, 10, 15, 10, 0);

      // Case 1: Backend generates human reference (e.g. AP-849201)
      final refBooking = BookingModel(
        id: 'AP-849201',
        bookingReference: 'AP-849201',
        businessId: 'biz_1',
        serviceId: 'srv_1',
        customerName: 'Alice',
        customerPhone: '5551234',
        startAt: now,
        endAt: now.add(const Duration(minutes: 30)),
        price: 25.0,
      );
      expect(refBooking.displayId, 'AP-849201');
      expect(refBooking.displayId.length, lessThanOrEqualTo(10));

      // Case 2: Legacy raw UUID from database is cleanly formatted to AP-XXXXXX
      final uuidBooking = BookingModel(
        id: 'a444a36f-31ef-41aa-94a5-cb6a6358ded4',
        businessId: 'biz_1',
        serviceId: 'srv_1',
        customerName: 'John Doe',
        customerPhone: '5559876',
        startAt: now,
        endAt: now.add(const Duration(minutes: 30)),
        price: 50.0,
      );
      expect(uuidBooking.displayId, 'AP-A444A3');
      expect(uuidBooking.displayId.startsWith('AP-'), isTrue);
      expect(uuidBooking.displayId.contains('-31ef'), isFalse);

      // Case 3: fromJson prioritizes booking_reference from API response
      final jsonResponse = {
        'id': 'a444a36f-31ef-41aa-94a5-cb6a6358ded4',
        'booking_reference': 'AP-739210',
        'business_id': 'biz_1',
        'service_id': 'srv_1',
        'customer_name': 'John Doe',
        'customer_phone': '5559876',
        'start_at': now.toIso8601String(),
        'end_at': now.add(const Duration(minutes: 30)).toIso8601String(),
        'price': 50.0,
        'status': 'confirmed',
      };
      final parsed = BookingModel.fromJson(jsonResponse);
      expect(parsed.displayId, 'AP-739210');
      expect(parsed.id, 'AP-739210');
    });

    test('BookingSlot formats times in 12-hour format with AM/PM', () {
      // Morning slot: 09:30 - 10:15
      final morningSlot = BookingSlot(
        startAt: DateTime(2026, 10, 17, 9, 30),
        endAt: DateTime(2026, 10, 17, 10, 15),
        startTimeString: '09:30',
        endTimeString: '10:15',
      );
      expect(morningSlot.startTime12, '9:30 AM');
      expect(morningSlot.endTime12, '10:15 AM');
      expect(morningSlot.formattedTime, '9:30 AM - 10:15 AM');
      expect(morningSlot.timeRangeLabel, '9:30 AM - 10:15 AM');

      // Afternoon slot: 14:00 - 14:50 (formerly 14:00 - 14:50 in 24h)
      final afternoonSlot = BookingSlot(
        startAt: DateTime(2026, 10, 17, 14, 0),
        endAt: DateTime(2026, 10, 17, 14, 50),
        startTimeString: '14:00',
        endTimeString: '14:50',
      );
      expect(afternoonSlot.startTime12, '2:00 PM');
      expect(afternoonSlot.endTime12, '2:50 PM');
      expect(afternoonSlot.formattedTime, '2:00 PM - 2:50 PM');
      expect(afternoonSlot.timeRangeLabel, '2:00 PM - 2:50 PM');

      // Evening slot: 18:30 - 19:15
      final eveningSlot = BookingSlot(
        startAt: DateTime(2026, 10, 17, 18, 30),
        endAt: DateTime(2026, 10, 17, 19, 15),
        startTimeString: '18:30',
        endTimeString: '19:15',
      );
      expect(eveningSlot.startTime12, '6:30 PM');
      expect(eveningSlot.endTime12, '7:15 PM');
      expect(eveningSlot.formattedTime, '6:30 PM - 7:15 PM');
    });

    test('validates status transitions properly', () {
      final now = DateTime(2026, 10, 15, 14, 0);
      final confirmedBooking = BookingModel(
        id: 'bk_201',
        businessId: 'biz_glow',
        serviceId: 'srv_1',
        customerName: 'Mark',
        customerPhone: '1234567',
        startAt: now,
        endAt: now.add(const Duration(minutes: 30)),
        price: 30.0,
        status: BookingStatus.confirmed,
      );

      // Confirmed can complete, mark no-show, reschedule, or cancel
      expect(confirmedBooking.canConfirm, isFalse);
      expect(confirmedBooking.canComplete, isTrue);
      expect(confirmedBooking.canMarkNoShow, isTrue);
      expect(confirmedBooking.canCancel, isTrue);
      expect(confirmedBooking.canReschedule, isTrue);

      final completedBooking = confirmedBooking.copyWith(
        status: BookingStatus.completed,
      );
      expect(completedBooking.canConfirm, isFalse);
      expect(completedBooking.canCancel, isFalse);
      expect(completedBooking.canComplete, isFalse);
      expect(completedBooking.isCompleted, isTrue);

      final cancelledBooking = confirmedBooking.copyWith(
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

    test('normalizes internal/local server URLs to production domain', () {
      final bizWithLocalUrl = BusinessModel(
        id: 'd8cea7d1-292c-4fbc-ac89-bed16ab371b0',
        name: 'JP Tech Class',
        type: 'Education & Teaching',
        slug: 'jp-tech-class-5882',
        bookingUrl:
            'http://172.28.0.3:5000/jp-tech-class-5882/d8cea7d1-292c-4fbc-ac89-bed16ab371b0',
        createdAt: DateTime.now(),
      );

      final url = BookingSlugHelper.buildBookingUrl(bizWithLocalUrl);
      expect(
        url,
        equals(
          'https://appointment-pro.rishvi.app/jp-tech-class-5882/d8cea7d1-292c-4fbc-ac89-bed16ab371b0',
        ),
      );

      final apexMedico = BusinessModel(
        id: '9b8cb716-755a-4a73-af62-3a72e13079ec',
        name: 'Apex Medico',
        type: 'Healthcare & Clinic',
        slug: 'apex-medico-6485',
        bookingUrl:
            'http://172.28.0.3:5000/apex-medico-6485/9b8cb716-755a-4a73-af62-3a72e13079ec',
        createdAt: DateTime.now(),
      );

      final apexUrl = BookingSlugHelper.buildBookingUrl(apexMedico);
      expect(
        apexUrl,
        equals(
          'https://appointment-pro.rishvi.app/apex-medico-6485/9b8cb716-755a-4a73-af62-3a72e13079ec',
        ),
      );
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
        status: BookingStatus.confirmed,
      );

      await repository.createBooking(booking);

      // 1. Complete confirmed booking -> success
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

    test('cancels booking with optional reason and timestamp', () async {
      final booking = BookingModel(
        id: 'bk_cancel_test',
        businessId: 'biz_cancel',
        serviceId: 'srv_c',
        customerName: 'Cancel User',
        customerPhone: '5551234',
        startAt: DateTime(2026, 10, 26, 11, 0),
        endAt: DateTime(2026, 10, 26, 11, 30),
        price: 55.0,
        status: BookingStatus.confirmed,
      );

      await repository.createBooking(booking);

      final cancelled = await repository.updateBookingStatus(
        'bk_cancel_test',
        BookingStatus.cancelled,
        cancellationReason: 'Doctor emergency',
      );

      expect(cancelled.status, BookingStatus.cancelled);
      expect(cancelled.cancellationReason, 'Doctor emergency');
      expect(cancelled.cancelledAt, isNotNull);
      expect(cancelled.isCancelled, isTrue);

      // Attempting to cancel an already-cancelled booking throws
      expect(
        () => repository.updateBookingStatus(
          'bk_cancel_test',
          BookingStatus.cancelled,
        ),
        throwsException,
      );
    });

    test(
      'reschedules booking preserving id, updating times and appending history',
      () async {
        final booking = BookingModel(
          id: 'bk_reschedule_1',
          businessId: 'biz_reschedule',
          serviceId: 'srv_r',
          staffId: 'stf_original',
          customerName: 'Reschedule User',
          customerPhone: '77788899',
          startAt: DateTime(2026, 11, 1, 10, 0),
          endAt: DateTime(2026, 11, 1, 10, 45),
          price: 65.0,
          status: BookingStatus.confirmed,
        );

        await repository.createBooking(booking);

        final newStart = DateTime(2026, 11, 2, 14, 0);
        final newEnd = DateTime(2026, 11, 2, 14, 45);

        final rescheduled = await repository.rescheduleBooking(
          bookingId: 'bk_reschedule_1',
          newStartAt: newStart,
          newEndAt: newEnd,
          newStaffId: 'stf_new',
          newStaffName: 'New Specialist',
          reason: 'Customer requested afternoon slot',
        );

        // Same ID preserved!
        expect(rescheduled.id, 'bk_reschedule_1');
        expect(rescheduled.startAt, newStart);
        expect(rescheduled.endAt, newEnd);
        expect(rescheduled.staffId, 'stf_new');
        expect(rescheduled.staffName, 'New Specialist');
        expect(rescheduled.customerName, 'Reschedule User');
        expect(rescheduled.rescheduleHistory.length, 1);

        final record = rescheduled.rescheduleHistory.first;
        expect(record.previousStartAt, DateTime(2026, 11, 1, 10, 0));
        expect(record.newStartAt, newStart);
        expect(record.reason, 'Customer requested afternoon slot');

        // Check persistence after re-instantiating repo
        final reloadedRepo = BookingRepository(BookingLocalDataSource(storage));
        final reloadedBooking = await reloadedRepo.getBookingById(
          'bk_reschedule_1',
        );
        expect(reloadedBooking, isNotNull);
        expect(reloadedBooking!.startAt, newStart);
        expect(reloadedBooking.rescheduleHistory.length, 1);
      },
    );

    test('cancelled bookings release their original time slot', () {
      final service = ServiceModel(
        id: 'srv_s',
        businessId: 'biz_slots',
        name: 'Service',
        price: 50.0,
        durationMinutes: 30,
        bufferMinutes: 0,
      );

      final staff = StaffModel(
        id: 'stf_a',
        businessId: 'biz_slots',
        name: 'Alice',
        assignedServiceIds: ['srv_s'],
      );

      final sched = <int, DaySchedule>{};
      for (int i = 1; i <= 7; i++) {
        sched[i] = const DaySchedule(
          dayOfWeek: 1,
          isOpen: true,
          openTime: '09:00',
          closeTime: '11:00',
        );
      }
      final avail = BusinessAvailability(
        businessId: 'biz_slots',
        weeklySchedule: sched,
      );

      final targetDate = DateTime(2027, 8, 10);
      final activeBooking = BookingModel(
        id: 'bk_active_slot',
        businessId: 'biz_slots',
        serviceId: 'srv_s',
        staffId: 'stf_a',
        customerName: 'Client',
        customerPhone: '111',
        startAt: DateTime(2027, 8, 10, 9, 0),
        endAt: DateTime(2027, 8, 10, 9, 30),
        price: 50.0,
        status: BookingStatus.confirmed,
      );

      // Slot 09:00 is occupied when booking is confirmed
      final occupiedSlots =
          BookingAvailabilityCalculator.calculateAvailableSlots(
            date: targetDate,
            service: service,
            availability: avail,
            timeOffList: [],
            eligibleStaff: [staff],
            existingBookings: [activeBooking],
            now: DateTime(2027, 8, 1, 8, 0),
          );
      expect(occupiedSlots.any((s) => s.startTimeString == '09:00'), isFalse);

      // Once cancelled, slot 09:00 is freed!
      final cancelledBooking = activeBooking.copyWith(
        status: BookingStatus.cancelled,
      );
      final releasedSlots =
          BookingAvailabilityCalculator.calculateAvailableSlots(
            date: targetDate,
            service: service,
            availability: avail,
            timeOffList: [],
            eligibleStaff: [staff],
            existingBookings: [cancelledBooking],
            now: DateTime(2027, 8, 1, 8, 0),
          );
      expect(releasedSlots.any((s) => s.startTimeString == '09:00'), isTrue);
    });

    test(
      'rescheduling ignores current booking ID so it does not block itself',
      () {
        final service = ServiceModel(
          id: 'srv_self',
          businessId: 'biz_self',
          name: 'Service',
          price: 50.0,
          durationMinutes: 30,
          bufferMinutes: 0,
        );

        final staff = StaffModel(
          id: 'stf_self',
          businessId: 'biz_self',
          name: 'Self Staff',
          assignedServiceIds: ['srv_self'],
        );

        final sched = <int, DaySchedule>{};
        for (int i = 1; i <= 7; i++) {
          sched[i] = const DaySchedule(
            dayOfWeek: 1,
            isOpen: true,
            openTime: '09:00',
            closeTime: '11:00',
          );
        }
        final avail = BusinessAvailability(
          businessId: 'biz_self',
          weeklySchedule: sched,
        );

        final currentBooking = BookingModel(
          id: 'bk_self_conflict',
          businessId: 'biz_self',
          serviceId: 'srv_self',
          staffId: 'stf_self',
          customerName: 'Client Self',
          customerPhone: '111',
          startAt: DateTime(2027, 9, 10, 9, 0),
          endAt: DateTime(2027, 9, 10, 9, 30),
          price: 50.0,
          status: BookingStatus.confirmed,
        );

        // If we ignore bk_self_conflict, 09:00 is available for re-selection (e.g. changing specialist)
        final availableSlots =
            BookingAvailabilityCalculator.calculateAvailableSlots(
              date: DateTime(2027, 9, 10),
              service: service,
              availability: avail,
              timeOffList: [],
              eligibleStaff: [staff],
              existingBookings: [currentBooking],
              ignoreBookingId: 'bk_self_conflict',
              now: DateTime(2027, 9, 1, 8, 0),
            );

        expect(availableSlots.any((s) => s.startTimeString == '09:00'), isTrue);

        final isAvailable = BookingAvailabilityCalculator.isSlotStillAvailable(
          startAt: DateTime(2027, 9, 10, 9, 0),
          endAt: DateTime(2027, 9, 10, 9, 30),
          bufferMinutes: 0,
          staffId: 'stf_self',
          existingBookings: [currentBooking],
          ignoreBookingId: 'bk_self_conflict',
        );
        expect(isAvailable, isTrue);
      },
    );
  });
}
