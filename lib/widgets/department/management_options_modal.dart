// widgets/department/management_options_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/issue_model.dart';
import '../../theme/modern_theme.dart';

class ManagementOptionsModal extends StatelessWidget {
  final UserModel? userData;
  final List<IssueModel> departmentIssues;
  final VoidCallback onRefresh;

  const ManagementOptionsModal({
    Key? key,
    required this.userData,
    required this.departmentIssues,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: ModernTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildManagementOption(
                    context,
                    Icons.analytics,
                    'Department Analytics',
                    'View detailed performance metrics',
                    () {
                      Navigator.pop(context);
                      _showAnalytics(context);
                    },
                  ),
                  _buildManagementOption(
                    context,
                    Icons.assignment_turned_in,
                    'Bulk Actions',
                    'Update multiple issues at once',
                    () {
                      Navigator.pop(context);
                      _showBulkActions(context);
                    },
                  ),
                  _buildManagementOption(
                    context,
                    Icons.schedule,
                    'Issue Assignment',
                    'Assign issues to team members',
                    () {
                      Navigator.pop(context);
                      _showAssignmentOptions(context);
                    },
                  ),
                  _buildManagementOption(
                    context,
                    Icons.people,
                    'Team Management',
                    'Manage department team',
                    () {
                      Navigator.pop(context);
                      _showSuccessSnackBar(
                        context,
                        'Team management coming soon!',
                      );
                    },
                  ),
                  _buildManagementOption(
                    context,
                    Icons.settings,
                    'Department Settings',
                    'Configure department preferences',
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: ModernTheme.primaryGradient,
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
    );
  }

  void _showBulkActions(BuildContext context) {
    final pendingIssues =
        departmentIssues
            .where((issue) => issue.status.toLowerCase() == 'pending')
            .toList();

    if (pendingIssues.isEmpty) {
      _showErrorSnackBar(
        context,
        'No pending issues available for bulk actions',
      );
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
                      context,
                      pendingIssues.map((e) => e.id).toList(),
                      'in_progress',
                      'Bulk updated to In Progress by ${userData?.shortDisplayName}',
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

  void _showAssignmentOptions(BuildContext context) {
    final unassignedIssues =
        departmentIssues
            .where(
              (issue) =>
                  issue.status.toLowerCase() == 'pending' &&
                  (issue.assignedTo == null || issue.assignedTo!.isEmpty),
            )
            .toList();

    if (unassignedIssues.isEmpty) {
      _showErrorSnackBar(context, 'No unassigned issues available');
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
                    _assignIssuesToSelf(context, unassignedIssues);
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

  void _showAnalytics(BuildContext context) {
    // This would open the analytics modal
    // Implementation would be similar to the existing analytics modal
    _showSuccessSnackBar(context, 'Analytics feature coming soon!');
  }

  Future<void> _performBulkStatusUpdate(
    BuildContext context,
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
      _showSuccessSnackBar(
        context,
        '${issueIds.length} issues updated successfully',
      );
      onRefresh();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to update issues: $e');
    }
  }

  Future<void> _assignIssuesToSelf(
    BuildContext context,
    List<IssueModel> issues,
  ) async {
    if (userData == null) return;

    try {
      for (final issue in issues) {
        await _assignIssue(
          issueId: issue.id,
          assignedToId: userData!.uid,
          assignedToName: userData!.displayName,
          notes: 'Self-assigned by ${userData!.shortDisplayName}',
        );
      }
      _showSuccessSnackBar(context, '${issues.length} issues assigned to you');
      onRefresh();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to assign issues: $e');
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
          'updatedBy': userData?.uid,
        });
      }

      await batch.commit();
    } catch (e) {
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
            'assignedBy': userData?.uid,
          });
    } catch (e) {
      throw 'Failed to assign issue: $e';
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
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

  void _showErrorSnackBar(BuildContext context, String message) {
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
