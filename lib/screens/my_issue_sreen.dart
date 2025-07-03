// screens/my_issues_screen.dart (Enhanced with Manual Reminder Feature)
import 'package:flutter/material.dart';
import '../services/issue_service.dart';
import '../services/notification_service.dart';
import '../models/issue_model.dart';
import '../theme/modern_theme.dart';
import 'issue_detail_screen.dart';

class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({Key? key}) : super(key: key);

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen>
    with TickerProviderStateMixin {
  final IssueService _issueService = IssueService();
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    _tabController.dispose();
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
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Scrollable Header
                  _buildModernHeader(),
                  _buildModernTabBar(),

                  // Main Content Container
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      color: ModernTheme.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: StreamBuilder<List<IssueModel>>(
                      stream: _issueService.getUserIssuesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            height: 400,
                            child: _buildLoadingState(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Container(
                            height: 400,
                            child: _buildErrorState(),
                          );
                        }

                        final issues = snapshot.data ?? [];
                        final filteredIssues =
                            _selectedFilter == 'all'
                                ? issues
                                : issues
                                    .where(
                                      (issue) =>
                                          issue.status == _selectedFilter,
                                    )
                                    .toList();

                        if (filteredIssues.isEmpty) {
                          return Container(
                            height: 400,
                            child: _buildEmptyState(),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              ...filteredIssues.asMap().entries.map(
                                (entry) => _buildModernIssueCard(
                                  entry.value,
                                  entry.key,
                                ),
                              ),
                              const SizedBox(height: 40), // Bottom padding
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Issues',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Track your reported issues',
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
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: ModernTheme.primaryBlue,
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'In Progress'),
          Tab(text: 'Resolved'),
        ],
        onTap: (index) {
          setState(() {
            switch (index) {
              case 0:
                _selectedFilter = 'all';
                break;
              case 1:
                _selectedFilter = 'pending';
                break;
              case 2:
                _selectedFilter = 'in_progress';
                break;
              case 3:
                _selectedFilter = 'resolved';
                break;
            }
          });
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ModernTheme.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ModernTheme.accent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading your issues...',
            style: TextStyle(
              fontSize: 16,
              color: ModernTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ModernTheme.errorGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ModernTheme.error.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Error loading issues',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            text: 'Retry',
            onPressed: () => setState(() {}),
            width: 120,
            height: 44,
            gradient: ModernTheme.primaryGradient,
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
              boxShadow: [
                BoxShadow(
                  color: ModernTheme.accent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _selectedFilter == 'all' ? Icons.inbox : Icons.filter_list,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'all'
                ? 'No issues reported yet'
                : 'No ${_getStatusText(_selectedFilter)} issues',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          if (_selectedFilter == 'all') ...[
            const SizedBox(height: 8),
            const Text(
              'Report an issue to see it here',
              style: TextStyle(fontSize: 16, color: ModernTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernIssueCard(IssueModel issue, int index) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);
    final canSendReminder = _canSendReminder(issue);
    final daysSinceCreated = DateTime.now().difference(issue.createdAt).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IssueDetailScreen(issue: issue),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ModernTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ModernTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(issue.category),
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ModernTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: ModernTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              issue.address,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ModernTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ModernStatusChip(
                      text: _getStatusText(issue.status),
                      color: statusColor,
                      icon: _getStatusIcon(issue.status),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            priorityColor,
                            priorityColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: priorityColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        issue.priority,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              issue.description,
              style: const TextStyle(
                fontSize: 15,
                color: ModernTheme.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Footer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ModernTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        issue.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ModernTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (issue.imageUrls.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: ModernTheme.accentGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.image,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${issue.imageUrls.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: ModernTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(issue.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ModernTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 🆕 MANUAL REMINDER SECTION
            if (canSendReminder) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ModernTheme.warning.withOpacity(0.1),
                      ModernTheme.warning.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ModernTheme.warning.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: ModernTheme.warningGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Issue Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ModernTheme.warning,
                                ),
                              ),
                              Text(
                                'This issue has been pending for $daysSinceCreated days. Send a reminder to the department?',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ModernTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSendReminderDialog(issue),
                        icon: const Icon(Icons.notifications_active, size: 16),
                        label: const Text(
                          'Send Reminder to Department',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ModernTheme.warning,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Admin Notes (if any)
            if (issue.adminNotes != null && issue.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ModernTheme.accent.withOpacity(0.1),
                      ModernTheme.accent.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ModernTheme.accent.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: ModernTheme.accentGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Response',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ModernTheme.accent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            issue.adminNotes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ModernTheme.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🆕 MANUAL REMINDER FUNCTIONALITY
  bool _canSendReminder(IssueModel issue) {
    // Allow reminders for pending issues that are older than 1 day
    return issue.status.toLowerCase() == 'pending' &&
        DateTime.now().difference(issue.createdAt).inDays >= 1;
  }

  void _showSendReminderDialog(IssueModel issue) {
    final messageController = TextEditingController();
    final daysPending = DateTime.now().difference(issue.createdAt).inDays;

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
                    gradient: ModernTheme.warningGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Send Manual Reminder',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Issue Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ModernTheme.primaryBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Department: ${issue.category}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ModernTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'Pending for: $daysPending days',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ModernTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Warning Notice
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

                  // Message Input
                  const Text(
                    'Your Message:',
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
                      hintText: 'Add a message to your reminder...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This message will be sent to all officials in the ${issue.category} department.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: ModernTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  bool isLoading = false;

                  return ElevatedButton.icon(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              final message = messageController.text.trim();
                              if (message.isNotEmpty) {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  await _notificationService
                                      .sendManualReminderToDepartment(
                                        issueId: issue.id,
                                        issueTitle: issue.title,
                                        category: issue.category,
                                        citizenMessage: message,
                                      );

                                  // FIX: Close dialog BEFORE showing success message
                                  Navigator.pop(context);

                                  // FIX: Show success message
                                  _showSuccessSnackBar(
                                    'Reminder sent to ${issue.category} department successfully!',
                                  );
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  _showErrorSnackBar(
                                    'Failed to send reminder: $e',
                                  );
                                }
                              } else {
                                _showErrorSnackBar(
                                  'Please enter a message for your reminder',
                                );
                              }
                            },
                    icon:
                        isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(Icons.send),
                    label: Text(isLoading ? 'Sending...' : 'Send Reminder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ModernTheme.warning,
                      foregroundColor: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Sending reminder...'),
                  ],
                ),
              ),
            ),
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

  // Helper methods (existing ones remain the same)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ModernTheme.warning;
      case 'in_progress':
        return ModernTheme.accent;
      case 'resolved':
        return ModernTheme.success;
      case 'rejected':
        return ModernTheme.error;
      default:
        return ModernTheme.textSecondary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return ModernTheme.success;
      case 'medium':
        return ModernTheme.warning;
      case 'high':
        return ModernTheme.error;
      case 'critical':
        return const Color(0xFFDC2626);
      default:
        return ModernTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'in_progress':
        return Icons.construction;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Road & Transportation':
        return Icons.construction;
      case 'Water & Sewerage':
        return Icons.water_drop;
      case 'Electricity':
        return Icons.electrical_services;
      case 'Public Safety':
        return Icons.security;
      case 'Waste Management':
        return Icons.delete;
      case 'Parks & Recreation':
        return Icons.park;
      case 'Street Lighting':
        return Icons.lightbulb;
      case 'Public Buildings':
        return Icons.business;
      case 'Traffic Management':
        return Icons.traffic;
      case 'Environmental Issues':
        return Icons.eco;
      default:
        return Icons.report_problem;
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
