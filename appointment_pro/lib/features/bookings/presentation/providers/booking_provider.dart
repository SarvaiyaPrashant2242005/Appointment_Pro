import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../../notifications/data/models/app_notification_model.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../data/datasources/booking_local_datasource.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';

/// Provider for BookingLocalDataSource
final bookingLocalDataSourceProvider = Provider<BookingLocalDataSource>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return BookingLocalDataSource(storage);
});

/// Provider for BookingRepository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dataSource = ref.watch(bookingLocalDataSourceProvider);
  return BookingRepository(apiClient, dataSource);
});

/// Main controller managing owner bookings for the active business
final bookingsProvider =
    AsyncNotifierProvider<BookingsController, List<BookingModel>>(
      BookingsController.new,
    );

class BookingsController extends AsyncNotifier<List<BookingModel>> {
  late BookingRepository _repository;

  @override
  Future<List<BookingModel>> build() async {
    _repository = ref.watch(bookingRepositoryProvider);
    final businessId = ref.watch(activeBusinessIdProvider);

    if (businessId == null || businessId.isEmpty) {
      return [];
    }

    final bookings = await _repository.getBookings(businessId);

    try {
      final serviceRepo = ref.read(serviceRepositoryProvider);
      final staffRepo = ref.read(staffRepositoryProvider);
      final services = await serviceRepo.getServices(businessId);
      final staffList = await staffRepo.getStaff(businessId);

      final serviceMap = {for (final s in services) s.id: s.name};
      final staffMap = {for (final st in staffList) st.id: st.name};

      return bookings.map((b) {
        final resolvedService =
            (b.serviceName != null && b.serviceName!.isNotEmpty)
            ? b.serviceName
            : serviceMap[b.serviceId];
        final resolvedStaff = (b.staffName != null && b.staffName!.isNotEmpty)
            ? b.staffName
            : (b.staffId != null ? staffMap[b.staffId] : null);

        if (resolvedService != b.serviceName || resolvedStaff != b.staffName) {
          return b.copyWith(
            serviceName: resolvedService,
            staffName: resolvedStaff,
          );
        }
        return b;
      }).toList();
    } catch (_) {
      return bookings;
    }
  }

