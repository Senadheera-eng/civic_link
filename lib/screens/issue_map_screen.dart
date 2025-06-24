// screens/issue_map_screen_simple.dart (MODERN UI UPDATE)
import 'package:flutter/material.dart';
import '../services/issue_service.dart';
import '../models/issue_model.dart';
import '../theme/modern_theme.dart';
import 'issue_detail_screen.dart';

class IssueMapScreen extends StatefulWidget {
  const IssueMapScreen({Key? key}) : super(key: key);

  @override
  State<IssueMapScreen> createState() => _IssueMapScreenState();
}

class _IssueMapScreenState extends State<IssueMapScreen>
    with TickerProviderStateMixin {
  final IssueService _issueService = IssueService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<IssueModel> _issues = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadIssues();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Error loading issues: $e'),
              ],
            ),
            backgroundColor: ModernTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
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
      body: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Scrollable Header
                  _buildModernHeader(),

                  // Main Content Container
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      color: ModernTheme.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Map Placeholder with Modern Design
                        Container(
                          height: 200,
                          width: double.infinity,
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ModernTheme.primaryBlue.withOpacity(0.1),
                                ModernTheme.accent.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ModernTheme.primaryBlue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Placeholder for map
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: ModernTheme.accentGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: ModernTheme.accent
                                                .withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.map,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Interactive Map',
                                      style: TextStyle(
                                        color: ModernTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Coming Soon',
                                      style: TextStyle(
                                        color: ModernTheme.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: ModernTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ModernTheme.primaryBlue
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_filteredIssues.length} ${_filteredIssues.length == 1 ? 'Issue' : 'Issues'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Modern Filters Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Filter Issues',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ModernTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Category Filter
                              SizedBox(
                                height: 44,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _buildModernFilterChip(
                                      label: 'All',
                                      icon: Icons.apps,
                                      isSelected: _selectedCategory == 'All',
                                      onSelected:
                                          () => setState(
                                            () => _selectedCategory = 'All',
                                          ),
                                      gradient: ModernTheme.accentGradient,
                                    ),
                                    ...IssueCategories.categories.map((
                                      category,
                                    ) {
                                      return _buildModernFilterChip(
                                        label: category,
                                        icon: _getCategoryIcon(category),
                                        isSelected:
                                            _selectedCategory == category,
                                        onSelected:
                                            () => setState(
                                              () =>
                                                  _selectedCategory = category,
                                            ),
                                        gradient: ModernTheme.primaryGradient,
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Status Filter
                              SizedBox(
                                height: 44,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _buildModernStatusChip(
                                      'All',
                                      ModernTheme.textSecondary,
                                    ),
                                    _buildModernStatusChip(
                                      'pending',
                                      ModernTheme.warning,
                                    ),
                                    _buildModernStatusChip(
                                      'in_progress',
                                      ModernTheme.accent,
                                    ),
                                    _buildModernStatusChip(
                                      'resolved',
                                      ModernTheme.success,
                                    ),
                                    _buildModernStatusChip(
                                      'rejected',
                                      ModernTheme.error,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Issues List
                        _isLoading
                            ? _buildLoadingState()
                            : _filteredIssues.isEmpty
                            ? _buildEmptyState()
                            : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                children:
                                    _filteredIssues
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => _buildModernIssueCard(
                                            entry.value,
                                            entry.key,
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),

                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issue Map',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Explore issues in your area',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadIssues,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
    required LinearGradient gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: isSelected ? null : ModernTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  isSelected
                      ? Colors.transparent
                      : ModernTheme.textTertiary.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : ModernTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label.length > 12 ? '${label.substring(0, 12)}...' : label,
                style: TextStyle(
                  color: isSelected ? Colors.white : ModernTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatusChip(String status, Color color) {
    final isSelected = _selectedStatus == status;
    final displayText = status == 'All' ? 'All' : _getStatusText(status);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                    : null,
            color: isSelected ? null : ModernTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? Colors.transparent : color.withOpacity(0.3),
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
          child: Text(
            displayText,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ModernTheme.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading issues...',
            style: TextStyle(
              fontSize: 16,
              color: ModernTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ModernTheme.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No issues found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 16, color: ModernTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildModernIssueCard(IssueModel issue, int index) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IssueDetailScreen(issue: issue),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ModernTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ModernTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(issue.category),
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ModernTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: ModernTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              issue.address,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ModernTheme.textSecondary,
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
                ModernStatusChip(
                  text: _getStatusText(issue.status),
                  color: statusColor,
                  icon: _getStatusIcon(issue.status),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              issue.description,
              style: const TextStyle(
                fontSize: 15,
                color: ModernTheme.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Footer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category and Reporter
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ModernTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        issue.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ModernTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: ModernTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      issue.userName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ModernTheme.textSecondary,
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
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            priorityColor,
                            priorityColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        issue.priority,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getTimeAgo(issue.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ModernTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
