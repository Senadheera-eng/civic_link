// screens/department_dashboard.dart (COMPLETE VERSION - All Functions Working)
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
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _refreshAnimation;
  late Animation<double> _pulseAnimation;

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
  int _overdueCount = 0;
  int _newTodayCount = 0;

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
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _issuesSubscription?.cancel();
    _fadeController.dispose();
    _refreshController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_isLoading) {
      setState(() => _isRefreshing = true);
      _refreshController.forward().then((_) => _refreshController.reset());
    }

    try {
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

      final issues = await _getIssuesByDepartment(userData.department!);
      final assignedIssues = await _getAssignedIssues(userData.uid);

      _calculateStatistics(issues, assignedIssues);
      _calculatePerformanceMetrics(issues);

      setState(() {
        _userData = userData;
        _departmentIssues = issues;
        _isLoading = false;
        _isRefreshing = false;
      });

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
    _issuesSubscription?.cancel();

    if (_userData?.department == null) {
      print("⚠️ No department found, skipping real-time listener setup");
      return;
    }

    print(
      "🔔 Setting up real-time listener for department: ${_userData!.department}",
    );

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
    final today = DateTime(now.year, now.month, now.day);
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
    _newTodayCount =
        issues.where((issue) => issue.createdAt.isAfter(today)).length;

    _urgentCount =
        issues
            .where(
              (issue) =>
                  (issue.priority.toLowerCase() == 'high' ||
                      issue.priority.toLowerCase() == 'critical') &&
                  issue.status.toLowerCase() == 'pending',
            )
            .length;

    // Calculate overdue issues (pending for more than 3 days)
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    _overdueCount =
        issues
            .where(
              (issue) =>
                  issue.status.toLowerCase() == 'pending' &&
                  issue.createdAt.isBefore(threeDaysAgo),
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

  List<IssueModel> get _filteredIssues {
    switch (_selectedTab) {
      case 'pending':
        return _departmentIssues
            .where((issue) => issue.status.toLowerCase() == 'pending')
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
      case 'in_progress':
        return _departmentIssues
            .where((issue) => issue.status.toLowerCase() == 'in_progress')
            .toList();
      case 'resolved':
        return _departmentIssues
            .where((issue) => issue.status.toLowerCase() == 'resolved')
            .toList();
      case 'overdue':
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        return _departmentIssues
            .where(
              (issue) =>
                  issue.status.toLowerCase() == 'pending' &&
                  issue.createdAt.isBefore(threeDaysAgo),
            )
            .toList();
      case 'new_today':
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        return _departmentIssues
            .where((issue) => issue.createdAt.isAfter(today))
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

  // MANAGEMENT OPTIONS WITH WORKING BULK ACTIONS AND ISSUE ASSIGNMENT
  void _showManagementOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (modalContext) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: ModernTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernTheme.textTertiary,
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
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildManagementOption(
                      context,
                      Icons.analytics,
                      'Department Analytics',
                      'View detailed performance metrics',
                      () {
                        Navigator.pop(context);
                        _showAnalytics();
                      },
                    ),
                    _buildManagementOption(
                      context,
                      Icons.assignment_turned_in,
                      'Bulk Actions',
                      'Update multiple issues at once',
                      () {
                        Navigator.pop(context);
                        _showBulkActions();
                      },
                    ),
                    _buildManagementOption(
                      context,
                      Icons.schedule,
                      'Issue Assignment',
                      'Assign issues to team members',
                      () {
                        Navigator.pop(context);
                        _showIssueAssignment();
                      },
                    ),
                    _buildManagementOption(
                      context,
                      Icons.people,
                      'Team Management',
                      'Manage department team',
                      () {
                        Navigator.pop(context);
                        _showTeamManagement();
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildManagementOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return Container(
      margin: isLast ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ModernTheme.primaryBlue, ModernTheme.accent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ModernTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: ModernTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: ModernTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WORKING BULK ACTIONS FUNCTION
  void _showBulkActions() {
    final pendingIssues =
        _departmentIssues
            .where((issue) => issue.status.toLowerCase() == 'pending')
            .toList();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ModernTheme.primaryBlue, ModernTheme.accent],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Bulk Actions'),
              ],
            ),
            content:
                pendingIssues.isEmpty
                    ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ModernTheme.textSecondary,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No pending issues available for bulk actions',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_turned_in,
                          color: ModernTheme.primaryBlue,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${pendingIssues.length} pending issues available for bulk actions',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ModernTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: ModernTheme.primaryBlue,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This will mark all pending issues as "In Progress"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ModernTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            actions:
                pendingIssues.isEmpty
                    ? [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ]
                    : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performBulkStatusUpdate(pendingIssues);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ModernTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Mark All In Progress'),
                      ),
                    ],
          ),
    );
  }

  // WORKING ISSUE ASSIGNMENT FUNCTION
  void _showIssueAssignment() {
    final unassignedIssues =
        _departmentIssues
            .where(
              (i) =>
                  i.status.toLowerCase() == 'pending' &&
                  (i.assignedTo == null || i.assignedTo!.isEmpty),
            )
            .toList();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ModernTheme.primaryBlue, ModernTheme.accent],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Issue Assignment'),
              ],
            ),
            content:
                unassignedIssues.isEmpty
                    ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_turned_in,
                          color: ModernTheme.success,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No unassigned issues available',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'All pending issues are already assigned',
                          style: TextStyle(
                            fontSize: 12,
                            color: ModernTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          color: ModernTheme.primaryBlue,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${unassignedIssues.length} unassigned issues available',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ModernTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: ModernTheme.primaryBlue,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This will assign all unassigned issues to you',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ModernTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            actions:
                unassignedIssues.isEmpty
                    ? [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ]
                    : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _assignIssuesToSelf(unassignedIssues);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ModernTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Assign All to Me'),
                      ),
                    ],
          ),
    );
  }

  // BULK STATUS UPDATE IMPLEMENTATION
  Future<void> _performBulkStatusUpdate(List<IssueModel> issues) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final issue in issues) {
        final docRef = FirebaseFirestore.instance
            .collection('issues')
            .doc(issue.id);
        batch.update(docRef, {
          'status': 'in_progress',
          'adminNotes':
              'Bulk updated to In Progress by ${_userData?.displayName ?? 'Department Official'}',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _userData?.uid,
        });
      }
      await batch.commit();

      _showSuccessSnackBar('${issues.length} issues updated to In Progress');
      await _loadData();
    } catch (e) {
      _showErrorSnackBar('Failed to update issues: $e');
    }
  }

  // ISSUE ASSIGNMENT IMPLEMENTATION
  Future<void> _assignIssuesToSelf(List<IssueModel> issues) async {
    if (_userData == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final issue in issues) {
        final docRef = FirebaseFirestore.instance
            .collection('issues')
            .doc(issue.id);
        batch.update(docRef, {
          'assignedTo': _userData!.uid,
          'status': 'in_progress',
          'adminNotes':
              'Self-assigned by ${_userData!.displayName ?? _userData!.email}',
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      _showSuccessSnackBar(
        '${issues.length} issues assigned to you successfully',
      );
      await _loadData();
    } catch (e) {
      _showErrorSnackBar('Failed to assign issues: $e');
    }
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

  void _showTeamManagement() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Team Management"),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 250,
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .where(
                                'department',
                                isEqualTo: _userData?.department,
                              )
                              .snapshots(),
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("No team members found."),
                          );
                        }

                        final users = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (ctx, i) {
                            final user = users[i];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(user['displayName'] ?? 'Unnamed'),
                              subtitle: Text(
                                'Email: ${user['email'] ?? 'N/A'}',
                              ),
                              trailing:
                                  user.id == _userData?.uid
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ModernTheme.primaryBlue,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'You',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                      : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  // PRIORITY TRIAGE SECTION AND OTHER UI METHODS
  Widget _buildPriorityTriageSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Issue Triage Center',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: ModernTheme.successGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Live Updates',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              _buildTriageCard(
                'Urgent Queue',
                _urgentCount,
                Icons.priority_high,
                ModernTheme.errorGradient,
                'urgent',
                'Critical & High priority',
              ),
              _buildTriageCard(
                'New Today',
                _newTodayCount,
                Icons.fiber_new,
                ModernTheme.primaryGradient,
                'new_today',
                'Reported today',
              ),
              _buildTriageCard(
                'Assigned to Me',
                _assignedToMeCount,
                Icons.assignment_ind,
                ModernTheme.accentGradient,
                'assigned',
                'Your active tasks',
              ),
              _buildTriageCard(
                'Overdue',
                _overdueCount,
                Icons.schedule,
                ModernTheme.warningGradient,
                'overdue',
                'Pending > 3 days',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'In Progress',
                  _inProgressCount,
                  ModernTheme.accent,
                  'in_progress',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'Resolved',
                  _resolvedCount,
                  ModernTheme.success,
                  'resolved',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'Pending',
                  _pendingCount,
                  ModernTheme.warning,
                  'pending',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriageCard(
    String title,
    int count,
    IconData icon,
    LinearGradient gradient,
    String filterKey,
    String subtitle,
  ) {
    final isSelected = _selectedTab == filterKey;
    final isUrgent = filterKey == 'urgent' && count > 0;

    return ScaleTransition(
      scale: isUrgent ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = filterKey),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(
                    isSelected ? 0.6 : 0.3,
                  ),
                  blurRadius: isSelected ? 20 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border:
                  isSelected
                      ? Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      )
                      : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
    String title,
    int count,
    Color color,
    String filterKey,
  ) {
    final isSelected = _selectedTab == filterKey;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = filterKey),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ISSUES LIST SECTION - THE MISSING PART!
  Widget _buildIssuesSliver() {
    final filteredIssues = _filteredIssues;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getFilterDisplayName(_selectedTab),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ModernTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredIssues.length} issues',
                    style: const TextStyle(
                      color: ModernTheme.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filteredIssues.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredIssues.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final issue = filteredIssues[index];
                  return _buildIssueCard(issue);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            _getEmptyStateIcon(_selectedTab),
            size: 64,
            color: ModernTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_getFilterDisplayName(_selectedTab).toLowerCase()} found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ModernTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateMessage(_selectedTab),
            style: const TextStyle(
              fontSize: 14,
              color: ModernTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(IssueModel issue) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToIssueDetail(issue),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ModernTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ModernTheme.textTertiary.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${issue.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ModernTheme.textTertiary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getStatusText(issue.status),
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: ModernTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2, // Give location more space
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
                  const SizedBox(width: 12), // Reduced from 16
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: ModernTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    // Changed from no wrapper to Flexible
                    child: Text(
                      _formatTimeAgo(issue.createdAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: ModernTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (issue.assignedTo != null && issue.assignedTo!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: ModernTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      // Wrap the text in Expanded
                      child: Text(
                        'Assigned to: ${issue.assignedTo == _userData?.uid ? 'You' : issue.assignedTo}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: ModernTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Add overflow handling
                        maxLines: 1, // Limit to one line
                      ),
                    ),
                  ],
                ),
              ],
              if (issue.adminNotes != null && issue.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ModernTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ModernTheme.primaryBlue.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: ModernTheme.primaryBlue,
                      ),
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
        ),
      ),
    );
  }

  void _navigateToIssueDetail(IssueModel issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OfficialIssueDetailScreen(
              issue: issue, // Only pass the issue parameter
            ),
      ),
    ).then((_) => _loadData()); // Refresh data when returning
  }

  // ALL REMAINING HELPER METHODS
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

  // Helper methods for UI
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

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'urgent':
        return 'Urgent Issues';
      case 'new_today':
        return 'New Today';
      case 'assigned':
        return 'Assigned to Me';
      case 'overdue':
        return 'Overdue Issues';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved Issues';
      case 'pending':
        return 'Pending Issues';
      default:
        return 'All Issues';
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
        return Icons.work_outline;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'overdue':
        return Icons.schedule;
      case 'new_today':
        return Icons.fiber_new;
      default:
        return Icons.inbox;
    }
  }

  String _getEmptyStateMessage(String tab) {
    switch (tab) {
      case 'pending':
        return 'All issues have been addressed or assigned';
      case 'urgent':
        return 'No critical or high priority issues at the moment';
      case 'assigned':
        return 'No issues are currently assigned to you';
      case 'in_progress':
        return 'No issues are currently being worked on';
      case 'resolved':
        return 'No issues have been resolved yet';
      case 'overdue':
        return 'Great! No overdue issues';
      case 'new_today':
        return 'No new issues reported today';
      default:
        return 'No issues found';
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
                  'Loading Department Dashboard...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Fetching live issue data and notifications',
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
                          _buildPriorityTriageSection(),
                          PerformanceMetrics(
                            resolutionRate: _resolutionRate,
                            averageResolutionTime: _averageResolutionTime,
                            assignedToMeCount: _assignedToMeCount,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // This is the key addition - the issues list!
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
}

// Add this ModernCard widget if it doesn't exist in your theme
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const ModernCard({Key? key, required this.child, this.margin, this.padding})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
