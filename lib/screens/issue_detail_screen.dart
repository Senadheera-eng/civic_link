// screens/issue_detail_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/issue_model.dart';
import '../theme/simple_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class IssueDetailScreen extends StatelessWidget {
  final IssueModel issue;

  const IssueDetailScreen({Key? key, required this.issue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: statusColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(issue.status),
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${_getStatusText(issue.status)}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Priority
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          issue.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: SimpleTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: priorityColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag, size: 16, color: priorityColor),
                            const SizedBox(width: 4),
                            Text(
                              issue.priority,
                              style: TextStyle(
                                color: priorityColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Category and Date
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(issue.category),
                        size: 20,
                        color: SimpleTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        issue.category,
                        style: const TextStyle(
                          fontSize: 16,
                          color: SimpleTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: SimpleTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(issue.createdAt),
                        style: const TextStyle(
                          fontSize: 14,
                          color: SimpleTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description Section
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: SimpleTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issue.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: SimpleTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Location Section
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: SimpleTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SimpleCard(
                    color: SimpleTheme.primaryBlue.withOpacity(0.05),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: SimpleTheme.primaryBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                issue.address,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: SimpleTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lat: ${issue.latitude.toStringAsFixed(6)}, Lng: ${issue.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: SimpleTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.map),
                          color: SimpleTheme.primaryBlue,
                          onPressed: () {
                            // TODO: Open in maps
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Map view coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Images Section
                  if (issue.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: SimpleTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: issue.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GestureDetector(
                                onTap:
                                    () => _showFullImage(
                                      context,
                                      issue.imageUrls[index],
                                    ),
                                child: CachedNetworkImage(
                                  imageUrl: issue.imageUrls[index],
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Admin Notes Section
                  if (issue.adminNotes != null &&
                      issue.adminNotes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Admin Response',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: SimpleTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SimpleTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: SimpleTheme.accent.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 20,
                                color: SimpleTheme.accent,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Administrator',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: SimpleTheme.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            issue.adminNotes!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: SimpleTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Timeline Section
                  const SizedBox(height: 24),
                  const Text(
                    'Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: SimpleTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineItem(
                    icon: Icons.report_problem,
                    title: 'Issue Reported',
                    subtitle: 'by ${issue.userName}',
                    date: issue.createdAt,
                    isFirst: true,
                    isLast: issue.updatedAt == null,
                  ),
                  if (issue.updatedAt != null)
                    _buildTimelineItem(
                      icon: Icons.update,
                      title: 'Status Updated',
                      subtitle: 'to ${_getStatusText(issue.status)}',
                      date: issue.updatedAt!,
                      isFirst: false,
                      isLast: true,
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required DateTime date,
    required bool isFirst,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SimpleTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: SimpleTheme.primaryBlue),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: SimpleTheme.primaryBlue.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SimpleTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: SimpleTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(date),
                style: const TextStyle(
                  fontSize: 12,
                  color: SimpleTheme.textSecondary,
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
              body: Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder:
                        (context, url) => const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                    errorWidget:
                        (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 50,
                        ),
                  ),
                ),
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'in_progress':
        return Icons.construction;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
