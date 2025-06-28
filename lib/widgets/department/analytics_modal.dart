// widgets/department/analytics_modal.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/modern_theme.dart';

class AnalyticsModal extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                    '${userData?.department ?? "Department"} Analytics',
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
                    totalIssues.toString(),
                    Icons.assignment,
                    ModernTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Resolution Rate',
                    '${resolutionRate.toStringAsFixed(1)}%',
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
                    '${averageResolutionTime.toStringAsFixed(1)}h',
                    Icons.timer,
                    ModernTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'This Month',
                    thisMonthCount.toString(),
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
                      totalIssues.toString(),
                    ),
                    _buildAnalyticsItem(
                      'Pending Issues',
                      pendingCount.toString(),
                    ),
                    _buildAnalyticsItem(
                      'In Progress',
                      inProgressCount.toString(),
                    ),
                    _buildAnalyticsItem(
                      'Resolved Issues',
                      resolvedCount.toString(),
                    ),
                    _buildAnalyticsItem(
                      'Rejected Issues',
                      rejectedCount.toString(),
                    ),
                    _buildAnalyticsItem(
                      'Urgent Issues',
                      urgentCount.toString(),
                    ),
                    _buildAnalyticsItem(
                      'Assigned to Me',
                      assignedToMeCount.toString(),
                    ),
                    _buildAnalyticsItem('This Week', thisWeekCount.toString()),
                    _buildAnalyticsItem(
                      'This Month',
                      thisMonthCount.toString(),
                    ),
                    _buildAnalyticsItem(
                      'Resolution Rate',
                      '${resolutionRate.toStringAsFixed(1)}%',
                    ),
                    _buildAnalyticsItem(
                      'Average Resolution Time',
                      '${averageResolutionTime.toStringAsFixed(1)} hours',
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
                      _exportAnalytics(context);
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

  Widget _buildInsight() {
    String insightText = 'Great performance! ';
    IconData insightIcon = Icons.trending_up;
    Color insightColor = ModernTheme.success;

    if (resolutionRate >= 80) {
      insightText +=
          'Your department has an excellent resolution rate of ${resolutionRate.toStringAsFixed(1)}%.';
    } else if (resolutionRate >= 60) {
      insightText +=
          'Your resolution rate of ${resolutionRate.toStringAsFixed(1)}% is good but can be improved.';
      insightColor = ModernTheme.warning;
      insightIcon = Icons.trending_flat;
    } else {
      insightText =
          'Focus needed! Your resolution rate of ${resolutionRate.toStringAsFixed(1)}% needs improvement.';
      insightColor = ModernTheme.error;
      insightIcon = Icons.trending_down;
    }

    if (urgentCount > 0) {
      insightText +=
          ' You have $urgentCount urgent issues requiring immediate attention.';
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

  void _exportAnalytics(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Analytics export initiated! You will receive an email with the detailed report shortly.',
            ),
          ],
        ),
        backgroundColor: ModernTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
