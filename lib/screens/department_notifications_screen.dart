// screens/department_notifications_screen.dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../theme/modern_theme.dart';

class DepartmentNotificationsScreen extends StatefulWidget {
  const DepartmentNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<DepartmentNotificationsScreen> createState() =>
      _DepartmentNotificationsScreenState();
}

class _DepartmentNotificationsScreenState
    extends State<DepartmentNotificationsScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _showUnreadOnly = false;
  String _selectedFilter = 'all'; // all, reminders, followups, replies

  @override
  void initState() {
    super.initState();
    _initAnimations();
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
                _buildHeader(),
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
                        _buildFilterTabs(),
                        _buildFilterControls(),
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

  Widget _buildHeader() {
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department Notifications',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage citizen communications',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    _markAllAsRead();
                    break;
                  case 'reply_stats':
                    _showReplyStats();
                    break;
                }
              },
              itemBuilder:
                  (context) => [
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
                      value: 'reply_stats',
                      child: Row(
                        children: [
                          Icon(Icons.analytics),
                          SizedBox(width: 12),
                          Text('Reply Statistics'),
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

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab('All', 'all'),
                  const SizedBox(width: 12),
                  _buildFilterTab('Reminders', 'reminders'),
                  const SizedBox(width: 12),
                  _buildFilterTab('Follow-ups', 'followups'),
                  const SizedBox(width: 12),
                  _buildFilterTab('Replies', 'replies'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? ModernTheme.primaryGradient : null,
          color: isSelected ? null : ModernTheme.surfaceVariant,
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

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          _buildShowFilterChip('All', !_showUnreadOnly),
          const SizedBox(width: 12),
          _buildShowFilterChip('Unread', _showUnreadOnly),
          const Spacer(),
          FutureBuilder<int>(
            future: _notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
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

  Widget _buildShowFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showUnreadOnly = label == 'Unread'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? ModernTheme.accentGradient : null,
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        List<NotificationModel> notifications = snapshot.data ?? [];

        // Filter by type
        if (_selectedFilter != 'all') {
          notifications =
              notifications.where((notification) {
                switch (_selectedFilter) {
                  case 'reminders':
                    return notification.type == 'citizen_manual_reminder' ||
                        notification.type == 'department_reminder';
                  case 'followups':
                    return notification.type == 'citizen_followup';
                  case 'replies':
                    return notification.type == 'department_reply';
                  default:
                    return true;
                }
              }).toList();
        }

        // Filter by read status
        if (_showUnreadOnly) {
          notifications = notifications.where((n) => !n.isRead).toList();
        }

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildDepartmentNotificationCard(notifications[index]);
          },
        );
      },
    );
  }

  Widget _buildDepartmentNotificationCard(NotificationModel notification) {
    final canReply = notification.data['canReply'] == true;
    final issueId = notification.data['issueId'];
    final citizenName =
        notification.data['citizenName'] ??
        notification.data['senderName'] ??
        'Citizen';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        color:
            notification.isRead
                ? ModernTheme.surface
                : ModernTheme.primaryBlue.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _getNotificationGradient(notification.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getNotificationEmoji(notification.type),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),

                // Content - FIX: Add proper constraints
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            // FIX: Wrap with Expanded
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
                              maxLines: 2, // FIX: Allow 2 lines
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: ModernTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ModernTheme.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 3, // FIX: Limit lines
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Metadata - FIX: Use Wrap for better layout
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            'From: ${citizenName.length > 15 ? '${citizenName.substring(0, 15)}...' : citizenName}',
                            Icons.person,
                            ModernTheme.accent,
                          ),
                          _buildInfoChip(
                            notification.timeAgo,
                            Icons.access_time,
                            ModernTheme.textTertiary,
                          ),
                          if (issueId != null)
                            _buildInfoChip(
                              'Issue: ${(notification.data['issueTitle'] ?? issueId).toString().length > 20 ? '${(notification.data['issueTitle'] ?? issueId).toString().substring(0, 20)}...' : (notification.data['issueTitle'] ?? issueId)}',
                              Icons.report_problem,
                              ModernTheme.primaryBlue,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Action Buttons
            if (canReply || issueId != null) ...[
              const SizedBox(height: 16),
              // FIX: Better button layout
              Row(
                children: [
                  if (issueId != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToIssue(issueId),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text(
                          'View Issue',
                          style: TextStyle(fontSize: 13), // FIX: Smaller font
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ModernTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // FIX: Smaller padding
                        ),
                      ),
                    ),
                  if (canReply && issueId != null) const SizedBox(width: 12),
                  if (canReply)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDetailedReplyDialog(notification),
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text(
                          'Reply',
                          style: TextStyle(fontSize: 13), // FIX: Smaller font
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ModernTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ), // FIX: Smaller padding
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
          const Icon(Icons.error_outline, size: 64, color: ModernTheme.error),
          const SizedBox(height: 16),
          const Text(
            'Error loading notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
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
            _getEmptyStateTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            style: const TextStyle(
              fontSize: 16,
              color: ModernTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper Methods
  LinearGradient _getNotificationGradient(String type) {
    switch (type) {
      case 'citizen_manual_reminder':
        return ModernTheme.warningGradient;
      case 'citizen_followup':
        return ModernTheme.accentGradient;
      case 'department_reminder':
        return ModernTheme.primaryGradient;
      default:
        return ModernTheme.primaryGradient;
    }
  }

  String _getNotificationEmoji(String type) {
    switch (type) {
      case 'citizen_manual_reminder':
        return '🔔';
      case 'citizen_followup':
        return '💬';
      case 'department_reminder':
        return '⏰';
      case 'department_reply':
        return '💼';
      default:
        return '📢';
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'reminders':
        return 'No reminders';
      case 'followups':
        return 'No follow-ups';
      case 'replies':
        return 'No replies';
      default:
        return _showUnreadOnly ? 'No unread notifications' : 'No notifications';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedFilter) {
      case 'reminders':
        return 'Citizen reminders will appear here';
      case 'followups':
        return 'Citizen follow-up messages will appear here';
      case 'replies':
        return 'Your reply history will appear here';
      default:
        return _showUnreadOnly
            ? 'All caught up! Check back later for updates.'
            : 'Citizen communications will appear here';
    }
  }

  void _navigateToIssue(String issueId) {
    // Navigate to issue detail or show issue info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to issue: $issueId'),
        backgroundColor: ModernTheme.primaryBlue,
      ),
    );
  }

  void _showDetailedReplyDialog(NotificationModel notification) {
    final messageController = TextEditingController();
    final issueTitle = notification.data['issueTitle'] ?? 'Issue';
    final citizenName =
        notification.data['citizenName'] ??
        notification.data['senderName'] ??
        'Citizen';
    final originalMessage =
        notification.data['message'] ??
        notification.data['citizenMessage'] ??
        '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ModernTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.reply, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Reply to Citizen')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Issue and Citizen Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reply to: $citizenName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Issue: $issueTitle',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ModernTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Original Message (if available)
                  if (originalMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Original Message:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ModernTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ModernTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ModernTheme.textTertiary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        originalMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ModernTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Reply Input
                  const Text(
                    'Your Reply:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ModernTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your response...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
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
                      await _notificationService.sendDepartmentReplyToCitizen(
                        issueId: notification.data['issueId'] ?? '',
                        citizenId:
                            notification.data['citizenId'] ??
                            notification.data['senderId'] ??
                            '',
                        replyMessage: messageController.text.trim(),
                        officialName:
                            'Department Official', // Get from user data
                        department: 'Department', // Get from user data
                        originalNotificationId: notification.id,
                      );

                      Navigator.pop(context);
                      _showSuccessSnackBar('Reply sent to $citizenName!');

                      // Mark the original notification as read
                      await _notificationService.markAsRead(notification.id);
                    } catch (e) {
                      _showErrorSnackBar('Failed to send reply: $e');
                    }
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Reply'),
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

  void _showReplyStats() {
    // Show statistics about department responses
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.analytics, color: ModernTheme.primaryBlue),
                SizedBox(width: 12),
                Text('Reply Statistics'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Department response statistics will be shown here.'),
                SizedBox(height: 16),
                Text(
                  'Features include:\n• Response time analytics\n• Reply rate tracking\n• Citizen satisfaction metrics',
                  style: TextStyle(color: ModernTheme.textSecondary),
                ),
              ],
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
