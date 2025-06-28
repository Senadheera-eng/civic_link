// widgets/department/performance_metrics.dart
import 'package:flutter/material.dart';
import '../../theme/modern_theme.dart';

class PerformanceMetrics extends StatelessWidget {
  final double resolutionRate;
  final double averageResolutionTime;
  final int assignedToMeCount;

  const PerformanceMetrics({
    Key? key,
    required this.resolutionRate,
    required this.averageResolutionTime,
    required this.assignedToMeCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Resolution Rate',
                    '${resolutionRate.toStringAsFixed(1)}%',
                    Icons.check_circle_outline,
                    ModernTheme.success,
                  ),
                ),
                Container(
                  width: 1,
                  color: ModernTheme.textTertiary.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Avg. Resolution',
                    '${averageResolutionTime.toStringAsFixed(1)}h',
                    Icons.timer_outlined,
                    ModernTheme.accent,
                  ),
                ),
                Container(
                  width: 1,
                  color: ModernTheme.textTertiary.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Assigned to Me',
                    assignedToMeCount.toString(),
                    Icons.person_pin_outlined,
                    ModernTheme.primaryBlue,
                  ),
                ),
              ],
            ),
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
      mainAxisSize: MainAxisSize.min,
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
}