  /// Create a new booking (scoped to active business or provided booking's business)
  Future<BookingModel> createBooking(BookingModel booking) async {
    final businessId = ref.read(activeBusinessIdProvider) ?? booking.businessId;
    final scopedBooking = booking.copyWith(businessId: businessId);
    final previous = state.asData?.value ?? [];

    try {
      final created = await _repository.createBooking(scopedBooking);
      state = AsyncData(
        [...previous, created]..sort((a, b) => a.startAt.compareTo(b.startAt)),
      );
      return created;
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Confirm a pending booking
  Future<void> confirmBooking(String id) async {
    final previous = state.asData?.value ?? [];
    try {
      final updated = await _repository.updateBookingStatus(
        id,
        BookingStatus.confirmed,
      );
      state = AsyncData(previous.map((b) => b.id == id ? updated : b).toList());
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String id, {String? reason}) async {
    final previous = state.asData?.value ?? [];
    try {
      final updated = await _repository.updateBookingStatus(
        id,
        BookingStatus.cancelled,
        cancellationReason: reason,
      );
      state = AsyncData(previous.map((b) => b.id == id ? updated : b).toList());
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Reschedule an existing booking
  Future<BookingModel> rescheduleBooking({
    required String bookingId,
    required DateTime newStartAt,
    required DateTime newEndAt,
    String? newStaffId,
    String? newStaffName,
    String? reason,
  }) async {
    final previous = state.asData?.value ?? [];
    try {
      final updated = await _repository.rescheduleBooking(
        bookingId: bookingId,
        newStartAt: newStartAt,
        newEndAt: newEndAt,
        newStaffId: newStaffId,
        newStaffName: newStaffName,
        reason: reason,
      );
      final updatedList =
          previous.map((b) => b.id == bookingId ? updated : b).toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
      state = AsyncData(updatedList);
      return updated;
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Mark booking as completed
  Future<void> completeBooking(String id) async {
    final previous = state.asData?.value ?? [];
    try {
      final updated = await _repository.updateBookingStatus(
        id,
        BookingStatus.completed,
      );
      state = AsyncData(previous.map((b) => b.id == id ? updated : b).toList());
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Mark booking as no-show
  Future<void> markNoShow(String id) async {
    final previous = state.asData?.value ?? [];
    try {
      final updated = await _repository.updateBookingStatus(
        id,
        BookingStatus.noShow,
      );
      state = AsyncData(previous.map((b) => b.id == id ? updated : b).toList());
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Refresh bookings
  Future<void> refresh() async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getBookings(businessId));
  }

  /// Real-time live WebSocket handler: new booking created
  Future<void> onLiveBookingCreated(BookingModel booking) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId != null &&
        booking.businessId.isNotEmpty &&
        booking.businessId != businessId) {
      return;
    }

    final previous = state.asData?.value ?? [];

    // Resolve service name and staff name if missing
    String? resolvedService = booking.serviceName;
    String? resolvedStaff = booking.staffName;

    try {
      if (resolvedService == null || resolvedService.isEmpty) {
        final serviceRepo = ref.read(serviceRepositoryProvider);
        final services = await serviceRepo.getServices(
          businessId ?? booking.businessId,
        );
        resolvedService = services
            .where((s) => s.id == booking.serviceId)
            .firstOrNull
            ?.name;
      }
      if (resolvedStaff == null || resolvedStaff.isEmpty) {
        if (booking.staffId != null) {
          final staffRepo = ref.read(staffRepositoryProvider);
          final staffList = await staffRepo.getStaff(
            businessId ?? booking.businessId,
          );
          resolvedStaff = staffList
              .where((st) => st.id == booking.staffId)
              .firstOrNull
              ?.name;
        }
      }
    } catch (_) {}

    final enrichedBooking = booking.copyWith(
      serviceName: resolvedService,
      staffName: resolvedStaff,
    );

    // If already exists, replace it, else add it
    final existsIndex = previous.indexWhere(
      (b) =>
          b.id == enrichedBooking.id ||
          (enrichedBooking.bookingReference != null &&
              b.bookingReference == enrichedBooking.bookingReference),
    );

    final List<BookingModel> updatedList;
    if (existsIndex >= 0) {
      updatedList = List.of(previous)..[existsIndex] = enrichedBooking;
    } else {
      updatedList = [...previous, enrichedBooking];
    }

    updatedList.sort((a, b) => a.startAt.compareTo(b.startAt));
    state = AsyncData(updatedList);
  }

  /// Real-time live WebSocket handler: booking updated or rescheduled
  void onLiveBookingUpdated(BookingModel booking) {
    final previous = state.asData?.value ?? [];
    final existsIndex = previous.indexWhere(
      (b) =>
          b.id == booking.id ||
          (booking.bookingReference != null &&
              b.bookingReference == booking.bookingReference),
    );

    if (existsIndex >= 0) {
      final old = previous[existsIndex];
      final updated = booking.copyWith(
        serviceName: booking.serviceName ?? old.serviceName,
        staffName: booking.staffName ?? old.staffName,
      );
      final updatedList = List.of(previous)..[existsIndex] = updated;
      updatedList.sort((a, b) => a.startAt.compareTo(b.startAt));
      state = AsyncData(updatedList);
    } else {
      final updatedList = [...previous, booking]
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      state = AsyncData(updatedList);
    }
  }

  /// Real-time live WebSocket handler: booking cancelled
  void onLiveBookingCancelled(String bookingId, {String? reason}) {
    final previous = state.asData?.value ?? [];
    final updatedList = previous.map((b) {
      if (b.id == bookingId || b.bookingReference == bookingId) {
        return b.copyWith(
          status: BookingStatus.cancelled,
          cancellationReason: reason ?? b.cancellationReason,
          cancelledAt: DateTime.now(),
        );
      }
      return b;
    }).toList();
    state = AsyncData(updatedList);
  }

  /// Real-time live WebSocket handler: booking deleted
  void onLiveBookingDeleted(String bookingId) {
    final previous = state.asData?.value ?? [];
    final updatedList = previous
        .where((b) => b.id != bookingId && b.bookingReference != bookingId)
        .toList();
    state = AsyncData(updatedList);
  }
}

/// Filter tab for booking list
enum BookingListTab { today, upcoming, past }

final bookingTabProvider = NotifierProvider<BookingTabNotifier, BookingListTab>(
  BookingTabNotifier.new,
);

class BookingTabNotifier extends Notifier<BookingListTab> {
  @override
  BookingListTab build() => BookingListTab.today;

  void selectTab(BookingListTab tab) => state = tab;
}

/// Search filter query for owner booking list
final bookingSearchQueryProvider =
    NotifierProvider<BookingSearchNotifier, String>(BookingSearchNotifier.new);

class BookingSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
}

/// Status filter for owner booking list (null means all)
final bookingStatusFilterProvider =
    NotifierProvider<BookingStatusFilterNotifier, BookingStatus?>(
      BookingStatusFilterNotifier.new,
    );

class BookingStatusFilterNotifier extends Notifier<BookingStatus?> {
  @override
  BookingStatus? build() => null;

  void setFilter(BookingStatus? status) => state = status;
}

/// Filtered bookings based on tab, status filter, and search query
final filteredBookingsProvider = Provider<List<BookingModel>>((ref) {
  final allBookings = ref.watch(bookingsProvider).value ?? [];
  final activeTab = ref.watch(bookingTabProvider);
  final statusFilter = ref.watch(bookingStatusFilterProvider);
  final query = ref.watch(bookingSearchQueryProvider).trim().toLowerCase();

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return allBookings.where((booking) {
    // 1. Tab filter
    switch (activeTab) {
      case BookingListTab.today:
        if (booking.startAt.isBefore(startOfToday) ||
            booking.startAt.isAfter(endOfToday)) {
          return false;
        }
        break;
      case BookingListTab.upcoming:
        if (booking.startAt.isBefore(endOfToday)) {
          return false;
        }
        break;
      case BookingListTab.past:
        if (booking.startAt.isAfter(startOfToday)) {
          return false;
        }
        break;
    }

    // 2. Status filter
    if (statusFilter != null && booking.status != statusFilter) {
      return false;
    }

    // 3. Search query filter (customer name, phone, or service ID)
    if (query.isNotEmpty) {
      final nameMatches = booking.customerName.toLowerCase().contains(query);
      final phoneMatches = booking.customerPhone.contains(query);
      final notesMatches = (booking.customerNotes ?? '').toLowerCase().contains(
        query,
      );
      if (!nameMatches && !phoneMatches && !notesMatches) {
        return false;
      }
    }

    return true;
  }).toList();
});

/// Bookings for today (used on dashboard and quick stats)
final todayBookingsProvider = Provider<List<BookingModel>>((ref) {
  final all = ref.watch(bookingsProvider).value ?? [];
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return all
      .where(
        (b) =>
            !b.startAt.isBefore(startOfToday) && !b.startAt.isAfter(endOfToday),
      )
      .toList();
});

/// Single booking lookup provider by ID
final bookingByIdProvider = Provider.family<BookingModel?, String>((ref, id) {
  final all = ref.watch(bookingsProvider).value ?? [];
  return all.where((b) => b.id == id).firstOrNull;
});

/// Live WebSocket booking alert model for in-app floating notifications
class LiveBookingAlert {
  final String title;
  final String message;
  final BookingModel booking;
  final String eventType;
  final DateTime timestamp;

  const LiveBookingAlert({
    required this.title,
    required this.message,
    required this.booking,
    required this.eventType,
    required this.timestamp,
  });
}

/// StateProvider holding the latest live booking alert to display in UI
final latestLiveBookingAlertProvider = StateProvider<LiveBookingAlert?>(
  (ref) => null,
);

/// Provider that syncs live WebSocket events with BookingsController
final bookingWebSocketSyncProvider = Provider<void>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  final activeBusinessId = ref.watch(activeBusinessIdProvider);

  if (activeBusinessId != null && activeBusinessId.isNotEmpty) {
    wsService.connect(businessId: activeBusinessId);
  }

  // Listen to incoming WebSocket events
  final subscription = wsService.eventStream.listen((eventMap) {
    final event = eventMap['event']?.toString() ?? '';
    final businessId = eventMap['businessId']?.toString();
    final data = eventMap['data'];

    // Only process events for current active business
    if (businessId != null &&
        activeBusinessId != null &&
        businessId != activeBusinessId) {
      return;
    }

    if (data is! Map<String, dynamic>) return;

    final bookingJson = data['booking'];
    if (bookingJson is! Map<String, dynamic>) {
      if (event == 'booking:deleted') {
        final deletedId =
            data['deletedId']?.toString() ?? data['bookingId']?.toString();
        if (deletedId != null) {
          ref.read(bookingsProvider.notifier).onLiveBookingDeleted(deletedId);
        }
      }
      return;
    }

    try {
      final booking = BookingModel.fromJson(bookingJson);

      final dateFormat = DateFormat('EEE, MMM d · h:mm a');

      switch (event) {
        case 'booking:created':
          ref.read(bookingsProvider.notifier).onLiveBookingCreated(booking);

          final dateStr = dateFormat.format(booking.startAt);
          final notifTitle = '🎉 New Appointment Booked!';
          final notifBody =
              '${booking.customerName} booked ${booking.serviceName ?? "an appointment"} for $dateStr. Ref: ${booking.displayId}';

          // 1. Show real device OS system notification (heads-up banner, sound, vibration)
          LocalNotificationService.instance.showBookingNotification(
            bookingId: booking.id,
            title: notifTitle,
            body: notifBody,
            payload: booking.id,
          );

          // 2. Persist to in-app Notifications center & update badge counter
          final appNotif = AppNotificationModel(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${booking.id}',
            businessId: booking.businessId,
            bookingId: booking.id,
            type: NotificationType.newBooking,
            title: notifTitle,
            body: notifBody,
            customerName: booking.customerName,
            serviceName: booking.serviceName ?? 'Service',
            startAt: booking.startAt,
            endAt: booking.endAt,
            createdAt: DateTime.now(),
            isRead: false,
            metadata: {
              'displayId': booking.displayId,
              'source': 'live_websocket',
            },
          );
          ref.read(notificationsProvider.notifier).onNotificationReceived(appNotif);

          ref.read(latestLiveBookingAlertProvider.notifier).state = LiveBookingAlert(
            title: notifTitle,
            message: notifBody,
            booking: booking,
            eventType: event,
            timestamp: DateTime.now(),
          );
          break;

        case 'booking:rescheduled':
          ref.read(bookingsProvider.notifier).onLiveBookingUpdated(booking);

          final dateStr = dateFormat.format(booking.startAt);
          final notifTitle = '🗓️ Appointment Rescheduled';
          final notifBody =
              '${booking.customerName} rescheduled ${booking.serviceName ?? "appointment"} to $dateStr. Ref: ${booking.displayId}';

          // 1. Show real device OS system notification
          LocalNotificationService.instance.showBookingNotification(
            bookingId: booking.id,
            title: notifTitle,
            body: notifBody,
            payload: booking.id,
          );

          // 2. Persist to in-app Notifications center & update badge counter
          final appNotifRescheduled = AppNotificationModel(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${booking.id}',
            businessId: booking.businessId,
            bookingId: booking.id,
            type: NotificationType.bookingRescheduled,
            title: notifTitle,
            body: notifBody,
            customerName: booking.customerName,
            serviceName: booking.serviceName ?? 'Service',
            startAt: booking.startAt,
            endAt: booking.endAt,
            createdAt: DateTime.now(),
            isRead: false,
            metadata: {
              'displayId': booking.displayId,
              'source': 'live_websocket',
            },
          );
          ref
              .read(notificationsProvider.notifier)
              .onNotificationReceived(appNotifRescheduled);

          ref.read(latestLiveBookingAlertProvider.notifier).state = LiveBookingAlert(
            title: notifTitle,
            message: notifBody,
            booking: booking,
            eventType: event,
            timestamp: DateTime.now(),
          );
          break;

        case 'booking:updated':
          ref.read(bookingsProvider.notifier).onLiveBookingUpdated(booking);
          break;

        case 'booking:cancelled':
          ref.read(bookingsProvider.notifier).onLiveBookingCancelled(
                booking.id,
                reason: booking.cancellationReason,
              );

          final reasonSuffix = booking.cancellationReason != null &&
                  booking.cancellationReason!.isNotEmpty
              ? ' Reason: "${booking.cancellationReason}"'
              : '';
          final notifTitle = '❌ Appointment Cancelled';
          final notifBody =
              '${booking.customerName} cancelled their appointment for ${booking.serviceName ?? "Service"} (Ref: ${booking.displayId}).$reasonSuffix';

          // 1. Show real device OS system notification
          LocalNotificationService.instance.showBookingNotification(
            bookingId: booking.id,
            title: notifTitle,
            body: notifBody,
            payload: booking.id,
          );

          // 2. Persist to in-app Notifications center & update badge counter
          final appNotifCancelled = AppNotificationModel(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${booking.id}',
            businessId: booking.businessId,
            bookingId: booking.id,
            type: NotificationType.bookingCancelled,
            title: notifTitle,
            body: notifBody,
            customerName: booking.customerName,
            serviceName: booking.serviceName ?? 'Service',
            startAt: booking.startAt,
            endAt: booking.endAt,
            cancellationReason: booking.cancellationReason,
            createdAt: DateTime.now(),
            isRead: false,
            metadata: {
              'displayId': booking.displayId,
              'source': 'live_websocket',
            },
          );
          ref
              .read(notificationsProvider.notifier)
              .onNotificationReceived(appNotifCancelled);

          ref.read(latestLiveBookingAlertProvider.notifier).state = LiveBookingAlert(
            title: notifTitle,
            message: notifBody,
            booking: booking,
            eventType: event,
            timestamp: DateTime.now(),
          );
          break;

        case 'booking:deleted':
          ref.read(bookingsProvider.notifier).onLiveBookingDeleted(booking.id);
          break;
      }
    } catch (e) {
      debugPrint('[WebSocketSync] Error handling booking event: $e');
    }
  });

  // Active live-sync polling (every 7 seconds)
  // Ensures new public bookings appear instantly without needing to close and reopen the app
  Timer? pollTimer;
  if (activeBusinessId != null && activeBusinessId.isNotEmpty) {
    pollTimer = Timer.periodic(const Duration(seconds: 7), (_) async {
      try {
        final currentList = ref.read(bookingsProvider).asData?.value;
        if (currentList == null) return;

        final repo = ref.read(bookingRepositoryProvider);
        final freshList = await repo.getBookings(activeBusinessId);

        final existingIds = currentList.map((b) => b.id).toSet();
        final existingRefs = currentList
            .where((b) => b.bookingReference != null && b.bookingReference!.isNotEmpty)
            .map((b) => b.bookingReference!)
            .toSet();

        for (final fresh in freshList) {
          final isNew = !existingIds.contains(fresh.id) &&
              (fresh.bookingReference == null ||
                  !existingRefs.contains(fresh.bookingReference));
          if (isNew) {
            await ref
                .read(bookingsProvider.notifier)
                .onLiveBookingCreated(fresh);

            final dateFormat = DateFormat('EEE, MMM d · h:mm a');
            final dateStr = dateFormat.format(fresh.startAt);
            final notifTitle = '🎉 New Appointment Booked!';
            final notifBody =
                '${fresh.customerName} booked ${fresh.serviceName ?? "an appointment"} for $dateStr. Ref: ${fresh.displayId}';

            LocalNotificationService.instance.showBookingNotification(
              bookingId: fresh.id,
              title: notifTitle,
              body: notifBody,
              payload: fresh.id,
            );

            final appNotif = AppNotificationModel(
              id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${fresh.id}',
              businessId: fresh.businessId,
              bookingId: fresh.id,
              type: NotificationType.newBooking,
              title: notifTitle,
              body: notifBody,
              customerName: fresh.customerName,
              serviceName: fresh.serviceName ?? 'Service',
              startAt: fresh.startAt,
              endAt: fresh.endAt,
              createdAt: DateTime.now(),
              isRead: false,
              metadata: {
                'displayId': fresh.displayId,
                'source': 'live_sync',
              },
            );
            ref
                .read(notificationsProvider.notifier)
                .onNotificationReceived(appNotif);

            ref.read(latestLiveBookingAlertProvider.notifier).state =
                LiveBookingAlert(
              title: notifTitle,
              message: notifBody,
              booking: fresh,
              eventType: 'booking:created',
              timestamp: DateTime.now(),
            );
          }
        }
      } catch (e) {
        debugPrint('[LiveSync] Polling check: $e');
      }
    });
  }

  ref.onDispose(() {
    subscription.cancel();
    pollTimer?.cancel();
  });
});
