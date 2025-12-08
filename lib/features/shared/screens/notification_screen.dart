import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Unread', child: Text('Unread Only')),
              const PopupMenuItem(value: 'Verification', child: Text('Verification')),
              const PopupMenuItem(value: 'Booking', child: Text('Bookings')),
              const PopupMenuItem(value: 'Payment', child: Text('Payments')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _notificationService.markAllAsRead(_currentUserId!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear old notifications',
            onPressed: () => _showClearDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          List<NotificationModel> notifications = snapshot.data!;

          // Apply filters
          notifications = _applyFilter(notifications);

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(notifications[index]);
            },
          );
        },
      ),
    );
  }

  List<NotificationModel> _applyFilter(List<NotificationModel> notifications) {
    if (_filter == 'Unread') {
      return notifications.where((n) => !n.isRead).toList();
    } else if (_filter == 'Verification') {
      return notifications
          .where((n) =>
              n.type == NotificationType.verificationApproved ||
              n.type == NotificationType.verificationRejected ||
              n.type == NotificationType.revisionRequested)
          .toList();
    } else if (_filter == 'Booking') {
      return notifications
          .where((n) =>
              n.type == NotificationType.bookingConfirmed ||
              n.type == NotificationType.bookingCancelled ||
              n.type == NotificationType.bookingCompleted)
          .toList();
    } else if (_filter == 'Payment') {
      return notifications
          .where((n) => n.type == NotificationType.paymentReceived)
          .toList();
    }
    return notifications;
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);
    final timeAgo = _getTimeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${notification.title} deleted')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: notification.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await _notificationService.markAsRead(notification.id);
            }
            _showNotificationDetail(notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeAgo,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'All'
                ? 'You\'re all caught up!'
                : 'No $_filter notifications',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetail(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.message),
              if (notification.data != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                if (notification.data!['rejectionReason'] != null) ...[
                  const Text(
                    'Rejection Reason:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(notification.data!['rejectionReason']),
                ],
                if (notification.data!['adminNotes'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Admin Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(notification.data!['adminNotes']),
                ],
                if (notification.data!['rejectedDocuments'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Documents to Revise:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...(notification.data!['rejectedDocuments'] as List)
                      .map((doc) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6),
                                const SizedBox(width: 8),
                                Text(doc.toString()),
                              ],
                            ),
                          )),
                ],
              ],
              const SizedBox(height: 16),
              Text(
                'Received: ${DateFormat('MMM dd, yyyy - hh:mm a').format(notification.createdAt)}',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Notifications'),
        content: const Text(
          'This will delete notifications older than 30 days. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _notificationService.deleteOldNotifications(_currentUserId!, 30);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Old notifications cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.verificationApproved:
        return Icons.verified_user;
      case NotificationType.verificationRejected:
        return Icons.cancel;
      case NotificationType.revisionRequested:
        return Icons.edit_note;
      case NotificationType.bookingConfirmed:
        return Icons.check_circle;
      case NotificationType.bookingCancelled:
        return Icons.cancel_outlined;
      case NotificationType.bookingCompleted:
        return Icons.done_all;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.reviewReceived:
        return Icons.star;
      case NotificationType.sessionReminder:
        return Icons.alarm;
      case NotificationType.documentExpiring:
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.verificationApproved:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingCompleted:
      case NotificationType.paymentReceived:
        return AppColors.success;
      case NotificationType.verificationRejected:
      case NotificationType.bookingCancelled:
        return AppColors.error;
      case NotificationType.revisionRequested:
      case NotificationType.sessionReminder:
      case NotificationType.documentExpiring:
        return AppColors.warning;
      case NotificationType.reviewReceived:
        return Colors.amber;
      default:
        return AppColors.info;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
