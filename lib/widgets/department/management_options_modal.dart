// widgets/department/management_options_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
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
      height: MediaQuery.of(context).size.height * 0.75,
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
                      _showTeamManagement(context);
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

  // 🔹 Analytics
  void _showAnalytics(BuildContext context) {
    final statusCounts = <String, int>{};
    for (var issue in departmentIssues) {
      statusCounts[issue.status] = (statusCounts[issue.status] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Department Analytics"),
            content: SizedBox(
              height: 250,
              width: 300,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: true),
                  barGroups:
                      statusCounts.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key.hashCode % 100,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: Colors.blue,
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Close"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  // 🔹 Bulk Actions
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
          (_) => AlertDialog(
            title: const Text('Bulk Actions'),
            content: Text('${pendingIssues.length} pending issues available'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performBulkStatusUpdate(
                    context,
                    pendingIssues.map((e) => e.id).toList(),
                    'in_progress',
                    'Bulk updated by ${userData?.shortDisplayName}',
                  );
                },
                child: const Text('Mark All In Progress'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  // 🔹 Assignment
  void _showAssignmentOptions(BuildContext context) {
    final unassignedIssues =
        departmentIssues
            .where(
              (i) =>
                  i.status.toLowerCase() == 'pending' &&
                  (i.assignedTo == null || i.assignedTo!.isEmpty),
            )
            .toList();

    if (unassignedIssues.isEmpty) {
      _showErrorSnackBar(context, 'No unassigned issues available');
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Issue Assignment'),
            content: Text('${unassignedIssues.length} issues unassigned'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _assignIssuesToSelf(context, unassignedIssues);
                },
                child: const Text('Assign All to Me'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  // 🔹 Team Management
  void _showTeamManagement(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Team Management"),
            content: SizedBox(
              width: 350,
              height: 400,
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .where(
                                'departmentId',
                                isEqualTo: userData?.department,
                              )
                              .snapshots(),
                      builder: (ctx, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final users = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (ctx, i) {
                            final user = users[i];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(user['displayName']),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.id)
                                      .delete();
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: "Enter member name",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () async {
                          if (controller.text.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .add({
                                  'displayName': controller.text,
                                  'departmentId': userData?.department,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                            controller.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 🔹 Firestore helpers
  Future<void> _performBulkStatusUpdate(
    BuildContext context,
    List<String> issueIds,
    String newStatus,
    String notes,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (String id in issueIds) {
        final docRef = FirebaseFirestore.instance.collection('issues').doc(id);
        batch.update(docRef, {
          'status': newStatus,
          'adminNotes': notes,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': userData?.uid,
        });
      }
      await batch.commit();
      _showSuccessSnackBar(context, '${issueIds.length} issues updated');
      onRefresh();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed: $e');
    }
  }

  Future<void> _assignIssuesToSelf(
    BuildContext context,
    List<IssueModel> issues,
  ) async {
    if (userData == null) return;
    try {
      for (final issue in issues) {
        await FirebaseFirestore.instance
            .collection('issues')
            .doc(issue.id)
            .update({
              'assignedTo': userData!.uid,
              'assignedToName': userData!.displayName,
              'status': 'in_progress',
              'adminNotes': 'Self-assigned by ${userData!.shortDisplayName}',
              'assignedAt': FieldValue.serverTimestamp(),
            });
      }
      _showSuccessSnackBar(context, '${issues.length} issues assigned');
      onRefresh();
    } catch (e) {
      _showErrorSnackBar(context, 'Failed: $e');
    }
  }

  // 🔹 Snackbars
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
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ModernTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
