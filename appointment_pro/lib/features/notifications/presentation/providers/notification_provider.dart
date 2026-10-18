import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/theme_provider.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/datasources/notification_local_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationRepository(
    local: NotificationLocalDataSource(prefs),
    remote: NotificationRemoteDataSource(),
  );
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotificationModel>>(
  NotificationsController.new,
);

class NotificationsController
    extends AsyncNotifier<List<AppNotificationModel>> {
  late final NotificationRepository _repo;

  @override
  Future<List<AppNotificationModel>> build() async {
    _repo = ref.read(notificationRepositoryProvider);
    final businessId = ref.watch(activeBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      return [];
    }
    return _repo.getNotifications(businessId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final businessId = ref.read(activeBusinessIdProvider);
      if (businessId == null || businessId.isEmpty) return [];
      return _repo.getNotifications(businessId);
    });
  }

  Future<void> onNotificationReceived(AppNotificationModel notification) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId != null &&
        businessId.isNotEmpty &&
        notification.businessId.isNotEmpty &&
        notification.businessId != businessId) {
      return;
    }

    final current = state.asData?.value ?? [];
    if (!current.any((n) => n.id == notification.id)) {
      state = AsyncData([notification, ...current]);
    }

    try {
      await _repo.saveReceivedNotification(notification);
    } catch (_) {}
  }

  Future<void> markAsRead(String notificationId) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    final current = state.asData?.value ?? [];
    state = AsyncData(
      current.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList(),
    );

    try {
      await _repo.markAsRead(businessId, notificationId);
    } catch (_) {
      // rollback or ignore
    }
  }

  Future<void> markAllAsRead() async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    final current = state.asData?.value ?? [];
    state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());

    try {
      await _repo.markAllAsRead(businessId);
    } catch (_) {}
  }

  Future<void> deleteNotification(String notificationId) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    final current = state.asData?.value ?? [];
    state = AsyncData(
      current.where((n) => n.id != notificationId).toList(),
    );

    try {
      await _repo.deleteNotification(businessId, notificationId);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    state = const AsyncData([]);
    try {
      await _repo.clearAll(businessId);
    } catch (_) {}
  }
}

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).asData?.value ?? [];
  return notifs.where((n) => !n.isRead).length;
});
