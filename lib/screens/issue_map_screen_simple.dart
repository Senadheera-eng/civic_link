// screens/issue_map_screen_simple.dart
// Use this version if Google Maps is not yet configured

import 'package:flutter/material.dart';
import '../services/issue_service.dart';
import '../models/issue_model.dart';
import '../theme/simple_theme.dart';
import 'issue_detail_screen.dart';

class IssueMapScreen extends StatefulWidget {
  const IssueMapScreen({Key? key}) : super(key: key);

  @override
  State<IssueMapScreen> createState() => _IssueMapScreenState();
}

class _IssueMapScreenState extends State<IssueMapScreen> {
  final IssueService _issueService = IssueService();
  List<IssueModel> _issues = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    try {
      final issues = await _issueService.getAllIssues();
      setState(() {
        _issues = issues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading issues: $e'),
            backgroundColor: SimpleTheme.error,
          ),
        );
      }
    }
  }

  List<IssueModel> get _filteredIssues {
    return _issues.where((issue) {
      final matchesCategory =
          _selectedCategory == 'All' || issue.category == _selectedCategory;
      final matchesStatus =
          _selectedStatus == 'All' || issue.status == _selectedStatus;
      return matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues Near You'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadIssues),
        ],
      ),
      body: Column(
        children: [
          // Map Placeholder
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: Stack(
              children: [
                // Placeholder for map
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Map View Coming Soon',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Currently showing list view',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Issue count overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: SimpleTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredIssues.length} ${_filteredIssues.length == 1 ? 'Issue' : 'Issues'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: SimpleTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Category Filter
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(
                        'All',
                        isSelected: _selectedCategory == 'All',
                        onSelected:
                            () => setState(() => _selectedCategory = 'All'),
                      ),
                      ...IssueCategories.categories.map((category) {
                        return _buildFilterChip(
                          category,
                          icon: _getCategoryIcon(category),
                          isSelected: _selectedCategory == category,
                          onSelected:
                              () =>
                                  setState(() => _selectedCategory = category),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Status Filter
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStatusChip('All', Colors.grey),
                      _buildStatusChip('pending', SimpleTheme.warning),
                      _buildStatusChip('in_progress', SimpleTheme.accent),
                      _buildStatusChip('resolved', SimpleTheme.success),
                      _buildStatusChip('rejected', SimpleTheme.error),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Issues List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredIssues.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredIssues.length,
                      itemBuilder: (context, index) {
                        final issue = _filteredIssues[index];
                        return _buildIssueCard(issue);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white,
        selectedColor: SimpleTheme.primaryBlue.withOpacity(0.2),
        checkmarkColor: SimpleTheme.primaryBlue,
        labelStyle: TextStyle(
          color:
              isSelected ? SimpleTheme.primaryBlue : SimpleTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? SimpleTheme.primaryBlue : Colors.grey[300]!,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    final isSelected = _selectedStatus == status;
    final displayText = status == 'All' ? 'All' : _getStatusText(status);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(displayText),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedStatus = status),
        backgroundColor: Colors.white,
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : SimpleTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(color: isSelected ? color : Colors.grey[300]!),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: SimpleTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No issues found',
            style: TextStyle(fontSize: 18, color: SimpleTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14, color: SimpleTheme.textSecondary),
          ),
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
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SimpleTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(issue.category),
                      size: 24,
                      color: SimpleTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Location
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
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
                  // Status
                  StatusChip(
                    text: _getStatusText(issue.status),
                    color: statusColor,
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

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reporter
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: SimpleTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        issue.userName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SimpleTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Priority and Time
                  Row(
                    children: [
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
                      const SizedBox(width: 8),
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
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
