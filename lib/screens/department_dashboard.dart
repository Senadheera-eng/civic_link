// screens/department_dashboard.dart (REFACTORED MAIN FILE)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/issue_service.dart';
import '../models/user_model.dart';
import '../models/issue_model.dart';
import '../theme/modern_theme.dart';
import 'issue_detail_screen.dart';
import 'dart:async';

// Import the separated widgets
import '../widgets/department/department_header.dart';
import '../widgets/department/department_stats.dart';
import '../widgets/department/performance_metrics.dart';
import '../widgets/department/filter_tabs.dart';
import '../widgets/department/management_options_modal.dart';
import '../widgets/department/analytics_modal.dart';
import '../widgets/department/official_issue_detail_screen.dart';

class DepartmentDashboard extends StatefulWidget {
  @override
  _DepartmentDashboardState createState() => _DepartmentDashboardState();
}

class _DepartmentDashboardState extends State<DepartmentDashboard>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final IssueService _issueService = IssueService();

  late AnimationController _fadeController;
  late AnimationController _refreshController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _refreshAnimation;

  StreamSubscription<QuerySnapshot>? _issuesSubscription;

  UserModel? _userData;
  List<IssueModel> _departmentIssues = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedTab = 'pending';

  // Statistics
  int _totalIssues = 0;
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _resolvedCount = 0;
  int _rejectedCount = 0;
  int _thisWeekCount = 0;
  int _thisMonthCount = 0;
  int _urgentCount = 0;
  int _assignedToMeCount = 0;

  // Performance metrics
  double _averageResolutionTime = 0.0;
  double _resolutionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _issuesSubscription?.cancel();
    _fadeController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_isLoading) {
      setState(() => _isRefreshing = true);
      _refreshController.forward().then((_) => _refreshController.reset());
    }

    try {
      // Load user data
      final userData = await _authService.getUserData();

      if (userData == null ||
          !userData.isOfficial ||
          userData.department == null) {
        _showErrorSnackBar('Access denied: Invalid account type');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      if (!userData.isVerified) {
        return;
      }

      // Load department issues
      final issues = await _getIssuesByDepartment(userData.department!);
      final assignedIssues = await _getAssignedIssues(userData.uid);

      // Calculate statistics
      _calculateStatistics(issues, assignedIssues);
      _calculatePerformanceMetrics(issues);

      setState(() {
        _userData = userData;
        _departmentIssues = issues;
        _isLoading = false;
        _isRefreshing = false;
      });
      // Setup real-time listener after userData is available
      _setupRealTimeListener();
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      _showErrorSnackBar('Failed to load dashboard data: ${e.toString()}');
    }
  }

  void _setupRealTimeListener() {
    // Cancel existing subscription to avoid duplicates
    _issuesSubscription?.cancel();

    if (_userData?.department == null) {
      print("⚠️ No department found, skipping real-time listener setup");
      return;
    }

    print(
      "🔔 Setting up real-time listener for department: ${_userData!.department}",
    );

    // Listen to real-time changes in issues collection
    _issuesSubscription = FirebaseFirestore.instance
        .collection('issues')
        .where('category', isEqualTo: _userData!.department!)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            print("🔔 Real-time update: ${snapshot.docs.length} issues found");
            _processRealTimeUpdate(snapshot);
          }
        });
  }

  void _processRealTimeUpdate(QuerySnapshot snapshot) {
    final issues =
        snapshot.docs.map((doc) => IssueModel.fromFirestore(doc)).toList();

    setState(() {
      _departmentIssues = issues;
    });

    // Recalculate statistics with updated data
    _getAssignedIssues(_userData?.uid ?? '').then((assignedIssues) {
      _calculateStatistics(issues, assignedIssues);
      _calculatePerformanceMetrics(issues);
      setState(() {});
    });
  }

  void _calculateStatistics(
    List<IssueModel> issues,
    List<IssueModel> assignedIssues,
  ) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    _totalIssues = issues.length;
    _pendingCount =
        issues.where((issue) => issue.status.toLowerCase() == 'pending').length;
    _inProgressCount =
        issues
            .where((issue) => issue.status.toLowerCase() == 'in_progress')
            .length;
    _resolvedCount =
        issues
            .where((issue) => issue.status.toLowerCase() == 'resolved')
            .length;
    _rejectedCount =
        issues
            .where((issue) => issue.status.toLowerCase() == 'rejected')
            .length;
    _thisWeekCount =
        issues.where((issue) => issue.createdAt.isAfter(weekAgo)).length;
    _thisMonthCount =
        issues.where((issue) => issue.createdAt.isAfter(monthAgo)).length;
    _assignedToMeCount = assignedIssues.length;

    _urgentCount =
        issues
            .where(
              (issue) =>
                  (issue.priority.toLowerCase() == 'high' ||
                      issue.priority.toLowerCase() == 'critical') &&
                  issue.status.toLowerCase() == 'pending',
            )
            .length;
  }

  void _calculatePerformanceMetrics(List<IssueModel> issues) {
    final resolvedIssues =
        issues
            .where((issue) => issue.status.toLowerCase() == 'resolved')
            .toList();

    if (resolvedIssues.isNotEmpty) {
      final totalHours = resolvedIssues.fold<double>(0, (sum, issue) {
        if (issue.updatedAt != null) {
          return sum +
              issue.updatedAt!.difference(issue.createdAt).inHours.toDouble();
        }
        return sum;
      });
      _averageResolutionTime = totalHours / resolvedIssues.length;
      _resolutionRate = (resolvedIssues.length / _totalIssues) * 100;
    } else {
      _averageResolutionTime = 0.0;
      _resolutionRate = 0.0;
    }
  }

  void _checkForNewIssues(List<IssueModel> newIssues) {
    final now = DateTime.now();
    final recentIssues =
        newIssues
            .where(
              (issue) =>
                  now.difference(issue.createdAt).inMinutes < 5 &&
                  issue.status.toLowerCase() == 'pending',
            )
            .toList();

    if (recentIssues.isNotEmpty && _departmentIssues.isNotEmpty) {
      _showSuccessSnackBar(
        '${recentIssues.length} new issue(s) reported in your department!',
      );
    }
  }

  List<IssueModel> get _filteredIssues {
    switch (_selectedTab) {
      case 'pending':
        return _departmentIssues
            .where((issue) => issue.status.toLowerCase() == 'pending')
            .toList();
      case 'in_progress':
        return _departmentIssues
            .where((issue) => issue.status.toLowerCase() == 'in_progress')
            .toList();
      case 'resolved':
        return _departmentIssues
            .where((issue) => issue.status.toLowerCase() == 'resolved')
            .toList();
      case 'urgent':
        return _departmentIssues
            .where(
              (issue) =>
                  (issue.priority.toLowerCase() == 'high' ||
                      issue.priority.toLowerCase() == 'critical') &&
                  issue.status.toLowerCase() == 'pending',
            )
            .toList();
      case 'assigned':
        return _departmentIssues
            .where((issue) => issue.assignedTo == _userData?.uid)
            .toList();
      default:
        return _departmentIssues;
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _signOut() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: ModernCard(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Signing out...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      await _authService.signOut();
      Navigator.of(context).pop();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Sign out failed: $e');
    }
  }

  void _showManagementOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ManagementOptionsModal(
            userData: _userData,
            departmentIssues: _departmentIssues,
            onRefresh: _loadData,
          ),
    );
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder:
          (context) => AnalyticsModal(
            userData: _userData,
            totalIssues: _totalIssues,
            resolutionRate: _resolutionRate,
            averageResolutionTime: _averageResolutionTime,
            thisMonthCount: _thisMonthCount,
            pendingCount: _pendingCount,
            inProgressCount: _inProgressCount,
            resolvedCount: _resolvedCount,
            rejectedCount: _rejectedCount,
            urgentCount: _urgentCount,
            assignedToMeCount: _assignedToMeCount,
            thisWeekCount: _thisWeekCount,
          ),
    );
  }

  // Issue service methods
  Future<List<IssueModel>> _getIssuesByDepartment(String department) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('issues')
              .where('category', isEqualTo: department)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => IssueModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting issues by department: $e');
      return [];
    }
  }

  Future<List<IssueModel>> _getAssignedIssues(String userId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('issues')
              .where('assignedTo', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => IssueModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting assigned issues: $e');
      return [];
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: ModernTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: ModernTheme.primaryGradient,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                SizedBox(height: 24),
                Text(
                  'Loading Dashboard...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we fetch your department data',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: ModernTheme.primaryBlue,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: DepartmentHeader(
                      userData: _userData,
                      urgentCount: _urgentCount,
                      isRefreshing: _isRefreshing,
                      refreshAnimation: _refreshAnimation,
                      onSignOut: _signOut,
                      onShowAnalytics: _showAnalytics,
                    ),
                  ),

                  // Main content with rounded top
                  SliverToBoxAdapter(
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DepartmentStats(
                            totalIssues: _totalIssues,
                            thisWeekCount: _thisWeekCount,
                            pendingCount: _pendingCount,
                            inProgressCount: _inProgressCount,
                            resolvedCount: _resolvedCount,
                            urgentCount: _urgentCount,
                          ),
                          PerformanceMetrics(
                            resolutionRate: _resolutionRate,
                            averageResolutionTime: _averageResolutionTime,
                            assignedToMeCount: _assignedToMeCount,
                          ),
                          FilterTabs(
                            selectedTab: _selectedTab,
                            pendingCount: _pendingCount,
                            urgentCount: _urgentCount,
                            assignedToMeCount: _assignedToMeCount,
                            inProgressCount: _inProgressCount,
                            resolvedCount: _resolvedCount,
                            onTabSelected: (tab) {
                              setState(() => _selectedTab = tab);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Issues list
                  _buildIssuesSliver(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: _refreshData,
            backgroundColor: ModernTheme.accent,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "manage",
            onPressed: _showManagementOptions,
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Manage'),
            backgroundColor: ModernTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSliver() {
    final filteredIssues = _filteredIssues;

    if (filteredIssues.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 400,
          color: ModernTheme.background,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: ModernTheme.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getEmptyStateIcon(_selectedTab),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _getEmptyStateTitle(_selectedTab),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateSubtitle(_selectedTab),
                  style: const TextStyle(
                    fontSize: 16,
                    color: ModernTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == 0) {
          // Add top padding for the first item
          return Container(
            color: ModernTheme.background,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
                left: 24,
                right: 24,
                bottom: 8,
              ),
              child: _buildIssueCard(filteredIssues[index], index),
            ),
          );
        } else if (index == filteredIssues.length - 1) {
          // Add bottom padding for the last item to account for FAB
          return Container(
            color: ModernTheme.background,
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
              child: _buildIssueCard(filteredIssues[index], index),
            ),
          );
        } else {
          return Container(
            color: ModernTheme.background,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _buildIssueCard(filteredIssues[index], index),
            ),
          );
        }
      }, childCount: filteredIssues.length),
    );
  }

  Widget _buildIssueCard(IssueModel issue, int index) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);
    final isUrgent =
        issue.priority.toLowerCase() == 'high' ||
        issue.priority.toLowerCase() == 'critical';
    final isAssignedToMe = issue.assignedTo == _userData?.uid;

    return ModernCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfficialIssueDetailScreen(issue: issue),
          ),
        ).then((_) => _loadData());
      },
      color: isUrgent ? ModernTheme.error.withOpacity(0.05) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and priority
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient:
                      isUrgent
                          ? ModernTheme.errorGradient
                          : ModernTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUrgent ? Icons.priority_high : Icons.report_problem,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ModernTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ModernTheme.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'By ${issue.userName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ModernTheme.textSecondary,
                          ),
                        ),
                        if (isAssignedToMe) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(color: ModernTheme.textSecondary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ModernTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ASSIGNED TO YOU',
                              style: TextStyle(
                                fontSize: 10,
                                color: ModernTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ModernStatusChip(
                    text: _getStatusText(issue.status),
                    color: statusColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(8),
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
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // Footer with location, images, and time
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
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
              if (issue.imageUrls.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ModernTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, size: 12, color: ModernTheme.accent),
                      const SizedBox(width: 2),
                      Text(
                        '${issue.imageUrls.length}',
                        style: TextStyle(
                          fontSize: 11,
                          color: ModernTheme.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                _getTimeAgo(issue.createdAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: ModernTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Admin notes preview
          if (issue.adminNotes != null && issue.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ModernTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ModernTheme.accent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.note_alt, size: 16, color: ModernTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue.adminNotes!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ModernTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods
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

  IconData _getEmptyStateIcon(String tab) {
    switch (tab) {
      case 'pending':
        return Icons.pending_actions;
      case 'urgent':
        return Icons.priority_high;
      case 'assigned':
        return Icons.assignment_ind;
      case 'in_progress':
        return Icons.construction;
      case 'resolved':
        return Icons.check_circle_outline;
      default:
        return Icons.inbox_outlined;
    }
  }

  String _getEmptyStateTitle(String tab) {
    switch (tab) {
      case 'pending':
        return 'No Pending Issues';
      case 'urgent':
        return 'No Urgent Issues';
      case 'assigned':
        return 'No Assigned Issues';
      case 'in_progress':
        return 'No Issues In Progress';
      case 'resolved':
        return 'No Resolved Issues';
      default:
        return 'No Issues Found';
    }
  }

  String _getEmptyStateSubtitle(String tab) {
    switch (tab) {
      case 'pending':
        return 'New issues will appear here when reported';
      case 'urgent':
        return 'High and critical priority issues will appear here';
      case 'assigned':
        return 'Issues assigned to you will appear here';
      case 'in_progress':
        return 'Issues being worked on will appear here';
      case 'resolved':
        return 'Completed issues will appear here';
      default:
        return 'Issues will appear here when available';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
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
