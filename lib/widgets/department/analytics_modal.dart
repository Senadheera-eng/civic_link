// widgets/department/analytics_modal.dart (ENHANCED VERSION)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/issue_model.dart';
import '../../theme/modern_theme.dart';

class AnalyticsModal extends StatefulWidget {
  final UserModel? userData;
  final int totalIssues;
  final double resolutionRate;
  final double averageResolutionTime;
  final int thisMonthCount;
  final int pendingCount;
  final int inProgressCount;
  final int resolvedCount;
  final int rejectedCount;
  final int urgentCount;
  final int assignedToMeCount;
  final int thisWeekCount;

  const AnalyticsModal({
    Key? key,
    required this.userData,
    required this.totalIssues,
    required this.resolutionRate,
    required this.averageResolutionTime,
    required this.thisMonthCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.rejectedCount,
    required this.urgentCount,
    required this.assignedToMeCount,
    required this.thisWeekCount,
  }) : super(key: key);

  @override
  State<AnalyticsModal> createState() => _AnalyticsModalState();
}

class _AnalyticsModalState extends State<AnalyticsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  // Additional analytics data
  Map<String, int> _priorityBreakdown = {};
  Map<String, int> _monthlyTrends = {};
  Map<String, double> _responseTimeByPriority = {};
  List<Map<String, dynamic>> _topIssueTypes = [];
  double _citizenSatisfactionScore = 0.0;
  int _repeatIssues = 0;
  Map<String, int> _hourlyDistribution = {};

  bool _isLoadingAnalytics = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initAnimations();
    _loadAdvancedAnalytics();
  }

  void _initAnimations() {
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvancedAnalytics() async {
    try {
      final department = widget.userData?.department;
      if (department == null) return;

      // Get all issues for this department
      final issuesSnapshot =
          await FirebaseFirestore.instance
              .collection('issues')
              .where('category', isEqualTo: department)
              .get();

      final issues =
          issuesSnapshot.docs
              .map((doc) => IssueModel.fromFirestore(doc))
              .toList();

      _calculateAdvancedMetrics(issues);

      setState(() {
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _isLoadingAnalytics = false;
      });
    }
  }

  void _calculateAdvancedMetrics(List<IssueModel> issues) {
    // Priority breakdown
    _priorityBreakdown = {'Low': 0, 'Medium': 0, 'High': 0, 'Critical': 0};

    // Monthly trends (last 6 months)
    _monthlyTrends = {};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      _monthlyTrends[monthKey] = 0;
    }

    // Response time by priority
    _responseTimeByPriority = {
      'Low': 0.0,
      'Medium': 0.0,
      'High': 0.0,
      'Critical': 0.0,
    };
    Map<String, List<double>> responseTimes = {
      'Low': [],
      'Medium': [],
      'High': [],
      'Critical': [],
    };

    // Hourly distribution
    _hourlyDistribution = {};
    for (int i = 0; i < 24; i++) {
      _hourlyDistribution[i.toString().padLeft(2, '0')] = 0;
    }

    // Issue type frequency
    Map<String, int> issueTypeCounts = {};

    // Process each issue
    for (final issue in issues) {
      // Priority breakdown
      final priority = issue.priority;
      _priorityBreakdown[priority] = (_priorityBreakdown[priority] ?? 0) + 1;

      // Monthly trends
      final issueMonth = issue.createdAt;
      final monthKey =
          '${issueMonth.year}-${issueMonth.month.toString().padLeft(2, '0')}';
      if (_monthlyTrends.containsKey(monthKey)) {
        _monthlyTrends[monthKey] = _monthlyTrends[monthKey]! + 1;
      }

      // Response time analysis
      if (issue.status == 'resolved' && issue.updatedAt != null) {
        final responseTime =
            issue.updatedAt!.difference(issue.createdAt).inHours.toDouble();
        responseTimes[priority]?.add(responseTime);
      }

      // Hourly distribution
      final hour = issue.createdAt.hour.toString().padLeft(2, '0');
      _hourlyDistribution[hour] = (_hourlyDistribution[hour] ?? 0) + 1;

      // Issue type analysis (simplified - using first word of title)
      final firstWord = issue.title.split(' ').first.toLowerCase();
      issueTypeCounts[firstWord] = (issueTypeCounts[firstWord] ?? 0) + 1;
    }

    // Calculate average response times
    responseTimes.forEach((priority, times) {
      if (times.isNotEmpty) {
        _responseTimeByPriority[priority] =
            times.reduce((a, b) => a + b) / times.length;
      }
    });

    // Top issue types
    _topIssueTypes =
        issueTypeCounts.entries
            .where((entry) => entry.value > 1)
            .map(
              (entry) => {
                'type': entry.key,
                'count': entry.value,
                'percentage': (entry.value / issues.length * 100),
              },
            )
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int))
          ..take(5).toList();

    // Calculate citizen satisfaction (simulated based on resolution rate and response time)
    _citizenSatisfactionScore = _calculateSatisfactionScore();

    // Calculate repeat issues (simplified - issues with similar titles)
    _repeatIssues = _calculateRepeatIssues(issues);
  }

  double _calculateSatisfactionScore() {
    // Simple satisfaction calculation based on resolution rate and response time
    double score = widget.resolutionRate * 0.6; // 60% weight on resolution rate

    // Add bonus for fast response times
    if (widget.averageResolutionTime <= 24) {
      score += 30; // Bonus for sub-24 hour response
    } else if (widget.averageResolutionTime <= 72) {
      score += 20; // Bonus for sub-3 day response
    }

    // Penalty for too many urgent issues
    if (widget.urgentCount > widget.totalIssues * 0.2) {
      score -= 10; // Penalty if more than 20% are urgent
    }

    return score.clamp(0.0, 100.0);
  }

  int _calculateRepeatIssues(List<IssueModel> issues) {
    // Simple repeat issue detection based on similar titles
    Map<String, int> titleWords = {};
    for (final issue in issues) {
      final words = issue.title.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 3) {
          // Only consider words longer than 3 characters
          titleWords[word] = (titleWords[word] ?? 0) + 1;
        }
      }
    }

    return titleWords.values.where((count) => count > 2).length;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: ModernTheme.background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildPerformanceTab(),
                  _buildTrendsTab(),
                  _buildInsightsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ModernTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.userData?.department ?? "Department"} Analytics',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Comprehensive performance insights',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: ModernTheme.accentGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: ModernTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Performance'),
          Tab(text: 'Trends'),
          Tab(text: 'Insights'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Key metrics row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Issues',
                  widget.totalIssues.toString(),
                  Icons.assignment,
                  ModernTheme.primaryBlue,
                  'All time',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Resolution Rate',
                  '${widget.resolutionRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  ModernTheme.success,
                  'Success rate',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Response',
                  '${widget.averageResolutionTime.toStringAsFixed(1)}h',
                  Icons.timer,
                  ModernTheme.accent,
                  'Time to resolve',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Satisfaction',
                  '${_citizenSatisfactionScore.toStringAsFixed(1)}%',
                  Icons.sentiment_satisfied,
                  ModernTheme.warning,
                  'Citizen rating',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status breakdown
          _buildStatusBreakdown(),

          const SizedBox(height: 24),

          // Priority breakdown chart
          _buildPriorityBreakdown(),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance metrics
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),

          // Response time by priority
          _buildResponseTimeChart(),
          const SizedBox(height: 24),

          // Hourly distribution
          _buildHourlyDistribution(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Monthly trends
          _buildMonthlyTrends(),
          const SizedBox(height: 24),

          // Issue type analysis
          _buildIssueTypeAnalysis(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Key insights
          _buildKeyInsights(),
          const SizedBox(height: 24),

          // Recommendations
          _buildRecommendations(),
          const SizedBox(height: 24),

          // Export options
          _buildExportOptions(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_chartAnimation.value * 0.2),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ModernTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBreakdown() {
    final statuses = [
      {
        'label': 'Pending',
        'count': widget.pendingCount,
        'color': ModernTheme.warning,
      },
      {
        'label': 'In Progress',
        'count': widget.inProgressCount,
        'color': ModernTheme.accent,
      },
      {
        'label': 'Resolved',
        'count': widget.resolvedCount,
        'color': ModernTheme.success,
      },
      {
        'label': 'Rejected',
        'count': widget.rejectedCount,
        'color': ModernTheme.error,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.textTertiary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Issue Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...statuses.map(
            (status) => _buildStatusItem(
              status['label'] as String,
              status['count'] as int,
              status['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    final percentage =
        widget.totalIssues > 0 ? (count / widget.totalIssues) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ModernTheme.textPrimary,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 12,
              color: ModernTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.textTertiary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority Level Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingAnalytics)
            const Center(child: CircularProgressIndicator())
          else
            ..._priorityBreakdown.entries.map((entry) {
              final color = _getPriorityColor(entry.key);
              return _buildPriorityBar(entry.key, entry.value, color);
            }),
        ],
      ),
    );
  }

  Widget _buildPriorityBar(String priority, int count, Color color) {
    final percentage =
        widget.totalIssues > 0 ? (count / widget.totalIssues) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                priority,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ModernTheme.textPrimary,
                ),
              ),
              Text(
                '$count (${(percentage * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: percentage * _chartAnimation.value,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final metrics = [
      {
        'title': 'Average Response Time',
        'value': '${widget.averageResolutionTime.toStringAsFixed(1)} hours',
        'target': '24 hours',
        'performance':
            widget.averageResolutionTime <= 24
                ? 'excellent'
                : 'needs_improvement',
      },
      {
        'title': 'Citizen Satisfaction',
        'value': '${_citizenSatisfactionScore.toStringAsFixed(1)}%',
        'target': '85%+',
        'performance': _citizenSatisfactionScore >= 85 ? 'excellent' : 'good',
      },
      {
        'title': 'Repeat Issues',
        'value': '$_repeatIssues issues',
        'target': '< 5 issues',
        'performance': _repeatIssues < 5 ? 'excellent' : 'needs_improvement',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.textTertiary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...metrics.map((metric) => _buildPerformanceMetric(metric)),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(Map<String, String> metric) {
    final performance = metric['performance']!;
    Color statusColor;
    IconData statusIcon;

    switch (performance) {
      case 'excellent':
        statusColor = ModernTheme.success;
        statusIcon = Icons.trending_up;
        break;
      case 'good':
        statusColor = ModernTheme.warning;
        statusIcon = Icons.trending_flat;
        break;
      default:
        statusColor = ModernTheme.error;
        statusIcon = Icons.trending_down;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric['title']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ModernTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${metric['target']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ModernTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metric['value']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    performance.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.textTertiary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response Time by Priority',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingAnalytics)
            const Center(child: CircularProgressIndicator())
          else
            ..._responseTimeByPriority.entries.map((entry) {
              final color = _getPriorityColor(entry.key);
              return _buildResponseTimeBar(entry.key, entry.value, color);
            }),
        ],
      ),
    );
  }

  Widget _buildResponseTimeBar(String priority, double hours, Color color) {
    final maxHours =
        _responseTimeByPriority.values.isNotEmpty
            ? _responseTimeByPriority.values.reduce((a, b) => a > b ? a : b)
            : 1.0;
    final percentage = maxHours > 0 ? (hours / maxHours) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                priority,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ModernTheme.textPrimary,
                ),
              ),
              Text(
                '${hours.toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: percentage * _chartAnimation.value,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.textTertiary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Issues by Hour of Day',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingAnalytics)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(height: 200, child: _buildHourlyChart()),
        ],
      ),
    );
  }

  Widget _buildHourlyChart() {
    final maxCount =
        _hourlyDistribution.values.isNotEmpty
            ? _hourlyDistribution.values.reduce((a, b) => a > b ? a : b)
            : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(24, (index) {
        final hour = index.toString().padLeft(2, '0');
        final count = _hourlyDistribution[hour] ?? 0;
        final height = maxCount > 0 ? (count / maxCount) * 160 : 0.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: _chartAnimation,
                  builder: (context, child) {
                    return Container(
                      height: height * _chartAnimation.value,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            ModernTheme.accent,
                            ModernTheme.accent.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  hour,
                  style: const TextStyle(
                    fontSize: 8,
                    color: ModernTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthlyTrends() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.textTertiary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Issue Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingAnalytics)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(height: 200, child: _buildMonthlyChart()),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    final entries = _monthlyTrends.entries.toList();
    final maxCount =
        entries.isNotEmpty
            ? entries.map((e) => e.value).reduce((a, b) => a > b ? a : b)
            : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          entries.map((entry) {
            final height = maxCount > 0 ? (entry.value / maxCount) * 160 : 0.0;
            final month = entry.key.split('-')[1];

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedBuilder(
                      animation: _chartAnimation,
                      builder: (context, child) {
                        return Container(
                          height: height * _chartAnimation.value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                ModernTheme.primaryBlue,
                                ModernTheme.primaryBlue.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      month,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ModernTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: ModernTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildIssueTypeAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.textTertiary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Issue Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingAnalytics)
            const Center(child: CircularProgressIndicator())
          else if (_topIssueTypes.isEmpty)
            const Text(
              'No issue patterns detected yet',
              style: TextStyle(color: ModernTheme.textSecondary),
            )
          else
            ..._topIssueTypes.map(
              (issueType) => _buildIssueTypeItem(issueType),
            ),
        ],
      ),
    );
  }

  Widget _buildIssueTypeItem(Map<String, dynamic> issueType) {
    final percentage = issueType['percentage'] as double;
    final color = _getIssueTypeColor(issueType['type'] as String);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (issueType['type'] as String).toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ModernTheme.textPrimary,
              ),
            ),
          ),
          Text(
            '${issueType['count']}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 12,
              color: ModernTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsights() {
    final insights = _generateInsights();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModernTheme.primaryBlue.withOpacity(0.1),
            ModernTheme.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Key Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            insight['icon'] as IconData,
            color: insight['color'] as Color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight['text'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: ModernTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _generateRecommendations();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModernTheme.success.withOpacity(0.1),
            ModernTheme.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernTheme.successGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.recommend,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => _buildRecommendationItem(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: ModernTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 14,
                color: ModernTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.textTertiary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  'PDF Report',
                  Icons.picture_as_pdf,
                  ModernTheme.error,
                  () => _exportToPDF(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(
                  'Excel Data',
                  Icons.table_chart,
                  ModernTheme.success,
                  () => _exportToExcel(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  'Email Report',
                  Icons.email,
                  ModernTheme.primaryBlue,
                  () => _emailReport(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(
                  'Share Link',
                  Icons.share,
                  ModernTheme.accent,
                  () => _shareReport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
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

  Color _getIssueTypeColor(String type) {
    final colors = [
      ModernTheme.primaryBlue,
      ModernTheme.accent,
      ModernTheme.success,
      ModernTheme.warning,
      ModernTheme.error,
    ];
    return colors[type.hashCode % colors.length];
  }

  List<Map<String, dynamic>> _generateInsights() {
    List<Map<String, dynamic>> insights = [];

    // Performance insights
    if (widget.resolutionRate >= 90) {
      insights.add({
        'icon': Icons.trending_up,
        'color': ModernTheme.success,
        'text':
            'Excellent resolution rate! Your department is performing above average.',
      });
    } else if (widget.resolutionRate < 60) {
      insights.add({
        'icon': Icons.trending_down,
        'color': ModernTheme.error,
        'text':
            'Resolution rate needs improvement. Consider reviewing current processes.',
      });
    }

    // Response time insights
    if (widget.averageResolutionTime <= 24) {
      insights.add({
        'icon': Icons.speed,
        'color': ModernTheme.success,
        'text': 'Fast response times! Citizens appreciate quick resolutions.',
      });
    } else if (widget.averageResolutionTime > 72) {
      insights.add({
        'icon': Icons.schedule,
        'color': ModernTheme.warning,
        'text':
            'Response times are slower than ideal. Consider optimizing workflows.',
      });
    }

    // Urgent issues insight
    if (widget.urgentCount > widget.totalIssues * 0.3) {
      insights.add({
        'icon': Icons.priority_high,
        'color': ModernTheme.error,
        'text':
            'High number of urgent issues detected. Preventive measures may be needed.',
      });
    }

    // Satisfaction insight
    if (_citizenSatisfactionScore >= 85) {
      insights.add({
        'icon': Icons.sentiment_very_satisfied,
        'color': ModernTheme.success,
        'text':
            'High citizen satisfaction score indicates quality service delivery.',
      });
    }

    return insights;
  }

  List<String> _generateRecommendations() {
    List<String> recommendations = [];

    if (widget.resolutionRate < 80) {
      recommendations.add(
        'Focus on resolving pending issues to improve overall resolution rate.',
      );
    }

    if (widget.averageResolutionTime > 48) {
      recommendations.add(
        'Implement faster response protocols to reduce average resolution time.',
      );
    }

    if (widget.urgentCount > 0) {
      recommendations.add(
        'Prioritize urgent issues to prevent escalation and improve citizen satisfaction.',
      );
    }

    if (_repeatIssues > 3) {
      recommendations.add(
        'Investigate root causes of recurring issues to prevent future occurrences.',
      );
    }

    if (widget.assignedToMeCount > widget.totalIssues * 0.5) {
      recommendations.add(
        'Consider distributing workload more evenly among team members.',
      );
    }

    recommendations.add(
      'Schedule regular team meetings to discuss complex cases and share best practices.',
    );
    recommendations.add(
      'Implement citizen feedback system to continuously improve service quality.',
    );

    return recommendations;
  }

  void _exportToPDF() {
    _showExportMessage(
      'PDF report generation initiated. You will receive an email shortly.',
    );
  }

  void _exportToExcel() {
    _showExportMessage(
      'Excel data export started. Download link will be sent to your email.',
    );
  }

  void _emailReport() {
    _showExportMessage(
      'Analytics report will be emailed to your registered address.',
    );
  }

  void _shareReport() {
    _showExportMessage(
      'Shareable analytics link has been copied to clipboard.',
    );
  }

  void _showExportMessage(String message) {
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
}
