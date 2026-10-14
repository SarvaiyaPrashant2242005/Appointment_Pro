import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/availability/data/models/availability_model.dart';
import 'package:appointment_pro/features/availability/data/repositories/availability_repository.dart';
import 'package:appointment_pro/features/bookings/data/datasources/booking_local_datasource.dart';
import 'package:appointment_pro/features/bookings/data/models/booking_model.dart';
import 'package:appointment_pro/features/bookings/data/repositories/booking_repository.dart';
import 'package:appointment_pro/features/bookings/presentation/screens/public_booking_manage_screen.dart';
import 'package:appointment_pro/features/bussiness_setup/data/models/business_model.dart';
import 'package:appointment_pro/features/bussiness_setup/data/repositories/business_repository.dart';
import 'package:appointment_pro/features/services/data/models/service_model.dart';
import 'package:appointment_pro/features/services/data/repositories/service_repository.dart';
import 'package:appointment_pro/features/staff/data/models/staff_model.dart';
import 'package:appointment_pro/features/staff/data/repositories/staff_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late BusinessModel testBusiness;
  late ServiceModel testService;
  late StaffModel testStaff;
  late BookingModel testBooking;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(prefs);

    testBusiness = BusinessModel(
      id: 'biz_aura',
      name: 'Aura Wellness',
      type: 'Spa & Salon',
      createdAt: DateTime(2026, 1, 1),
    );

    testService = ServiceModel(
      id: 'srv_facial',
      businessId: 'biz_aura',
      name: 'Hydra Facial',
      price: 85.0,
      durationMinutes: 45,
      bufferMinutes: 15,
    );

    testStaff = StaffModel(
      id: 'stf_emma',
      businessId: 'biz_aura',
      name: 'Emma Stone',
      assignedServiceIds: ['srv_facial'],
    );

    testBooking = BookingModel(
      id: 'bk_aura_101',
      businessId: 'biz_aura',
      serviceId: 'srv_facial',
      serviceName: 'Hydra Facial',
      staffId: 'stf_emma',
      staffName: 'Emma Stone',
      customerName: 'Sarah Connor',
      customerCountryCode: '+1',
      customerPhone: '5559876543',
      startAt: DateTime(2027, 4, 15, 14, 0),
      endAt: DateTime(2027, 4, 15, 14, 45),
      price: 85.0,
      status: BookingStatus.confirmed,
    );

    // Seed storage
    final bizRepo = BusinessRepository(storage);
    await bizRepo.createBusiness(testBusiness);

    final srvRepo = ServiceRepository(storage);
    await srvRepo.createService(testService);

    final staffRepo = StaffRepository(storage);
    await staffRepo.createStaff(testStaff);

    final availRepo = AvailabilityRepository(storage);
    await availRepo.saveBusinessAvailability(
      BusinessAvailability.defaultFor('biz_aura'),
    );

    final bookingRepo = BookingRepository(BookingLocalDataSource(storage));
    await bookingRepo.createBooking(testBooking);
  });

  Widget buildTestWidget({String? prefilledId}) {
    return ProviderScope(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      child: MaterialApp(
        home: PublicBookingManageScreen(
          businessSlug: 'aura-wellness',
          prefilledBookingId: prefilledId,
        ),
      ),
    );
  }

  testWidgets('renders search form and prefilled booking ID', (tester) async {
    await tester.pumpWidget(buildTestWidget(prefilledId: 'bk_aura_101'));
    await tester.pumpAndSettle();

    expect(find.text('Find Your Appointment'), findsOneWidget);
    expect(find.text('bk_aura_101'), findsOneWidget);
    expect(find.text('Verify & Manage Appointment'), findsOneWidget);
  });

  testWidgets(
    'shows generic error on mismatched phone without revealing existence',
    (tester) async {
      await tester.pumpWidget(buildTestWidget(prefilledId: 'bk_aura_101'));
      await tester.pumpAndSettle();

      // Enter wrong phone number
      await tester.enterText(find.byType(TextFormField).at(1), '5550000000');
      await tester.tap(find.text('Verify & Manage Appointment'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Booking not found. Please check your booking ID and phone number.',
        ),
        findsOneWidget,
      );
      // Booking details not revealed
      expect(find.text('Sarah Connor'), findsNothing);
    },
  );

  testWidgets(
    'verifies booking with matching phone number and displays details and actions',
    (tester) async {
      await tester.pumpWidget(buildTestWidget(prefilledId: 'bk_aura_101'));
      await tester.pumpAndSettle();

      // Enter matching phone number (can have spaces or clean digits)
      await tester.enterText(find.byType(TextFormField).at(1), '555-987-6543');
      await tester.tap(find.text('Verify & Manage Appointment'));
      await tester.pumpAndSettle();

      // Verification succeeded
      expect(find.text('Appointment Details'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('Hydra Facial'), findsOneWidget);
      expect(find.text('Emma Stone'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);

      // Eligible actions available
      expect(find.text('Reschedule Appointment'), findsOneWidget);
      expect(find.text('Cancel Appointment'), findsOneWidget);
    },
  );

  testWidgets(
    'cancels booking through public manage screen and reflects cancelled state',
    (tester) async {
      await tester.pumpWidget(buildTestWidget(prefilledId: 'bk_aura_101'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), '5559876543');
      await tester.tap(find.text('Verify & Manage Appointment'));
      await tester.pumpAndSettle();

      // Scroll down and tap Cancel Appointment
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      final cancelButtonFinder = find.widgetWithText(
        OutlinedButton,
        'Cancel Appointment',
      );
      await tester.tap(cancelButtonFinder);
      await tester.pumpAndSettle();

      // Dialog appears with reason field
      expect(find.text('Reason for Cancellation (Optional)'), findsOneWidget);

      // Enter optional reason
      await tester.enterText(
        find.widgetWithText(TextField, 'Reason for Cancellation (Optional)'),
        'Vacation travel',
      );

      // Confirm cancellation in dialog
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Cancel Appointment'),
      );
      await tester.pumpAndSettle();

      // Status updated to cancelled
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('This appointment was cancelled'), findsOneWidget);
      expect(find.text('Vacation travel'), findsOneWidget);

      // Reschedule and Cancel buttons are no longer present for cancelled booking
      expect(find.text('Reschedule Appointment'), findsNothing);

      // Let the toast timer expire
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets('prevents accessing a booking belonging to another business', (
    tester,
  ) async {
    // Another business and booking
    final otherBusiness = BusinessModel(
      id: 'biz_other',
      name: 'Other Clinic',
      type: 'Medical',
      createdAt: DateTime(2026, 1, 1),
    );
    final otherBizRepo = BusinessRepository(storage);
    await otherBizRepo.createBusiness(otherBusiness);

    final otherBooking = BookingModel(
      id: 'bk_other_999',
      businessId: 'biz_other',
      serviceId: 'srv_other',
      customerName: 'Foreign Customer',
      customerPhone: '9991112222',
      startAt: DateTime(2027, 4, 15, 14, 0),
      endAt: DateTime(2027, 4, 15, 14, 45),
      price: 50.0,
      status: BookingStatus.confirmed,
    );
    final bookingRepo = BookingRepository(BookingLocalDataSource(storage));
    await bookingRepo.createBooking(otherBooking);

    // Try finding bk_other_999 from aura-wellness manage page
    await tester.pumpWidget(buildTestWidget(prefilledId: 'bk_other_999'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '9991112222');
    await tester.tap(find.text('Verify & Manage Appointment'));
    await tester.pumpAndSettle();

    // Generic error shown, details never revealed
    expect(
      find.text(
        'Booking not found. Please check your booking ID and phone number.',
      ),
      findsOneWidget,
    );
    expect(find.text('Foreign Customer'), findsNothing);
  });
}
