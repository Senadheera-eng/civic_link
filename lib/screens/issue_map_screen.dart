// screens/issue_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<IssueModel> _issues = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  // Default camera position (you can update this to user's location)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612), // Colombo, Sri Lanka
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    try {
      final issues = await _issueService.getAllIssues();
      setState(() {
        _issues = issues;
        _createMarkers();
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

  void _createMarkers() {
    final filteredIssues =
        _selectedCategory == 'All'
            ? _issues
            : _issues
                .where((issue) => issue.category == _selectedCategory)
                .toList();

    _markers =
        filteredIssues.map((issue) {
          return Marker(
            markerId: MarkerId(issue.id),
            position: LatLng(issue.latitude, issue.longitude),
            icon: _getMarkerIcon(issue.status, issue.priority),
            infoWindow: InfoWindow(
              title: issue.title,
              snippet: '${issue.category} • ${_getStatusText(issue.status)}',
              onTap: () => _showIssueDetails(issue),
            ),
            onTap: () => _showIssueBottomSheet(issue),
          );
        }).toSet();
  }

  BitmapDescriptor _getMarkerIcon(String status, String priority) {
    // Color based on status
    switch (status.toLowerCase()) {
      case 'pending':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'in_progress':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'resolved':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'rejected':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _showIssueBottomSheet(IssueModel issue) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildIssueBottomSheet(issue),
    );
  }

  Widget _buildIssueBottomSheet(IssueModel issue) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title and Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  issue.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusChip(
                text: _getStatusText(issue.status),
                color: statusColor,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Category and Priority
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
                  fontSize: 14,
                  color: SimpleTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  issue.priority,
                  style: TextStyle(
                    fontSize: 12,
                    color: priorityColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

          const SizedBox(height: 16),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
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

          const SizedBox(height: 8),

          // Reported by and time
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 16,
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
              const Spacer(),
              Text(
                _getTimeAgo(issue.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: SimpleTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // View Details Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showIssueDetails(issue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SimpleTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIssueDetails(IssueModel issue) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IssueDetailScreen(issue: issue)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Map'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadIssues),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Category Filter
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'All',
                    isSelected: _selectedCategory == 'All',
                  ),
                  ...IssueCategories.categories.map((category) {
                    return _buildFilterChip(
                      category,
                      isSelected: _selectedCategory == category,
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Issue Count
          Positioned(
            bottom: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    '${_markers.length} ${_markers.length == 1 ? 'Issue' : 'Issues'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: SimpleTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Legend
          Positioned(
            bottom: 20,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem('Pending', SimpleTheme.warning),
                  _buildLegendItem('In Progress', SimpleTheme.accent),
                  _buildLegendItem('Resolved', SimpleTheme.success),
                  _buildLegendItem('Rejected', SimpleTheme.error),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = label;
            _createMarkers();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: SimpleTheme.primaryBlue.withOpacity(0.2),
        checkmarkColor: SimpleTheme.primaryBlue,
        labelStyle: TextStyle(
          color:
              isSelected ? SimpleTheme.primaryBlue : SimpleTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? SimpleTheme.primaryBlue : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
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
