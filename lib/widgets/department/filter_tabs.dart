// widgets/department/filter_tabs.dart
import 'package:flutter/material.dart';
import '../../theme/modern_theme.dart';

class FilterTabs extends StatelessWidget {
  final String selectedTab;
  final int pendingCount;
  final int urgentCount;
  final int assignedToMeCount;
  final int inProgressCount;
  final int resolvedCount;
  final Function(String) onTabSelected;

  const FilterTabs({
    Key? key,
    required this.selectedTab,
    required this.pendingCount,
    required this.urgentCount,
    required this.assignedToMeCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {
        'key': 'pending',
        'label': 'Pending',
        'count': pendingCount,
        'color': ModernTheme.warning,
      },
      {
        'key': 'urgent',
        'label': 'Urgent',
        'count': urgentCount,
        'color': ModernTheme.error,
      },
      {
        'key': 'assigned',
        'label': 'Assigned',
        'count': assignedToMeCount,
        'color': ModernTheme.primaryBlue,
      },
      {
        'key': 'in_progress',
        'label': 'In Progress',
        'count': inProgressCount,
        'color': ModernTheme.accent,
      },
      {
        'key': 'resolved',
        'label': 'Resolved',
        'count': resolvedCount,
        'color': ModernTheme.success,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children:
              tabs.map((tab) {
                final isSelected = selectedTab == tab['key'];
                final color = tab['color'] as Color;
                return GestureDetector(
                  onTap: () => onTabSelected(tab['key'] as String),
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
}
