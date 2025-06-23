// screens/notifications_screen.dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/simple_theme.dart';
import 'issue_detail_screen.dart';
import '../services/issue_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final IssueService _issueService = IssueService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Mark all as read
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount > 0) {
                return TextButton(
                  onPressed: () async {
                    await _notificationService.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: SimpleTheme.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading notifications',
                    style: TextStyle(fontSize: 16, color: SimpleTheme.error),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationTile(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: SimpleTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, color: SimpleTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll receive updates about your issues here',
            style: TextStyle(fontSize: 14, color: SimpleTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final isUnread = !notification.read;
    final notificationType = _getNotificationType(notification.title);
    final icon = _getNotificationIcon(notificationType);
    final color = _getNotificationColor(notificationType);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: SimpleTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Notification'),
                content: const Text(
                  'Are you sure you want to delete this notification?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: SimpleTheme.error),
                    ),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) async {
        await _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        color: isUnread ? SimpleTheme.primaryBlue.withOpacity(0.05) : null,
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Row(
            children: [
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: SimpleTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                    color: SimpleTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: TextStyle(
                  color: SimpleTheme.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _getTimeAgo(notification.createdAt),
                style: TextStyle(
                  color: SimpleTheme.textSecondary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: SimpleTheme.textSecondary,
          ),
          onTap: () async {
            // Mark as read
            if (isUnread) {
              await _notificationService.markAsRead(notification.id);
            }

            // Navigate to issue detail if issueId exists
            final issueId = notification.data['issueId'];
            if (issueId != null) {
              final issue = await _issueService.getIssueById(issueId);
              if (issue != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IssueDetailScreen(issue: issue),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Issue not found'),
                    backgroundColor: SimpleTheme.error,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  String _getNotificationType(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('resolved')) return 'resolved';
    if (lowerTitle.contains('progress')) return 'progress';
    if (lowerTitle.contains('rejected')) return 'rejected';
    if (lowerTitle.contains('new') || lowerTitle.contains('submitted'))
      return 'new';
    if (lowerTitle.contains('comment') || lowerTitle.contains('note'))
      return 'comment';
    return 'update';
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'resolved':
        return Icons.check_circle;
      case 'progress':
        return Icons.construction;
      case 'rejected':
        return Icons.cancel;
      case 'new':
        return Icons.add_circle;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'resolved':
        return SimpleTheme.success;
      case 'progress':
        return SimpleTheme.accent;
      case 'rejected':
        return SimpleTheme.error;
      case 'new':
        return SimpleTheme.primaryBlue;
      case 'comment':
        return SimpleTheme.warning;
      default:
        return SimpleTheme.textSecondary;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
