import 'package:appointment_pro/features/bookings/data/models/booking_model.dart';
import 'package:appointment_pro/features/bookings/presentation/widgets/booking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'BookingCard displays Mark Completed button for confirmed booking and fires callback',
    (tester) async {
      bool completeCalled = false;

      final booking = BookingModel(
        id: 'bk_card_test',
        businessId: 'biz_1',
        serviceId: 'srv_1',
        customerName: 'Prashant Sarvaiya',
        customerPhone: '9316163578',
        startAt: DateTime(2026, 10, 14, 10, 45),
        endAt: DateTime(2026, 10, 14, 10, 50),
        price: 50.0,
        status: BookingStatus.confirmed,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: booking,
                margin: EdgeInsets.zero,
                onComplete: () {
                  completeCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify customer name, phone, and price
      expect(find.text('Prashant Sarvaiya'), findsOneWidget);
      expect(find.text('+91 9316163578'), findsOneWidget);
      expect(find.text('₹50.00'), findsOneWidget);

      // Verify "Mark Completed" button is visible
      final markCompletedButton = find.text('Mark Completed');
      expect(markCompletedButton, findsOneWidget);

      // Tap "Mark Completed"
      await tester.tap(markCompletedButton);
      await tester.pump();

      expect(completeCalled, isTrue);
    },
  );

  testWidgets(
    'BookingCard renders responsively on compact screen widths without errors',
    (tester) async {
      final booking = BookingModel(
        id: 'bk_compact_test',
        businessId: 'biz_1',
        serviceId: 'srv_1',
        customerName: 'Compact Width User',
        customerPhone: '9876543210',
        startAt: DateTime(2026, 10, 14, 14, 0),
        endAt: DateTime(2026, 10, 14, 14, 30),
        price: 75.0,
        status: BookingStatus.confirmed,
      );

      // Test on a narrow width (e.g. 320px)
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BookingCard(
                booking: booking,
                margin: EdgeInsets.zero,
                onComplete: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Compact Width User'), findsOneWidget);
      expect(find.text('Mark Completed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
