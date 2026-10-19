import 'package:appointment_pro/features/bookings/data/models/booking_model.dart';
import 'package:appointment_pro/features/bookings/presentation/widgets/booking_calendar_view.dart';
import 'package:appointment_pro/features/bookings/presentation/widgets/booking_date_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingDateSelector Overflow Fix Tests', () {
    testWidgets('renders month text and day without overflow on tight bounds', (
      tester,
    ) async {
      DateTime selected = DateTime(2026, 10, 14);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320, // narrow screen
              child: BookingDateSelector(
                selectedDate: selected,
                onDateSelected: (d) => selected = d,
              ),
            ),
          ),
        ),
      );

      // Verify Oct / month text rendered without exception
      expect(find.byType(BookingDateSelector), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('BookingCalendarView Tests', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 14, 0);

    final sampleBookings = [
      BookingModel(
        id: 'bk_1',
        businessId: 'biz_1',
        serviceId: 'srv_1',
        serviceName: 'General Consultation',
        customerName: 'Mahesh Patel',
        customerPhone: '9085236846',
        startAt: today,
        endAt: today.add(const Duration(minutes: 30)),
        price: 50.0,
        status: BookingStatus.confirmed,
      ),
      BookingModel(
        id: 'bk_2',
        businessId: 'biz_1',
        serviceId: 'srv_2',
        serviceName: 'Dental Checkup',
        customerName: 'Aarav Shah',
        customerPhone: '9876543210',
        startAt: today.add(const Duration(hours: 1)),
        endAt: today.add(const Duration(hours: 1, minutes: 45)),
        price: 80.0,
        status: BookingStatus.confirmed,
      ),
      BookingModel(
        id: 'bk_3',
        businessId: 'biz_1',
        serviceId: 'srv_1',
        serviceName: 'Follow Up',
        customerName: 'Rohan Sharma',
        customerPhone: '9123456780',
        startAt: today.add(const Duration(hours: 2)),
        endAt: today.add(const Duration(hours: 2, minutes: 20)),
        price: 30.0,
        status: BookingStatus.completed,
      ),
      BookingModel(
        id: 'bk_4',
        businessId: 'biz_1',
        serviceId: 'srv_1',
        serviceName: 'Consultation',
        customerName: 'Kiran Desai',
        customerPhone: '9988776655',
        startAt: today.add(const Duration(hours: 3)),
        endAt: today.add(const Duration(hours: 3, minutes: 15)),
        price: 45.0,
        status: BookingStatus.cancelled,
      ),
    ];

    testWidgets('renders month calendar with status counts and day agenda', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BookingCalendarView(bookings: sampleBookings),
            ),
          ),
        ),
      );

      // Verify calendar headers
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Verify legend and chips without Pending
      expect(find.text('Pending'), findsNothing);
      expect(find.text('Confirmed'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Cancelled'), findsWidgets);

      // Today should be selected by default, displaying the 4 appointments
      expect(find.text('4 appointments scheduled'), findsOneWidget);
      expect(find.text('General Consultation'), findsOneWidget);
      expect(find.text('Dental Checkup'), findsOneWidget);
      expect(find.text('Follow Up'), findsOneWidget);
      expect(find.text('Consultation'), findsOneWidget);

      // Tapping on an appointment card opens Google Calendar-style details modal
      final firstAppointment = find.text('General Consultation').first;
      await tester.ensureVisible(firstAppointment);
      await tester.pumpAndSettle();
      await tester.tap(firstAppointment);
      await tester.pumpAndSettle();

      // Verify details modal contains customer name, phone, price and Full Details button
      expect(find.text('ID: bk_1'), findsOneWidget);
      expect(find.text('Mahesh Patel'), findsWidgets);
      expect(find.text('Price: ₹50.00'), findsOneWidget);
      expect(find.text('Full Details'), findsOneWidget);
    });

    testWidgets('tapping empty day displays zero appointments notice', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BookingCalendarView(bookings: const []),
            ),
          ),
        ),
      );

      expect(find.text('No appointments on this day'), findsOneWidget);
    });
  });
}
