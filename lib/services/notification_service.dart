import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user notifications stream
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return NotificationModel.fromMap(doc.id, doc.data());
        }).toList();
      }).handleError((error) {
        // ignore: avoid_print
        print('Error loading notifications: $error');
        // If index error, try without orderBy
        return _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .snapshots()
            .map((snapshot) {
          final notifications = snapshot.docs.map((doc) {
            return NotificationModel.fromMap(doc.id, doc.data());
          }).toList();
          // Sort in memory instead
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error setting up notification stream: $e');
      // Return empty stream if everything fails
      return Stream.value([]);
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Create a notification
  Future<String?> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore.collection('notifications').add(notification.toMap());
      return docRef.id;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating notification: $e');
      return null;
    }
  }

  /// Get notification by ID
  Future<NotificationModel?> getNotification(String notificationId) async {
    try {
      final doc = await _firestore.collection('notifications').doc(notificationId).get();
      if (doc.exists) {
        return NotificationModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting notification: $e');
      return null;
    }
  }

  /// Get notifications by type
  Stream<List<NotificationModel>> getNotificationsByType(String userId, NotificationType type) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Delete old notifications (older than specified days)
  Future<bool> deleteOldNotifications(String userId, int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting old notifications: $e');
      return false;
    }
  }
}
