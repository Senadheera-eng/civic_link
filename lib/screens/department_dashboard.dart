// screens/department_dashboard.dart (PROFESSIONAL STYLING ONLY)
import 'package:civic_link/models/notification_model.dart';
import 'package:civic_link/screens/department_notifications_screen.dart';
import 'package:civic_link/services/notification_service.dart';
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
import '../widgets/department/performance_metrics.dart';
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

      setState(() {
        _userData = userData;
        _departmentIssues = issues;
        _isLoading = false;
        _isRefreshing = false;
      });

      _calculateStatistics(issues, assignedIssues);
      _calculatePerformanceMetrics(issues);
      _subscribeToRealTimeUpdates();
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      _showErrorSnackBar('Failed to load dashboard: ${e.toString()}');
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  // Issue service methods (existing)
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

  void _subscribeToRealTimeUpdates() {
    if (_userData?.department == null) return;

    _issuesSubscription?.cancel();
    _issuesSubscription = FirebaseFirestore.instance
        .collection('issues')
        .where('category', isEqualTo: _userData!.department!)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: ModernTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: ModernTheme.primaryBlue,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Professional Header
                _buildProfessionalHeader(),

                // Statistics Cards
                _buildStatisticsCards(),

                // Filter Tabs
                _buildFilterTabs(),

                // Issues List
                _buildIssuesList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
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

  Widget _buildProfessionalHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.dashboard,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Department Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userData?.department ?? 'Loading...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showAnalytics,
                    icon: const Icon(Icons.analytics, color: Colors.white),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: _handleMenuSelection,
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'notifications',
                            child: Row(
                              children: [
                                Icon(Icons.notifications),
                                SizedBox(width: 8),
                                Text('Notifications'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(Icons.settings),
                                SizedBox(width: 8),
                                Text('Settings'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout),
                                SizedBox(width: 8),
                                Text('Sign Out'),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              if (_urgentCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.priority_high,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_urgentCount urgent issues require immediate attention',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Total Issues',
              _totalIssues.toString(),
              Icons.assignment,
              ModernTheme.primaryBlue,
              '+$_thisWeekCount this week',
            ),
            _buildStatCard(
              'Pending',
              _pendingCount.toString(),
              Icons.pending,
              Colors.orange,
              'Requires attention',
            ),
            _buildStatCard(
              'In Progress',
              _inProgressCount.toString(),
              Icons.work,
              ModernTheme.secondary,
              'Being processed',
            ),
            _buildStatCard(
              'Resolved',
              _resolvedCount.toString(),
              Icons.check_circle,
              Colors.green,
              '${_resolutionRate.toStringAsFixed(1)}% rate',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      height: 140, // Fixed height to prevent overflow
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header with icon and badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (title == 'Total Issues' && _thisWeekCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+$_thisWeekCount',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ModernTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: ModernTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {
        'key': 'pending',
        'label': 'Pending',
        'count': _pendingCount,
        'color': Colors.orange,
        'icon': Icons.pending,
      },
      {
        'key': 'in_progress',
        'label': 'In Progress',
        'count': _inProgressCount,
        'color': ModernTheme.secondary,
        'icon': Icons.work,
      },
      {
        'key': 'resolved',
        'label': 'Resolved',
        'count': _resolvedCount,
        'color': Colors.green,
        'icon': Icons.check_circle,
      },
      {
        'key': 'assigned_to_me',
        'label': 'My Tasks',
        'count': _assignedToMeCount,
        'color': ModernTheme.primaryBlue,
        'icon': Icons.person,
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          itemBuilder: (context, index) {
            final tab = tabs[index];
            final isSelected = _selectedTab == tab['key'];
            final color = tab['color'] as Color;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab['key'] as String;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: color.withOpacity(isSelected ? 1.0 : 0.3),
                    width: 2,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      color: isSelected ? Colors.white : color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.3)
                                : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (tab['count'] as int).toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIssuesList() {
    final filteredIssues = _getFilteredIssues();

    if (filteredIssues.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: ModernTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No ${_selectedTab.replaceAll('_', ' ')} issues',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ModernTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All caught up! New issues will appear here.',
                style: TextStyle(color: ModernTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final issue = filteredIssues[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildIssueCard(issue),
          );
        }, childCount: filteredIssues.length),
      ),
    );
  }

  Widget _buildIssueCard(IssueModel issue) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);
    final isAssignedToMe = issue.assignedTo == _userData?.employeeId;

    return GestureDetector(
      onTap: () => _navigateToIssueDetail(issue),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isAssignedToMe
                    ? ModernTheme.primaryBlue.withOpacity(0.3)
                    : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    issue.priority,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(issue.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (isAssignedToMe)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ASSIGNED TO YOU',
                      style: TextStyle(
                        fontSize: 8,
                        color: ModernTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  _formatTimeAgo(issue.createdAt),
                  style: const TextStyle(
                    color: ModernTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              issue.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ModernTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              issue.description,
              style: const TextStyle(
                color: ModernTheme.textSecondary,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: ModernTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    issue.address,
                    style: const TextStyle(
                      color: ModernTheme.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.person,
                  size: 16,
                  color: ModernTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  issue.userName,
                  style: const TextStyle(
                    color: ModernTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showManagementOptions,
      backgroundColor: ModernTheme.secondary,
      icon: const Icon(Icons.settings, color: Colors.white),
      label: const Text(
        'Manage',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper methods
  List<IssueModel> _getFilteredIssues() {
    switch (_selectedTab) {
      case 'pending':
        return _departmentIssues
            .where((i) => i.status.toLowerCase() == 'pending')
            .toList();
      case 'in_progress':
        return _departmentIssues
            .where((i) => i.status.toLowerCase() == 'in_progress')
            .toList();
      case 'resolved':
        return _departmentIssues
            .where((i) => i.status.toLowerCase() == 'resolved')
            .toList();
      case 'assigned_to_me':
        return _departmentIssues
            .where((i) => i.assignedTo == _userData?.employeeId)
            .toList();
      default:
        return _departmentIssues;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return ModernTheme.secondary;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return ModernTheme.textSecondary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return ModernTheme.primaryBlue;
      case 'low':
        return Colors.green;
      default:
        return ModernTheme.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'resolved':
        return 'RESOLVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
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

  void _navigateToIssueDetail(IssueModel issue) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IssueDetailScreen(issue: issue)),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'notifications':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DepartmentNotificationsScreen(),
          ),
        );
        break;
      case 'settings':
        Navigator.pushNamed(context, '/official-settings');
        break;
      case 'logout':
        _signOut();
        break;
    }
  }

  void _signOut() async {
    try {
      await _authService.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      _showErrorSnackBar('Failed to sign out');
    }
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Department Analytics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Issues: $_totalIssues'),
                const SizedBox(height: 8),
                Text('Resolution Rate: ${_resolutionRate.toStringAsFixed(1)}%'),
                const SizedBox(height: 8),
                Text(
                  'Average Resolution Time: ${_averageResolutionTime.toStringAsFixed(1)} hours',
                ),
                const SizedBox(height: 8),
                Text('This Week: $_thisWeekCount new issues'),
                const SizedBox(height: 8),
                Text('This Month: $_thisMonthCount new issues'),
                const SizedBox(height: 8),
                Text('Assigned to You: $_assignedToMeCount issues'),
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

  void _showManagementOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ModernTheme.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Management Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ModernTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(
                      Icons.assignment_ind,
                      color: ModernTheme.primaryBlue,
                    ),
                    title: const Text('Assign Issues'),
                    subtitle: const Text('Assign issues to team members'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAssignmentModal();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.update,
                      color: ModernTheme.secondary,
                    ),
                    title: const Text('Bulk Update'),
                    subtitle: const Text('Update multiple issues at once'),
                    onTap: () {
                      Navigator.pop(context);
                      _showBulkUpdateModal();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics, color: Colors.green),
                    title: const Text('View Analytics'),
                    subtitle: const Text('Department performance metrics'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAnalytics();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  void _showAssignmentModal() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Assign Issues'),
            content: const Text(
              'Assignment feature coming soon!\n\nThis will allow you to assign pending issues to specific team members.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showBulkUpdateModal() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bulk Update'),
            content: const Text(
              'Bulk update feature coming soon!\n\nThis will allow you to update status, priority, or assignments for multiple issues at once.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
