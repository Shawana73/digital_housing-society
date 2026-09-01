import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../viewmodels/admin_view_models.dart'; // for BaseAdminViewModel

class NotificationsViewModel extends BaseAdminViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AdminNotification> notifications = [];

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('notifications').get();
      notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return AdminNotification(
          id: doc.id,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          time: data['time'] ?? '',
          icon: Icons.notifications_rounded,
          unread: data['unread'] ?? true,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  List<AdminNotification> get filteredNotifications {
    if (query.isEmpty) return notifications;
    return notifications.where((notification) {
      return notification.title.toLowerCase().contains(query) || notification.message.toLowerCase().contains(query);
    }).toList();
  }

  int get unreadCount => notifications.where((notification) => notification.unread).length;

  Future<void> markAllRead() async {
    try {
      for (final notification in notifications) {
        await _firestore.collection('notifications').doc(notification.id).update({'unread': false});
        notification.unread = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }

  Future<void> markRead(AdminNotification notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).update({'unread': false});
      notification.unread = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> delete(AdminNotification notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).delete();
      notifications.removeWhere((item) => item.id == notification.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
}