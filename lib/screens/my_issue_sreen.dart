// screens/my_issues_screen.dart
import 'package:flutter/material.dart';
import '../services/issue_service.dart';
import '../models/issue_model.dart';
import '../theme/simple_theme.dart';
import 'issue_detail_screen.dart';

class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({Key? key}) : super(key: key);

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen>
    with SingleTickerProviderStateMixin {
  final IssueService _issueService = IssueService();
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Issues'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Resolved'),
          ],
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedFilter = 'all';
                  break;
                case 1:
                  _selectedFilter = 'pending';
                  break;
                case 2:
                  _selectedFilter = 'in_progress';
                  break;
                case 3:
                  _selectedFilter = 'resolved';
                  break;
              }
            });
          },
        ),
      ),
      body: StreamBuilder<List<IssueModel>>(
        stream: _issueService.getUserIssuesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: SimpleTheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading issues',
                    style: TextStyle(color: SimpleTheme.error),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final issues = snapshot.data ?? [];

          // Filter issues based on selected tab
          final filteredIssues =
              _selectedFilter == 'all'
                  ? issues
                  : issues
                      .where((issue) => issue.status == _selectedFilter)
                      .toList();

          if (filteredIssues.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredIssues.length,
              itemBuilder: (context, index) {
                final issue = filteredIssues[index];
                return _buildIssueCard(issue);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == 'all' ? Icons.inbox : Icons.filter_list,
            size: 80,
            color: SimpleTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No issues reported yet'
                : 'No ${_getStatusText(_selectedFilter)} issues',
            style: const TextStyle(
              fontSize: 18,
              color: SimpleTheme.textSecondary,
            ),
          ),
          if (_selectedFilter == 'all') ...[
            const SizedBox(height: 8),
            const Text(
              'Report an issue to see it here',
              style: TextStyle(fontSize: 14, color: SimpleTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIssueCard(IssueModel issue) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IssueDetailScreen(issue: issue),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: SimpleTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: SimpleTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                issue.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: SimpleTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusChip(
                        text: _getStatusText(issue.status),
                        color: statusColor,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          issue.priority,
                          style: TextStyle(
                            fontSize: 11,
                            color: priorityColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                issue.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: SimpleTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(issue.category),
                        size: 16,
                        color: SimpleTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        issue.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SimpleTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (issue.imageUrls.isNotEmpty) ...[
                        Icon(
                          Icons.image,
                          size: 16,
                          color: SimpleTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${issue.imageUrls.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SimpleTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: SimpleTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(issue.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: SimpleTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Admin Notes (if any)
              if (issue.adminNotes != null && issue.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SimpleTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: SimpleTheme.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Admin: ${issue.adminNotes}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SimpleTheme.textPrimary,
                          ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return SimpleTheme.warning;
      case 'in_progress':
        return SimpleTheme.accent;
      case 'resolved':
        return SimpleTheme.success;
      case 'rejected':
        return SimpleTheme.error;
      default:
        return SimpleTheme.textSecondary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return SimpleTheme.success;
      case 'medium':
        return SimpleTheme.warning;
      case 'high':
        return SimpleTheme.error;
      case 'critical':
        return Colors.red[800]!;
      default:
        return SimpleTheme.textSecondary;
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Road & Transportation':
        return Icons.construction;
      case 'Water & Sewerage':
        return Icons.water_drop;
      case 'Electricity':
        return Icons.electrical_services;
      case 'Public Safety':
        return Icons.security;
      case 'Waste Management':
        return Icons.delete;
      case 'Parks & Recreation':
        return Icons.park;
      case 'Street Lighting':
        return Icons.lightbulb;
      case 'Public Buildings':
        return Icons.business;
      case 'Traffic Management':
        return Icons.traffic;
      case 'Environmental Issues':
        return Icons.eco;
      default:
        return Icons.report_problem;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
