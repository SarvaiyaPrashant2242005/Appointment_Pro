import 'package:intl/intl.dart';

import '../../../bookings/data/models/booking_model.dart';
import '../datasources/notification_local_datasource.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/app_notification_model.dart';

class NotificationRepository {
  final NotificationLocalDataSource _local;
  final NotificationRemoteDataSource _remote;

  NotificationRepository({
    required NotificationLocalDataSource local,
    required NotificationRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  Future<List<AppNotificationModel>> getNotifications(String businessId) async {
    final localList = await _local.getNotifications(businessId);

    // Try fetching remote notifications and merge any new ones
    try {
      final remoteList = await _remote.getNotifications(businessId);
      if (remoteList.isNotEmpty) {
        final existingIds = localList.map((n) => n.id).toSet();
        for (final r in remoteList) {
          if (!existingIds.contains(r.id)) {
            await _local.saveNotification(r);
            localList.add(r);
          }
        }
        localList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (_) {}

    return localList;
  }

  Future<int> getUnreadCount(String businessId) async {
    final list = await _local.getNotifications(businessId);
    return list.where((n) => !n.isRead).length;
  }

  /// Dispatches a notification for CUSTOMER-initiated actions:
  /// 1. New booking created through public booking page
  /// 2. Booking cancelled through public booking manage page
  /// 3. Booking rescheduled through public booking manage page
  Future<AppNotificationModel> dispatchCustomerNotification({
    required NotificationType type,
    required BookingModel booking,
    String? cancellationReason,
    DateTime? oldStartAt,
  }) async {
    final String title;
    final String body;
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');

    switch (type) {
      case NotificationType.newBooking:
        title = '🎉 New Booking Received';
        body =
            '${booking.customerName} booked ${booking.serviceName ?? 'Service'} for ${dateFormat.format(booking.startAt)}.';
        break;

      case NotificationType.bookingCancelled:
        title = '❌ Booking Cancelled by Customer';
        final reasonSuffix = cancellationReason != null && cancellationReason.isNotEmpty
            ? ' Reason: "$cancellationReason"'
            : '';
        body =
            '${booking.customerName} cancelled their appointment for ${booking.serviceName ?? 'Service'}.$reasonSuffix';
        break;

      case NotificationType.bookingRescheduled:
        title = '🗓️ Booking Rescheduled by Customer';
        final oldTimeStr = oldStartAt != null ? ' (previously ${dateFormat.format(oldStartAt)})' : '';
        body =
            '${booking.customerName} rescheduled ${booking.serviceName ?? 'Service'} to ${dateFormat.format(booking.startAt)}$oldTimeStr.';
        break;
    }

    final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}_${booking.id}';
    final notification = AppNotificationModel(
      id: notifId,
      businessId: booking.businessId,
      bookingId: booking.id,
      type: type,
      title: title,
      body: body,
      customerName: booking.customerName,
      serviceName: booking.serviceName ?? 'Service',
      startAt: booking.startAt,
      endAt: booking.endAt,
      cancellationReason: cancellationReason,
      createdAt: DateTime.now(),
      isRead: false,
      metadata: {
        'source': 'customer_public_portal',
        'customerPhone': booking.customerPhone,
        if (oldStartAt != null) 'oldStartAt': oldStartAt.toIso8601String(),
        if (cancellationReason != null) 'cancellationReason': cancellationReason,
      },
    );

    // Save locally
    await _local.saveNotification(notification);

    // Sync to Firestore & trigger FCM
    await _remote.saveNotification(notification);

    return notification;
  }

  Future<void> markAsRead(String businessId, String notificationId) async {
    await _local.markAsRead(businessId, notificationId);
    await _remote.markAsRead(businessId, notificationId);
  }

  Future<void> markAllAsRead(String businessId) async {
    await _local.markAllAsRead(businessId);
    await _remote.markAllAsRead(businessId);
  }

  Future<void> deleteNotification(String businessId, String notificationId) async {
    await _local.deleteNotification(businessId, notificationId);
    await _remote.deleteNotification(businessId, notificationId);
  }

  Future<void> clearAll(String businessId) async {
    await _local.clearAll(businessId);
  }
}
