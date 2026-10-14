import 'package:appointment_pro/app/theme/theme_provider.dart';
import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/bookings/data/datasources/booking_local_datasource.dart';
import 'package:appointment_pro/features/bookings/data/models/booking_model.dart';
import 'package:appointment_pro/features/bookings/data/repositories/booking_repository.dart';
import 'package:appointment_pro/features/bussiness_setup/presentation/providers/business_provider.dart';
import 'package:appointment_pro/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:appointment_pro/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:appointment_pro/features/notifications/data/models/app_notification_model.dart';
import 'package:appointment_pro/features/notifications/data/repositories/notification_repository.dart';
import 'package:appointment_pro/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:appointment_pro/features/notifications/presentation/widgets/notification_badge_button.dart';
import 'package:appointment_pro/features/notifications/presentation/widgets/notification_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late NotificationLocalDataSource localDataSource;
  late NotificationRemoteDataSource remoteDataSource;
  late NotificationRepository notificationRepo;

  final testBooking = BookingModel(
    id: 'bk_notif_001',
    businessId: 'biz_aura',
    serviceId: 'srv_haircut',
    serviceName: 'Hair Styling',
    staffId: 'stf_alex',
    staffName: 'Alex Rivera',
    customerName: 'Sarah Connor',
    customerPhone: '5551234567',
    startAt: DateTime(2026, 10, 20, 14, 0),
    endAt: DateTime(2026, 10, 20, 15, 0),
    price: 60.0,
    status: BookingStatus.confirmed,
    createdAt: DateTime(2026, 10, 15, 10, 0),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localDataSource = NotificationLocalDataSource(prefs);
    remoteDataSource = NotificationRemoteDataSource();
    notificationRepo = NotificationRepository(
      local: localDataSource,
      remote: remoteDataSource,
    );
  });

  group('AppNotificationModel & Enum Tests', () {
    test('NotificationType enum serializes and deserializes correctly', () {
      expect(NotificationType.newBooking.value, 'new_booking');
      expect(NotificationType.bookingCancelled.value, 'booking_cancelled');
      expect(NotificationType.bookingRescheduled.value, 'booking_rescheduled');

      expect(NotificationType.fromString('new_booking'), NotificationType.newBooking);
      expect(NotificationType.fromString('booking_cancelled'), NotificationType.bookingCancelled);
      expect(NotificationType.fromString('booking_rescheduled'), NotificationType.bookingRescheduled);
      expect(NotificationType.fromString('unknown_val'), NotificationType.newBooking);
    });

    test('AppNotificationModel round-trip toMap and fromMap works seamlessly', () {
      final now = DateTime(2026, 10, 15, 12, 30);
      final model = AppNotificationModel(
        id: 'notif_123',
        businessId: 'biz_aura',
        bookingId: 'bk_notif_001',
        type: NotificationType.newBooking,
        title: 'New Booking',
        body: 'Sarah booked Haircut',
        customerName: 'Sarah Connor',
        serviceName: 'Haircut',
        startAt: DateTime(2026, 10, 20, 14, 0),
        endAt: DateTime(2026, 10, 20, 15, 0),
        cancellationReason: null,
        createdAt: now,
        isRead: false,
        metadata: {'platform': 'web'},
      );

      final map = model.toMap();
      final reconstituted = AppNotificationModel.fromMap(map);

      expect(reconstituted.id, 'notif_123');
      expect(reconstituted.businessId, 'biz_aura');
      expect(reconstituted.bookingId, 'bk_notif_001');
      expect(reconstituted.type, NotificationType.newBooking);
      expect(reconstituted.customerName, 'Sarah Connor');
      expect(reconstituted.serviceName, 'Haircut');
      expect(reconstituted.isRead, false);
      expect(reconstituted.metadata['platform'], 'web');
    });
  });

  group('Customer-Initiated Events vs Owner-Initiated Exclusions', () {
    test('Rule 1: New booking through public portal DISPATCHES notification', () async {
      final notif = await notificationRepo.dispatchCustomerNotification(
        type: NotificationType.newBooking,
        booking: testBooking,
      );

      expect(notif.type, NotificationType.newBooking);
      expect(notif.title, contains('New Booking Received'));
      expect(notif.body, contains('Sarah Connor'));
      expect(notif.isRead, false);

      final list = await notificationRepo.getNotifications('biz_aura');
      expect(list.length, 1);
      expect(list.first.bookingId, 'bk_notif_001');
    });

    test('Rule 2: Booking cancelled through public management DISPATCHES notification', () async {
      final notif = await notificationRepo.dispatchCustomerNotification(
        type: NotificationType.bookingCancelled,
        booking: testBooking,
        cancellationReason: 'Emergency conflict',
      );

      expect(notif.type, NotificationType.bookingCancelled);
      expect(notif.title, contains('Booking Cancelled'));
      expect(notif.cancellationReason, 'Emergency conflict');
      expect(notif.body, contains('Emergency conflict'));

      final list = await notificationRepo.getNotifications('biz_aura');
      expect(list.length, 1);
      expect(list.first.cancellationReason, 'Emergency conflict');
    });

    test('Rule 3: Booking rescheduled through public management DISPATCHES notification', () async {
      final oldTime = DateTime(2026, 10, 20, 14, 0);
      final rescheduledBooking = testBooking.copyWith(
        startAt: DateTime(2026, 10, 22, 16, 0),
        endAt: DateTime(2026, 10, 22, 17, 0),
      );

      final notif = await notificationRepo.dispatchCustomerNotification(
        type: NotificationType.bookingRescheduled,
        booking: rescheduledBooking,
        oldStartAt: oldTime,
      );

      expect(notif.type, NotificationType.bookingRescheduled);
      expect(notif.title, contains('Booking Rescheduled'));
      expect(notif.body, contains('Sarah Connor'));

      final list = await notificationRepo.getNotifications('biz_aura');
      expect(list.length, 1);
      expect(list.first.type, NotificationType.bookingRescheduled);
    });

    test('Exclusion Rule: Owner walk-in booking creation does NOT dispatch notification', () async {
      final bookingLocal = BookingLocalDataSource(LocalStorageService(prefs));
      final bookingRepo = BookingRepository(bookingLocal);

      // Owner creates a walk-in booking inside the app
      await bookingRepo.createBooking(testBooking);

      // Verify NO notification was generated for this business
      final notifications = await notificationRepo.getNotifications('biz_aura');
      expect(notifications.isEmpty, true,
          reason: 'Owner walk-in bookings must never generate notifications');
    });

    test('Exclusion Rule: Owner cancelling booking inside the app does NOT dispatch notification', () async {
      final bookingLocal = BookingLocalDataSource(LocalStorageService(prefs));
      final bookingRepo = BookingRepository(bookingLocal);

      await bookingRepo.createBooking(testBooking);
      // Owner cancels inside the app
      await bookingRepo.updateBookingStatus(
        testBooking.id,
        BookingStatus.cancelled,
        cancellationReason: 'Owner had staff shortage',
      );

      final notifications = await notificationRepo.getNotifications('biz_aura');
      expect(notifications.isEmpty, true,
          reason: 'Owner-initiated cancellations must never generate customer notifications');
    });

    test('Exclusion Rule: Owner rescheduling booking inside the app does NOT dispatch notification', () async {
      final bookingLocal = BookingLocalDataSource(LocalStorageService(prefs));
      final bookingRepo = BookingRepository(bookingLocal);

      await bookingRepo.createBooking(testBooking);
      // Owner reschedules inside the app
      await bookingRepo.rescheduleBooking(
        bookingId: testBooking.id,
        newStartAt: DateTime(2026, 10, 25, 10, 0),
        newEndAt: DateTime(2026, 10, 25, 11, 0),
        reason: 'Staff reallocated',
      );

      final notifications = await notificationRepo.getNotifications('biz_aura');
      expect(notifications.isEmpty, true,
          reason: 'Owner-initiated reschedules must never generate customer notifications');
    });
  });

  group('Notification State & Management Tests', () {
    test('Unread count and mark as read functionality', () async {
      await notificationRepo.dispatchCustomerNotification(
        type: NotificationType.newBooking,
        booking: testBooking,
      );
      await notificationRepo.dispatchCustomerNotification(
        type: NotificationType.bookingRescheduled,
        booking: testBooking.copyWith(id: 'bk_2'),
      );

      var unreadCount = await notificationRepo.getUnreadCount('biz_aura');
      expect(unreadCount, 2);

      final list = await notificationRepo.getNotifications('biz_aura');
      await notificationRepo.markAsRead('biz_aura', list.first.id);

      unreadCount = await notificationRepo.getUnreadCount('biz_aura');
      expect(unreadCount, 1);

      await notificationRepo.markAllAsRead('biz_aura');
      unreadCount = await notificationRepo.getUnreadCount('biz_aura');
      expect(unreadCount, 0);
    });

    test('Clear all removes notifications for business', () async {
      await notificationRepo.dispatchCustomerNotification(
        type: NotificationType.newBooking,
        booking: testBooking,
      );

      await notificationRepo.clearAll('biz_aura');
      final list = await notificationRepo.getNotifications('biz_aura');
      expect(list.isEmpty, true);
    });
  });

  group('Notification Widgets & UI Tests', () {
    testWidgets('NotificationItemTile renders details and status icon', (tester) async {
      final notif = AppNotificationModel(
        id: 'n_1',
        businessId: 'biz_aura',
        bookingId: 'bk_1',
        type: NotificationType.newBooking,
        title: 'New Booking',
        body: 'Alex booked Massage',
        customerName: 'Alex',
        serviceName: 'Massage',
        createdAt: DateTime.now(),
        isRead: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationItemTile(notification: notif),
          ),
        ),
      );

      expect(find.text('New Booking'), findsOneWidget);
      expect(find.text('Alex booked Massage'), findsOneWidget);
      expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);
    });

    testWidgets('NotificationBadgeButton displays badge counter when unread > 0', (tester) async {
      await notificationRepo.dispatchCustomerNotification(
        type: NotificationType.newBooking,
        booking: testBooking,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeBusinessIdProvider.overrideWithValue('biz_aura'),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: NotificationBadgeButton(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NotificationBadgeButton), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('NotificationCenterScreen renders notifications list and filter tabs', (tester) async {
      await notificationRepo.dispatchCustomerNotification(
        type: NotificationType.newBooking,
        booking: testBooking,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeBusinessIdProvider.overrideWithValue('biz_aura'),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.byType(NotificationItemTile), findsOneWidget);
    });
  });
}
