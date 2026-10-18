import 'package:appointment_pro/core/services/websocket_service.dart';
import 'package:appointment_pro/features/bookings/data/models/booking_model.dart';
import 'package:appointment_pro/features/bookings/presentation/providers/booking_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebSocketEvent parsing & handling', () {
    test('parses standard live booking event payload', () {
      final json = {
        'event': 'booking:created',
        'businessId': 'biz-123',
        'data': {
          'bookingId': 'bk-001',
          'bookingReference': 'AP-849201',
          'status': 'confirmed',
          'booking': {
            'id': 'bk-001',
            'businessId': 'biz-123',
            'serviceId': 'srv-1',
            'serviceName': 'Health Checkup',
            'customerName': 'Rajesh Sharma',
            'customerPhone': '+91 9876543210',
            'startAt': '2026-10-18T10:00:00.000Z',
            'endAt': '2026-10-18T10:30:00.000Z',
            'price': 100.0,
            'status': 'confirmed',
            'bookingReference': 'AP-849201',
          },
        },
        'timestamp': '2026-10-18T17:00:00.000Z',
      };

      final event = WebSocketEvent.fromJson(json);
      expect(event.event, equals('booking:created'));
      expect(event.businessId, equals('biz-123'));
      expect(event.data['bookingReference'], equals('AP-849201'));
      expect(event.bookingJson, isNotNull);
      expect(event.bookingJson?['customerName'], equals('Rajesh Sharma'));
    });

    test('parses ping/pong and system messages gracefully', () {
      final pong = WebSocketEvent.fromJson({'type': 'pong'});
      expect(pong.event, equals('pong'));

      final joined = WebSocketEvent.fromJson({
        'event': 'business:joined',
        'businessId': 'biz-999',
      });
      expect(joined.event, equals('business:joined'));
      expect(joined.businessId, equals('biz-999'));
    });
  });

  group('BookingsController Live WebSocket synchronization', () {
    final now = DateTime(2026, 10, 18, 10, 0);

    final initialBooking = BookingModel(
      id: 'bk-1',
      businessId: 'biz-test',
      serviceId: 'srv-1',
      serviceName: 'Consultation',
      customerName: 'Aarav Patel',
      customerPhone: '9876543210',
      startAt: now,
      endAt: now.add(const Duration(minutes: 30)),
      price: 500,
      status: BookingStatus.confirmed,
      bookingReference: 'AP-100001',
    );

    test('onLiveBookingCreated adds booking to list in chronological order', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Await initial build completion
      await container.read(bookingsProvider.future);
      final controller = container.read(bookingsProvider.notifier);
      // Prime initial state
      controller.state = AsyncData([initialBooking]);

      final newBooking = BookingModel(
        id: 'bk-2',
        businessId: 'biz-test',
        serviceId: 'srv-2',
        serviceName: 'Dental Scaling',
        customerName: 'Pooja Mehta',
        customerPhone: '9123456789',
        startAt: now.add(const Duration(hours: 1)),
        endAt: now.add(const Duration(hours: 1, minutes: 45)),
        price: 800,
        status: BookingStatus.confirmed,
        bookingReference: 'AP-100002',
      );

      await controller.onLiveBookingCreated(newBooking);

      final state = container.read(bookingsProvider).asData?.value;
      expect(state, isNotNull);
      expect(state!.length, equals(2));
      expect(state[0].id, equals('bk-1'));
      expect(state[1].id, equals('bk-2'));
      expect(state[1].displayId, equals('AP-100002'));
    });

    test('onLiveBookingCreated replaces existing booking if same ID arrives', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Await initial build completion
      await container.read(bookingsProvider.future);
      final controller = container.read(bookingsProvider.notifier);
      controller.state = AsyncData([initialBooking]);

      final updatedInitial = initialBooking.copyWith(
        customerName: 'Aarav Patel (VIP)',
        price: 550,
      );

      await controller.onLiveBookingCreated(updatedInitial);

      final state = container.read(bookingsProvider).asData?.value;
      expect(state, isNotNull);
      expect(state!.length, equals(1));
      expect(state[0].customerName, equals('Aarav Patel (VIP)'));
      expect(state[0].price, equals(550));
    });

    test('onLiveBookingUpdated updates existing booking in place', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(bookingsProvider.notifier);
      controller.state = AsyncData([initialBooking]);

      final updatedBooking = initialBooking.copyWith(
        status: BookingStatus.completed,
      );

      controller.onLiveBookingUpdated(updatedBooking);

      final state = container.read(bookingsProvider).asData?.value;
      expect(state, isNotNull);
      expect(state!.length, equals(1));
      expect(state[0].status, equals(BookingStatus.completed));
    });

    test('onLiveBookingCancelled updates booking to cancelled status and retains reason', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(bookingsProvider.notifier);
      controller.state = AsyncData([initialBooking]);

      controller.onLiveBookingCancelled('bk-1', reason: 'Customer requested cancellation via portal');

      final state = container.read(bookingsProvider).asData?.value;
      expect(state, isNotNull);
      expect(state!.length, equals(1));
      expect(state[0].status, equals(BookingStatus.cancelled));
      expect(state[0].cancellationReason, equals('Customer requested cancellation via portal'));
    });

    test('onLiveBookingDeleted removes booking from state list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(bookingsProvider.notifier);
      controller.state = AsyncData([initialBooking]);

      controller.onLiveBookingDeleted('bk-1');

      final state = container.read(bookingsProvider).asData?.value;
      expect(state, isNotNull);
      expect(state!.isEmpty, isTrue);
    });
  });
}
