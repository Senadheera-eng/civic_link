// widgets/department/official_issue_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/issue_model.dart';
import '../../services/issue_service.dart';
import '../../theme/modern_theme.dart';

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
