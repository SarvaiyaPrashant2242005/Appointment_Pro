import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification_model.dart';

class NotificationLocalDataSource {
  final SharedPreferences _prefs;

  NotificationLocalDataSource(this._prefs);

  String _getKey(String businessId) => 'notifications_$businessId';

  Future<List<AppNotificationModel>> getNotifications(String businessId) async {
    final raw = _prefs.getString(_getKey(businessId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((item) =>
              AppNotificationModel.fromMap(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotification(AppNotificationModel notification) async {
    final list = await getNotifications(notification.businessId);
    final existingIndex = list.indexWhere((n) => n.id == notification.id);

    if (existingIndex >= 0) {
      list[existingIndex] = notification;
    } else {
      list.insert(0, notification);
    }

    final encoded = json.encode(list.map((n) => n.toMap()).toList());
    await _prefs.setString(_getKey(notification.businessId), encoded);
  }

  Future<void> markAsRead(String businessId, String notificationId) async {
    final list = await getNotifications(businessId);
    final index = list.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      list[index] = list[index].copyWith(isRead: true);
      final encoded = json.encode(list.map((n) => n.toMap()).toList());
      await _prefs.setString(_getKey(businessId), encoded);
    }
  }

  Future<void> markAllAsRead(String businessId) async {
    final list = await getNotifications(businessId);
    final updated = list.map((n) => n.copyWith(isRead: true)).toList();
    final encoded = json.encode(updated.map((n) => n.toMap()).toList());
    await _prefs.setString(_getKey(businessId), encoded);
  }

  Future<void> deleteNotification(String businessId, String notificationId) async {
    final list = await getNotifications(businessId);
    list.removeWhere((n) => n.id == notificationId);
    final encoded = json.encode(list.map((n) => n.toMap()).toList());
    await _prefs.setString(_getKey(businessId), encoded);
  }

  Future<void> clearAll(String businessId) async {
    await _prefs.remove(_getKey(businessId));
  }
}
