import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final NotificationService _notificationService = NotificationService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Material(
        child: _buildErrorState('Please login to view notifications'),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth < 500 ? screenWidth : (screenWidth < 800 ? 380.0 : 420.0);

    return Material(
      child: Container(
        width: panelWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            const Divider(height: 1),
            Expanded(child: _buildNotificationList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            'Notifications',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.done_all, size: 20),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _notificationService.markAllAsRead(_currentUserId!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Unread'),
            const SizedBox(width: 8),
            _buildFilterChip('Verification'),
            const SizedBox(width: 8),
            _buildFilterChip('Booking'),
            const SizedBox(width: 8),
            _buildFilterChip('Payment'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = label;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
        fontSize: 13,
      ),
    );
  }

  Widget _buildNotificationList() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getUserNotifications(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorStateWithRetry(
            'Error loading notifications',
            snapshot.error.toString(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        List<NotificationModel> notifications = _applyFilter(snapshot.data!);

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _buildNotificationCard(notifications[index]);
          },
        );
      },
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

    return Card(
      margin: EdgeInsets.zero,
      color: notification.isRead
          ? Colors.white
          : AppColors.primary.withValues(alpha: 0.03),
      elevation: notification.isRead ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: notification.isRead
              ? Colors.grey.shade200
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await _notificationService.markAsRead(notification.id);
          }
          _showNotificationDetail(notification);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyMedium.copyWith(
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
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'All'
                ? 'You\'re all caught up!'
                : 'No $_filter notifications',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStateWithRetry(String message, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  // Trigger rebuild to retry
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
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
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: AppTextStyles.titleMedium,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.message,
                style: AppTextStyles.bodyMedium,
              ),
              if (notification.data != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                if (notification.data!['rejectionReason'] != null) ...[
                  Text(
                    'Rejection Reason:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.data!['rejectionReason'],
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                if (notification.data!['adminNotes'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Admin Notes:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.data!['adminNotes'],
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                if (notification.data!['rejectedDocuments'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Documents to Revise:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(notification.data!['rejectedDocuments'] as List)
                      .map((doc) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    doc.toString(),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ],
              const SizedBox(height: 16),
              Text(
                'Received: ${DateFormat('MMM dd, yyyy - hh:mm a').format(notification.createdAt)}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
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
      return DateFormat('MMM dd').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
