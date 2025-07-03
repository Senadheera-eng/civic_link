// screens/notifications_screen.dart (Enhanced with Delete and Manual Reminder Features)
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../theme/modern_theme.dart';
import 'issue_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _showUnreadOnly = false;
  bool _isTestingConnection = false;
  bool _isSelectionMode = false;
  Set<String> _selectedNotifications = {};

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeNotifications();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  Future<void> _initializeNotifications() async {
    try {
      print("🔔 Initializing notifications in NotificationsScreen...");
      await _notificationService.initialize();

      // Test connection and create test notification if needed
      await _testNotificationSystem();
    } catch (e) {
      print("❌ Error initializing notifications: $e");
    }
  }

  Future<void> _testNotificationSystem() async {
    setState(() => _isTestingConnection = true);

    try {
      // Test Firestore connection
      await _notificationService.testFirestoreConnection();

      // Create a test notification to ensure the system works
      await _notificationService.createTestNotification();

      print("✅ Notification system test completed");
    } catch (e) {
      print("❌ Notification system test failed: $e");
      _showErrorSnackBar('Failed to initialize notifications: $e');
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildModernHeader(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      color: ModernTheme.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildFilterControls(),
                        if (_isTestingConnection) _buildTestingIndicator(),
                        if (_isSelectionMode) _buildSelectionControls(),
                        Expanded(child: _buildNotificationsList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (_isSelectionMode) {
                  _exitSelectionMode();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSelectionMode
                      ? '${_selectedNotifications.length} Selected'
                      : 'Notifications',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _isSelectionMode
                      ? 'Select notifications to delete'
                      : 'Stay updated with your issues',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!_isSelectionMode)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'select_mode':
                      _enterSelectionMode();
                      break;
                    case 'mark_all_read':
                      _markAllAsRead();
                      break;
                    case 'delete_all':
                      _showDeleteAllDialog();
                      break;
                    // FIX: REMOVE test notification and check reminders options
                    case 'settings':
                      _openNotificationSettings();
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'select_mode',
                        child: Row(
                          children: [
                            Icon(Icons.checklist),
                            SizedBox(width: 12),
                            Text('Select notifications'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'mark_all_read',
                        child: Row(
                          children: [
                            Icon(Icons.done_all),
                            SizedBox(width: 12),
                            Text('Mark all as read'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep, color: Colors.red),
                            SizedBox(width: 12),
                            Text(
                              'Delete all',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      // FIX: REMOVE these items:
                      // - Test Notification
                      // - Check Reminders
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings),
                            SizedBox(width: 12),
                            Text('Notification Settings'),
                          ],
                        ),
                      ),
                    ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: ModernTheme.primaryBlue.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: ModernTheme.primaryBlue.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _selectAll,
            icon: const Icon(Icons.select_all),
            label: const Text('Select All'),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _clearSelection,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed:
                _selectedNotifications.isNotEmpty ? _deleteSelected : null,
            icon: const Icon(Icons.delete),
            label: Text('Delete (${_selectedNotifications.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingIndicator() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ModernTheme.accentGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Testing notification system...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Text(
            'Show:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _buildFilterChip('All', !_showUnreadOnly),
                const SizedBox(width: 12),
                _buildFilterChip('Unread', _showUnreadOnly),
              ],
            ),
          ),
          // FIX: Use StreamBuilder to get real-time unread count (excluding tests)
          StreamBuilder<List<NotificationModel>>(
            stream: _notificationService.getUserNotificationsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              // FIX: Count unread notifications from filtered stream
              final unreadCount = snapshot.data!.where((n) => !n.isRead).length;
              if (unreadCount == 0) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: ModernTheme.errorGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unreadCount unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showUnreadOnly = label == 'Unread';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? ModernTheme.primaryGradient : null,
          color: isSelected ? null : ModernTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? Colors.transparent
                    : ModernTheme.textTertiary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ModernTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getUserNotificationsStream(),
      builder: (context, snapshot) {
        print("🔔 Notification stream state: ${snapshot.connectionState}");
        print("🔔 Has data: ${snapshot.hasData}");
        print("🔔 Data length: ${snapshot.data?.length ?? 0}");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          print("❌ Stream error: ${snapshot.error}");
          return _buildErrorState(snapshot.error.toString());
        }

        List<NotificationModel> notifications = snapshot.data ?? [];

        // FIX: Filter out test notifications
        notifications =
            notifications
                .where((notification) => notification.type != 'test')
                .toList();

        // Filter notifications if needed
        if (_showUnreadOnly) {
          notifications = notifications.where((n) => !n.isRead).toList();
        }

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const BouncingScrollPhysics(),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(notifications[index]);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isSelected = _selectedNotifications.contains(notification.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        color:
            notification.isRead
                ? ModernTheme.surface
                : ModernTheme.primaryBlue.withOpacity(0.05),
        onTap: () => _handleNotificationTap(notification),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection checkbox (if in selection mode)
                if (_isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedNotifications.add(notification.id);
                        } else {
                          _selectedNotifications.remove(notification.id);
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Notification Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _getNotificationGradient(notification.type),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getNotificationColor(
                          notification.type,
                        ).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    notification.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),

                const SizedBox(width: 16),

                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                color: ModernTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: ModernTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              notification.isRead
                                  ? ModernTheme.textSecondary
                                  : ModernTheme.textPrimary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Text(
                            notification.timeAgo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ModernTheme.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _buildNotificationTypeChip(notification.type),
                        ],
                      ),

                      // Show follow-up button for reminders
                      if (_canShowFollowUpButton(notification)) ...[
                        const SizedBox(height: 12),
                        _buildFollowUpButton(notification),
                      ],

                      // Show manual reminder button for citizen reminders
                      if (_canShowManualReminderButton(notification)) ...[
                        const SizedBox(height: 8),
                        _buildManualReminderButton(notification),
                      ],
                    ],
                  ),
                ),

                // Action Menu (if not in selection mode)
                if (!_isSelectionMode)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: ModernTheme.textSecondary,
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'mark_read':
                          if (!notification.isRead) {
                            _notificationService.markAsRead(notification.id);
                          }
                          break;
                        case 'delete':
                          _deleteNotification(notification);
                          break;
                        case 'reply':
                          _showReplyDialog(notification);
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          if (!notification.isRead)
                            const PopupMenuItem(
                              value: 'mark_read',
                              child: Row(
                                children: [
                                  Icon(Icons.done, size: 18),
                                  SizedBox(width: 8),
                                  Text('Mark as read'),
                                ],
                              ),
                            ),
                          if (_canReplyToNotification(notification))
                            const PopupMenuItem(
                              value: 'reply',
                              child: Row(
                                children: [
                                  Icon(Icons.reply, size: 18),
                                  SizedBox(width: 8),
                                  Text('Reply'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpButton(NotificationModel notification) {
    return Container(
      width: double.infinity,
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () => _showFollowUpDialog(notification),
        icon: const Icon(Icons.message, size: 16),
        label: const Text('Send Follow-up', style: TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ModernTheme.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildManualReminderButton(NotificationModel notification) {
    return Container(
      width: double.infinity,
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () => _showManualReminderDialog(notification),
        icon: const Icon(Icons.notifications_active, size: 16),
        label: const Text('Send Reminder', style: TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ModernTheme.warning,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  bool _canShowFollowUpButton(NotificationModel notification) {
    return notification.type == 'citizen_reminder' &&
        notification.data['canSendFollowUp'] == true;
  }

  bool _canShowManualReminderButton(NotificationModel notification) {
    return notification.type == 'citizen_reminder' &&
        notification.data['canSendManualReminder'] == true;
  }

  bool _canReplyToNotification(NotificationModel notification) {
    return notification.data['canReply'] == true ||
        notification.type == 'department_reminder' ||
        notification.type == 'citizen_followup' ||
        notification.type == 'citizen_manual_reminder';
  }

  Widget _buildNotificationTypeChip(String type) {
    Color color = _getNotificationColor(type);
    String label = _getNotificationTypeLabel(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading notifications...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ModernTheme.errorGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Error loading notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: ModernTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GradientButton(
                text: 'Retry',
                onPressed: () => setState(() {}),
                width: 120,
                height: 44,
              ),
              const SizedBox(width: 12),
              GradientButton(
                text: 'Test Connection',
                onPressed: _testNotificationSystem,
                width: 140,
                height: 44,
                gradient: ModernTheme.accentGradient,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ModernTheme.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _showUnreadOnly
                ? 'No unread notifications'
                : 'No notifications yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showUnreadOnly
                ? 'All caught up! Check back later for updates.'
                : 'You\'ll see notifications about your issues here.',
            style: const TextStyle(
              fontSize: 16,
              color: ModernTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'When you receive notifications, they will appear here.',
            style: TextStyle(fontSize: 14, color: ModernTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'issue_update':
        return ModernTheme.primaryBlue;
      case 'welcome':
        return ModernTheme.success;
      case 'system_update':
        return ModernTheme.warning;
      case 'reminder':
      case 'citizen_reminder':
      case 'department_reminder':
      case 'citizen_manual_reminder':
        return ModernTheme.accent;
      case 'citizen_followup':
        return ModernTheme.info;
      case 'department_reply':
        return ModernTheme.primaryBlue;
      case 'test':
        return ModernTheme.error;
      default:
        return ModernTheme.textSecondary;
    }
  }

  LinearGradient _getNotificationGradient(String type) {
    switch (type) {
      case 'issue_update':
        return ModernTheme.primaryGradient;
      case 'welcome':
        return ModernTheme.successGradient;
      case 'system_update':
        return ModernTheme.warningGradient;
      case 'reminder':
      case 'citizen_reminder':
      case 'department_reminder':
      case 'citizen_manual_reminder':
        return ModernTheme.accentGradient;
      case 'test':
        return ModernTheme.errorGradient;
      default:
        return ModernTheme.primaryGradient;
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'issue_update':
        return 'Issue Update';
      case 'welcome':
        return 'Welcome';
      case 'system_update':
        return 'System';
      case 'reminder':
      case 'citizen_reminder':
        return 'Reminder';
      case 'department_reminder':
        return 'Dept. Reminder';
      case 'citizen_followup':
        return 'Follow-up';
      case 'citizen_manual_reminder':
        return 'Manual Reminder';
      case 'department_reply':
        return 'Reply';
      case 'test':
        return 'Test';
      default:
        return 'General';
    }
  }

  // Selection Mode Methods
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedNotifications.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotifications.clear();
    });
  }

  void _selectAll() {
    // We need to get the current notifications to select all
    // This is a simplified version - in practice you'd get them from the stream
    setState(() {
      // This would need to be updated with actual notification IDs
      // For now, we'll show the UI pattern
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNotifications.clear();
    });
  }

  void _deleteSelected() async {
    if (_selectedNotifications.isEmpty) return;

    try {
      await _notificationService.bulkDeleteNotifications(
        _selectedNotifications.toList(),
      );

      setState(() {
        _selectedNotifications.clear();
        _isSelectionMode = false;
      });

      _showSuccessSnackBar('Selected notifications deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete notifications: $e');
    }
  }

  // Notification Action Methods
  void _handleNotificationTap(NotificationModel notification) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedNotifications.contains(notification.id)) {
          _selectedNotifications.remove(notification.id);
        } else {
          _selectedNotifications.add(notification.id);
        }
      });
      return;
    }

    // Mark as read if not already read
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case 'issue_update':
        final issueId = notification.data['issueId'];
        if (issueId != null) {
          _navigateToIssueDetail(issueId);
        }
        break;
      case 'welcome':
        Navigator.pop(context);
        break;
      case 'citizen_reminder':
      case 'department_reminder':
      case 'citizen_manual_reminder':
        final issueId = notification.data['issueId'];
        if (issueId != null) {
          _navigateToIssueDetail(issueId);
        }
        break;
      default:
        break;
    }
  }

  void _navigateToIssueDetail(String issueId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to issue: $issueId'),
        backgroundColor: ModernTheme.primaryBlue,
      ),
    );
  }

  void _showFollowUpDialog(NotificationModel notification) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Send Follow-up Message'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send a follow-up message about: ${notification.data['issueTitle'] ?? 'your issue'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ModernTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (messageController.text.trim().isNotEmpty) {
                    try {
                      await _notificationService.sendCitizenFollowUp(
                        issueId: notification.data['issueId'] ?? '',
                        message: messageController.text.trim(),
                        category: notification.data['category'] ?? '',
                      );
                      Navigator.pop(context);
                      _showSuccessSnackBar('Follow-up message sent!');
                    } catch (e) {
                      _showErrorSnackBar('Failed to send follow-up: $e');
                    }
                  }
                },
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }

  void _showManualReminderDialog(NotificationModel notification) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.notifications_active, color: ModernTheme.warning),
                const SizedBox(width: 8),
                const Expanded(child: Text('Send Manual Reminder')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send a reminder to the ${notification.data['category'] ?? ''} department about: ${notification.data['issueTitle'] ?? 'your issue'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ModernTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ModernTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ModernTheme.warning.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: ModernTheme.warning,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can only send one reminder per day for each issue.',
                          style: TextStyle(
                            fontSize: 12,
                            color: ModernTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Add a message to your reminder...',
                    border: OutlineInputBorder(),
                    labelText: 'Your message',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (messageController.text.trim().isNotEmpty) {
                    try {
                      await _notificationService.sendManualReminderToDepartment(
                        issueId: notification.data['issueId'] ?? '',
                        issueTitle: notification.data['issueTitle'] ?? '',
                        category: notification.data['category'] ?? '',
                        citizenMessage: messageController.text.trim(),
                      );
                      Navigator.pop(context);
                      _showSuccessSnackBar(
                        'Manual reminder sent to department!',
                      );
                    } catch (e) {
                      _showErrorSnackBar('Failed to send reminder: $e');
                    }
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.warning,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  void _showReplyDialog(NotificationModel notification) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Send Reply'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reply to: ${notification.data['senderName'] ?? notification.data['citizenName'] ?? 'Citizen'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ModernTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type your reply...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (messageController.text.trim().isNotEmpty) {
                    try {
                      await _notificationService.sendDepartmentReplyToCitizen(
                        issueId: notification.data['issueId'] ?? '',
                        citizenId:
                            notification.data['senderId'] ??
                            notification.data['citizenId'] ??
                            '',
                        replyMessage: messageController.text.trim(),
                        officialName:
                            'Department Official', // Get from user data
                        department: notification.data['category'] ?? '',
                        originalNotificationId: notification.id,
                      );
                      Navigator.pop(context);
                      _showSuccessSnackBar('Reply sent!');
                    } catch (e) {
                      _showErrorSnackBar('Failed to send reply: $e');
                    }
                  }
                },
                child: const Text('Send Reply'),
              ),
            ],
          ),
    );
  }

  void _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _showSuccessSnackBar('All notifications marked as read');
    } catch (e) {
      _showErrorSnackBar('Failed to mark notifications as read: $e');
    }
  }

  void _deleteNotification(NotificationModel notification) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Notification'),
            content: const Text(
              'Are you sure you want to delete this notification?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // FIX: Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Deleting notification...'),
              ],
            ),
            backgroundColor: ModernTheme.primaryBlue,
            duration: Duration(seconds: 1),
          ),
        );

        await _notificationService.deleteNotification(notification.id);

        // FIX: Force UI refresh by calling setState
        if (mounted) {
          setState(() {
            // This will trigger a rebuild and the stream will update
          });
        }

        _showSuccessSnackBar('Notification deleted');
      } catch (e) {
        _showErrorSnackBar('Failed to delete notification: $e');
      }
    }
  }

  void _showDeleteAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: ModernTheme.error),
                const SizedBox(width: 8),
                const Text('Delete All Notifications'),
              ],
            ),
            content: const Text(
              'Are you sure you want to delete ALL your notifications? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.error,
                ),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.deleteAllNotifications();
        _showSuccessSnackBar('All notifications deleted');
      } catch (e) {
        _showErrorSnackBar('Failed to delete notifications: $e');
      }
    }
  }

  void _openNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ModernTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ModernTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _pushNotifications = true;
  bool _issueUpdates = true;
  bool _systemUpdates = false;
  bool _emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification Settings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Manage your preferences',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Settings Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    color: ModernTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildSettingCard(
                          title: 'Push Notifications',
                          subtitle: 'Receive notifications on your device',
                          icon: Icons.notifications,
                          value: _pushNotifications,
                          onChanged:
                              (value) =>
                                  setState(() => _pushNotifications = value),
                        ),

                        const SizedBox(height: 16),

                        _buildSettingCard(
                          title: 'Issue Updates',
                          subtitle: 'Get notified when your issues are updated',
                          icon: Icons.update,
                          value: _issueUpdates,
                          onChanged:
                              (value) => setState(() => _issueUpdates = value),
                        ),

                        const SizedBox(height: 16),

                        _buildSettingCard(
                          title: 'System Updates',
                          subtitle: 'App updates and maintenance notifications',
                          icon: Icons.system_update,
                          value: _systemUpdates,
                          onChanged:
                              (value) => setState(() => _systemUpdates = value),
                        ),

                        const SizedBox(height: 16),

                        _buildSettingCard(
                          title: 'Email Notifications',
                          subtitle: 'Receive notifications via email',
                          icon: Icons.email,
                          value: _emailNotifications,
                          onChanged:
                              (value) =>
                                  setState(() => _emailNotifications = value),
                        ),

                        const SizedBox(height: 32),

                        GradientButton(
                          text: 'Save Settings',
                          onPressed: _saveSettings,
                          icon: Icons.save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ModernCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ModernTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ModernTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ModernTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  void _saveSettings() async {
    try {
      await _notificationService.updateNotificationPreferences(
        pushNotifications: _pushNotifications,
        issueUpdates: _issueUpdates,
        systemUpdates: _systemUpdates,
        emailNotifications: _emailNotifications,
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Settings saved successfully'),
            ],
          ),
          backgroundColor: ModernTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text('Failed to save settings: $e'),
            ],
          ),
          backgroundColor: ModernTheme.error,
        ),
      );
    }
  }
}
