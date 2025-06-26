// screens/department_dashboard.dart (COMPLETE FIXED VERSION)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/issue_service.dart';
import '../models/user_model.dart';
import '../models/issue_model.dart';
import '../theme/modern_theme.dart';
import 'issue_detail_screen.dart';

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
        // User will be redirected by AuthWrapper
        return;
      }

      // Load department issues
      final issues = await _getIssuesByDepartment(userData.department!);

      // Load assigned issues
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
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      _showErrorSnackBar('Failed to load dashboard data: ${e.toString()}');
    }
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

    // Count urgent issues (High and Critical priority, Pending status)
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
      // Calculate average resolution time
      final totalHours = resolvedIssues.fold<double>(0, (sum, issue) {
        if (issue.updatedAt != null) {
          return sum +
              issue.updatedAt!.difference(issue.createdAt).inHours.toDouble();
        }
        return sum;
      });
      _averageResolutionTime = totalHours / resolvedIssues.length;

      // Calculate resolution rate
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
      Navigator.of(context).pop(); // Close loading dialog
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('Sign out failed: $e');
    }
  }

  void _showManagementOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
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
                _buildManagementOption(
                  Icons.analytics,
                  'Department Analytics',
                  'View detailed performance metrics',
                  () {
                    Navigator.pop(context);
                    _showAnalytics();
                  },
                ),
                _buildManagementOption(
                  Icons.assignment_turned_in,
                  'Bulk Actions',
                  'Update multiple issues at once',
                  () {
                    Navigator.pop(context);
                    _showBulkActions();
                  },
                ),
                _buildManagementOption(
                  Icons.schedule,
                  'Issue Assignment',
                  'Assign issues to team members',
                  () {
                    Navigator.pop(context);
                    _showAssignmentOptions();
                  },
                ),
                _buildManagementOption(
                  Icons.people,
                  'Team Management',
                  'Manage department team',
                  () {
                    Navigator.pop(context);
                    _showSuccessSnackBar('Team management coming soon!');
                  },
                ),
                _buildManagementOption(
                  Icons.settings,
                  'Department Settings',
                  'Configure department preferences',
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildManagementOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: ModernTheme.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: ModernTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: ModernTheme.textSecondary, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: ModernTheme.textSecondary,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showBulkActions() {
    final pendingIssues =
        _departmentIssues
            .where((issue) => issue.status.toLowerCase() == 'pending')
            .toList();

    if (pendingIssues.isEmpty) {
      _showErrorSnackBar('No pending issues available for bulk actions');
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Bulk Actions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${pendingIssues.length} pending issues available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performBulkStatusUpdate(
                      pendingIssues.map((e) => e.id).toList(),
                      'in_progress',
                      'Bulk updated to In Progress by ${_userData?.shortDisplayName}',
                    );
                  },
                  child: const Text('Mark All as In Progress'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showAssignmentOptions() {
    final unassignedIssues =
        _departmentIssues
            .where(
              (issue) =>
                  issue.status.toLowerCase() == 'pending' &&
                  (issue.assignedTo == null || issue.assignedTo!.isEmpty),
            )
            .toList();

    if (unassignedIssues.isEmpty) {
      _showErrorSnackBar('No unassigned issues available');
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Issue Assignment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${unassignedIssues.length} unassigned issues'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _assignIssuesToSelf(unassignedIssues);
                  },
                  child: const Text('Assign All to Myself'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _performBulkStatusUpdate(
    List<String> issueIds,
    String newStatus,
    String notes,
  ) async {
    try {
      await _bulkUpdateIssues(
        issueIds: issueIds,
        newStatus: newStatus,
        notes: notes,
      );
      _showSuccessSnackBar('${issueIds.length} issues updated successfully');
      _loadData();
    } catch (e) {
      _showErrorSnackBar('Failed to update issues: $e');
    }
  }

  Future<void> _assignIssuesToSelf(List<IssueModel> issues) async {
    if (_userData == null) return;

    try {
      for (final issue in issues) {
        await _assignIssue(
          issueId: issue.id,
          assignedToId: _userData!.uid,
          assignedToName: _userData!.displayName,
          notes: 'Self-assigned by ${_userData!.shortDisplayName}',
        );
      }
      _showSuccessSnackBar('${issues.length} issues assigned to you');
      _loadData();
    } catch (e) {
      _showErrorSnackBar('Failed to assign issues: $e');
    }
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: ModernTheme.accentGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_userData?.department ?? "Department"} Analytics',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: ModernTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Total Issues',
                          _totalIssues.toString(),
                          Icons.assignment,
                          ModernTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Resolution Rate',
                          '${_resolutionRate.toStringAsFixed(1)}%',
                          Icons.check_circle,
                          ModernTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          'Avg. Time',
                          '${_averageResolutionTime.toStringAsFixed(1)}h',
                          Icons.timer,
                          ModernTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'This Month',
                          _thisMonthCount.toString(),
                          Icons.calendar_month,
                          ModernTheme.warning,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Detailed Analytics
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detailed Analysis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ModernTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildAnalyticsItem(
                            'Total Issues Handled',
                            _totalIssues.toString(),
                          ),
                          _buildAnalyticsItem(
                            'Pending Issues',
                            _pendingCount.toString(),
                          ),
                          _buildAnalyticsItem(
                            'In Progress',
                            _inProgressCount.toString(),
                          ),
                          _buildAnalyticsItem(
                            'Resolved Issues',
                            _resolvedCount.toString(),
                          ),
                          _buildAnalyticsItem(
                            'Rejected Issues',
                            _rejectedCount.toString(),
                          ),
                          _buildAnalyticsItem(
                            'Urgent Issues',
                            _urgentCount.toString(),
                          ),
                          _buildAnalyticsItem(
                            'Assigned to Me',
                            _assignedToMeCount.toString(),
                          ),
                          _buildAnalyticsItem(
                            'This Week',
                            _thisWeekCount.toString(),
                          ),
                          _buildAnalyticsItem(
                            'This Month',
                            _thisMonthCount.toString(),
                          ),
                          _buildAnalyticsItem(
                            'Resolution Rate',
                            '${_resolutionRate.toStringAsFixed(1)}%',
                          ),
                          _buildAnalyticsItem(
                            'Average Resolution Time',
                            '${_averageResolutionTime.toStringAsFixed(1)} hours',
                          ),

                          const SizedBox(height: 20),

                          // Performance Insights
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ModernTheme.primaryBlue.withOpacity(0.1),
                                  ModernTheme.accent.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ModernTheme.primaryBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: ModernTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.insights,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Performance Insights',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: ModernTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildInsight(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _exportAnalytics();
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Export'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: ModernTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsight() {
    String insightText = 'Great performance! ';
    IconData insightIcon = Icons.trending_up;
    Color insightColor = ModernTheme.success;

    if (_resolutionRate >= 80) {
      insightText +=
          'Your department has an excellent resolution rate of ${_resolutionRate.toStringAsFixed(1)}%.';
    } else if (_resolutionRate >= 60) {
      insightText +=
          'Your resolution rate of ${_resolutionRate.toStringAsFixed(1)}% is good but can be improved.';
      insightColor = ModernTheme.warning;
      insightIcon = Icons.trending_flat;
    } else {
      insightText =
          'Focus needed! Your resolution rate of ${_resolutionRate.toStringAsFixed(1)}% needs improvement.';
      insightColor = ModernTheme.error;
      insightIcon = Icons.trending_down;
    }

    if (_urgentCount > 0) {
      insightText +=
          ' You have $_urgentCount urgent issues requiring immediate attention.';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(insightIcon, color: insightColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            insightText,
            style: const TextStyle(
              fontSize: 14,
              color: ModernTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _exportAnalytics() {
    _showSuccessSnackBar(
      'Analytics export initiated! You will receive an email with the detailed report shortly.',
    );
  }

  // Issue service methods for department officials
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

  Future<void> _bulkUpdateIssues({
    required List<String> issueIds,
    required String newStatus,
    required String notes,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (String issueId in issueIds) {
        final docRef = FirebaseFirestore.instance
            .collection('issues')
            .doc(issueId);
        batch.update(docRef, {
          'status': newStatus,
          'adminNotes': notes,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _userData?.uid,
        });
      }

      await batch.commit();
      print('Bulk update completed for ${issueIds.length} issues');
    } catch (e) {
      print('Error in bulk update: $e');
      throw 'Failed to update issues: $e';
    }
  }

  Future<void> _assignIssue({
    required String issueId,
    required String assignedToId,
    required String assignedToName,
    required String notes,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
            'assignedTo': assignedToId,
            'assignedToName': assignedToName,
            'adminNotes': notes,
            'status': 'in_progress',
            'updatedAt': FieldValue.serverTimestamp(),
            'assignedAt': FieldValue.serverTimestamp(),
            'assignedBy': _userData?.uid,
          });

      print('Issue assigned successfully');
    } catch (e) {
      print('Error assigning issue: $e');
      throw 'Failed to assign issue: $e';
    }
  }

  // Helper methods
  IconData _getDepartmentIcon(String department) {
    final departmentInfo = Departments.getByName(department);
    switch (departmentInfo?['icon']) {
      case 'construction':
        return Icons.construction;
      case 'water_drop':
        return Icons.water_drop;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'security':
        return Icons.security;
      case 'delete':
        return Icons.delete;
      case 'park':
        return Icons.park;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'business':
        return Icons.business;
      case 'traffic':
        return Icons.traffic;
      case 'eco':
        return Icons.eco;
      default:
        return Icons.dashboard;
    }
  }

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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: ModernTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
        ],
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
                          if (_isRefreshing) _buildRefreshIndicator(),
                          _buildDepartmentStats(),
                          _buildPerformanceMetrics(),
                          _buildTabBar(),
                          Expanded(child: _buildIssuesList()),
                        ],
                      ),
                    ),
                  ),
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

  Widget _buildRefreshIndicator() {
    return RotationTransition(
      turns: _refreshAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, color: ModernTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Refreshing data...',
              style: TextStyle(
                color: ModernTheme.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final departmentInfo = Departments.getByName(_userData?.department ?? '');
    final departmentColor =
        departmentInfo?['color'] != null
            ? Color(departmentInfo!['color'])
            : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getDepartmentIcon(_userData?.department ?? ''),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?.department ?? 'Department',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Official Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.more_vert, color: Colors.white),
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      _showProfile();
                      break;
                    case 'settings':
                      Navigator.pushNamed(context, '/settings');
                      break;
                    case 'analytics':
                      _showAnalytics();
                      break;
                    case 'logout':
                      _signOut();
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person),
                            SizedBox(width: 12),
                            Text('Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'analytics',
                        child: Row(
                          children: [
                            Icon(Icons.analytics),
                            SizedBox(width: 12),
                            Text('Analytics'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings),
                            SizedBox(width: 12),
                            Text('Settings'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Logout', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Welcome message with verification status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: departmentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _userData?.isVerified == true
                        ? Icons.verified
                        : Icons.pending,
                    color: departmentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${_userData?.shortDisplayName ?? 'Official'}!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ID: ${_userData?.employeeId ?? 'N/A'} • ${_userData?.accountStatus ?? 'Active'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_urgentCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ModernTheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_urgentCount URGENT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Department Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: ModernTheme.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Live',
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
          // Main stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Issues',
                  _totalIssues.toString(),
                  Icons.assignment,
                  ModernTheme.primaryBlue,
                  subtitle: 'All time',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'This Week',
                  _thisWeekCount.toString(),
                  Icons.trending_up,
                  ModernTheme.info,
                  subtitle: 'New issues',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status breakdown
          Row(
            children: [
              Expanded(
                child: _buildSmallStatCard(
                  'Pending',
                  _pendingCount.toString(),
                  ModernTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStatCard(
                  'In Progress',
                  _inProgressCount.toString(),
                  ModernTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStatCard(
                  'Resolved',
                  _resolvedCount.toString(),
                  ModernTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStatCard(
                  'Urgent',
                  _urgentCount.toString(),
                  ModernTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModernTheme.accent.withOpacity(0.1),
            ModernTheme.primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernTheme.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.speed, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Performance Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Resolution Rate',
                  '${_resolutionRate.toStringAsFixed(1)}%',
                  Icons.check_circle_outline,
                  ModernTheme.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: ModernTheme.textTertiary.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Avg. Resolution',
                  '${_averageResolutionTime.toStringAsFixed(1)}h',
                  Icons.timer_outlined,
                  ModernTheme.accent,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: ModernTheme.textTertiary.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Assigned to Me',
                  _assignedToMeCount.toString(),
                  Icons.person_pin_outlined,
                  ModernTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: ModernTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return ModernCard(
      color: color.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ModernTheme.textSecondary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ModernTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      {
        'key': 'pending',
        'label': 'Pending',
        'count': _pendingCount,
        'color': ModernTheme.warning,
      },
      {
        'key': 'urgent',
        'label': 'Urgent',
        'count': _urgentCount,
        'color': ModernTheme.error,
      },
      {
        'key': 'assigned',
        'label': 'Assigned',
        'count': _assignedToMeCount,
        'color': ModernTheme.primaryBlue,
      },
      {
        'key': 'in_progress',
        'label': 'In Progress',
        'count': _inProgressCount,
        'color': ModernTheme.accent,
      },
      {
        'key': 'resolved',
        'label': 'Resolved',
        'count': _resolvedCount,
        'color': ModernTheme.success,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children:
              tabs.map((tab) {
                final isSelected = _selectedTab == tab['key'];
                final color = tab['color'] as Color;
                return GestureDetector(
                  onTap:
                      () => setState(() => _selectedTab = tab['key'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? LinearGradient(
                                colors: [color, color.withOpacity(0.8)],
                              )
                              : null,
                      color: isSelected ? null : ModernTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.transparent
                                : color.withOpacity(0.3),
                        width: 1.5,
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
                        Text(
                          tab['label'] as String,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : ModernTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (tab['count'] as int).toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildIssuesList() {
    final filteredIssues = _filteredIssues;

    if (filteredIssues.isEmpty) {
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredIssues.length,
      itemBuilder: (context, index) {
        final issue = filteredIssues[index];
        return _buildIssueCard(issue, index);
      },
    );
  }

  Widget _buildIssueCard(IssueModel issue, int index) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);
    final isUrgent =
        issue.priority.toLowerCase() == 'high' ||
        issue.priority.toLowerCase() == 'critical';
    final isAssignedToMe = issue.assignedTo == _userData?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfficialIssueDetailScreen(issue: issue),
            ),
          ).then((_) => _loadData()); // Refresh when returning
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
                              style: TextStyle(
                                color: ModernTheme.textSecondary,
                              ),
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
                  border: Border.all(
                    color: ModernTheme.accent.withOpacity(0.2),
                  ),
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
      ),
    );
  }

  void _showProfile() {
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
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Official Profile'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileItem('Name', _userData?.fullName ?? 'N/A'),
                _buildProfileItem('Email', _userData?.email ?? 'N/A'),
                _buildProfileItem('Department', _userData?.department ?? 'N/A'),
                _buildProfileItem(
                  'Employee ID',
                  _userData?.employeeId ?? 'N/A',
                ),
                _buildProfileItem('Status', _userData?.accountStatus ?? 'N/A'),
                _buildProfileItem(
                  'Member Since',
                  _userData?.createdAt != null
                      ? _formatDate(_userData!.createdAt!)
                      : 'N/A',
                ),
                if (_userData?.verifiedAt != null)
                  _buildProfileItem(
                    'Verified On',
                    _formatDate(_userData!.verifiedAt!),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
                child: const Text('Edit Profile'),
              ),
            ],
          ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ModernTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: ModernTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// Official Issue Detail Screen (enhanced version for officials)
class OfficialIssueDetailScreen extends StatefulWidget {
  final IssueModel issue;

  const OfficialIssueDetailScreen({Key? key, required this.issue})
    : super(key: key);

  @override
  State<OfficialIssueDetailScreen> createState() =>
      _OfficialIssueDetailScreenState();
}

class _OfficialIssueDetailScreenState extends State<OfficialIssueDetailScreen> {
  final IssueService _issueService = IssueService();
  final _notesController = TextEditingController();

  bool _isUpdating = false;
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.issue.status;
    _notesController.text = widget.issue.adminNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateIssueStatus() async {
    if (_selectedStatus == widget.issue.status &&
        _notesController.text.trim() == (widget.issue.adminNotes ?? '')) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await _issueService.updateIssueStatus(
        issueId: widget.issue.id,
        newStatus: _selectedStatus,
        adminNotes: _notesController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Issue updated successfully'),
            ],
          ),
          backgroundColor: ModernTheme.success,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Update failed: $e')),
            ],
          ),
          backgroundColor: ModernTheme.error,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Management'),
        backgroundColor: ModernTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateIssueStatus,
              child: const Text(
                'Update',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Issue details
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.issue.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ModernTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.issue.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: ModernTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ModernStatusChip(
                        text: widget.issue.priority,
                        color: _getPriorityColor(widget.issue.priority),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Reported by ${widget.issue.userName}',
                        style: const TextStyle(
                          color: ModernTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status Update Section
            const Text(
              'Update Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ModernTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ModernTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children:
                        ['pending', 'in_progress', 'resolved', 'rejected'].map((
                          status,
                        ) {
                          final isSelected = _selectedStatus == status;
                          final color = _getStatusColor(status);

                          return GestureDetector(
                            onTap:
                                () => setState(() => _selectedStatus = status),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient:
                                    isSelected
                                        ? LinearGradient(
                                          colors: [
                                            color,
                                            color.withOpacity(0.8),
                                          ],
                                        )
                                        : null,
                                color: isSelected ? null : ModernTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.transparent
                                          : color.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Official Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ModernTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add notes about this issue...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GradientButton(
                    text: _isUpdating ? 'Updating...' : 'Update Issue',
                    onPressed: _isUpdating ? null : _updateIssueStatus,
                    icon: Icons.update,
                    isLoading: _isUpdating,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
}
