import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';

class NotificationRemoteDataSource {
  FirebaseFirestore? get _firestore {
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveNotification(AppNotificationModel notification) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection('businesses')
          .doc(notification.businessId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      // Also create an FCM trigger document in 'fcm_triggers' collection
      // which Cloud Functions or background triggers can listen to:
      await firestore
          .collection('businesses')
          .doc(notification.businessId)
          .collection('fcm_triggers')
          .doc(notification.id)
          .set({
        'notificationId': notification.id,
        'businessId': notification.businessId,
        'bookingId': notification.bookingId,
        'type': notification.type.value,
        'title': notification.title,
        'body': notification.body,
        'targetTopic': 'business_${notification.businessId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_')}',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Firestore saveNotification failed gracefully: $e');
    }
  }

  Future<List<AppNotificationModel>> getNotifications(String businessId) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('businesses')
          .doc(businessId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => AppNotificationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Firestore getNotifications failed gracefully: $e');
      return [];
    }
  }

  Future<void> markAsRead(String businessId, String notificationId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection('businesses')
          .doc(businessId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Firestore markAsRead failed: $e');
    }
  }

  Future<void> markAllAsRead(String businessId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final snapshot = await firestore
          .collection('businesses')
          .doc(businessId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore markAllAsRead failed: $e');
    }
  }

  Future<void> deleteNotification(String businessId, String notificationId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection('businesses')
          .doc(businessId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Firestore deleteNotification failed: $e');
    }
  }
}
