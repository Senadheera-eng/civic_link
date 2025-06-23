// screens/home_screen.dart (SIMPLE COLORFUL VERSION)
import 'package:civic_link/screens/issue_map_screen.dart';
import 'package:civic_link/screens/my_issue_sreen.dart';
import 'package:civic_link/screens/notification_screen.dart';
import 'package:civic_link/services/notification_service.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme/simple_theme.dart';
import 'report_issue_screen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _subscribeToNotifications();
  }

  Future<void> _subscribeToNotifications() async {
    try {
      // Subscribe to general updates
      await NotificationService().subscribeToTopic('general_updates');

      // Subscribe to user-specific updates if needed
      final user = _authService.currentUser;
      if (user != null) {
        await NotificationService().subscribeToTopic('user_${user.uid}');
      }
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    try {
      print("🔐 HomeScreen: Starting sign out process");

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _authService.signOut();

      // Close loading dialog
      Navigator.of(context).pop();

      print("✅ HomeScreen: Sign out successful, navigating to login");
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print("❌ HomeScreen: Sign out failed: $e");

      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $e'),
          backgroundColor: SimpleTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SimpleTheme.primaryBlue, SimpleTheme.primaryDark],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading CivicLink...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicLink'),
        actions: [
          // Notification Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              StreamBuilder<int>(
                stream: NotificationService().getUnreadCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();

                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: SimpleTheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          // Existing PopupMenuButton
          PopupMenuButton<String>(
            // ... existing code
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(),

            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),

            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return SimpleCard(
      color: SimpleTheme.primaryBlue,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  _userData?.fullName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StatusChip(
                  text: _userData?.userType.toUpperCase() ?? 'CITIZEN',
                  color: Colors.white,
                  icon:
                      _userData?.isAdmin == true
                          ? Icons.admin_panel_settings
                          : Icons.person,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: SimpleCard(
            color: SimpleTheme.success.withOpacity(0.1),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: SimpleTheme.success, size: 32),
                const SizedBox(height: 8),
                const Text(
                  '12',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SimpleTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Resolved',
                  style: TextStyle(
                    fontSize: 14,
                    color: SimpleTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SimpleCard(
            color: SimpleTheme.warning.withOpacity(0.1),
            child: Column(
              children: [
                Icon(Icons.pending, color: SimpleTheme.warning, size: 32),
                const SizedBox(height: 8),
                const Text(
                  '3',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SimpleTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 14,
                    color: SimpleTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SimpleCard(
            color: SimpleTheme.accent.withOpacity(0.1),
            child: Column(
              children: [
                Icon(Icons.trending_up, color: SimpleTheme.accent, size: 32),
                const SizedBox(height: 8),
                const Text(
                  '8',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SimpleTheme.textPrimary,
                  ),
                ),
                const Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 14,
                    color: SimpleTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: SimpleTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3, // Increased from 1.2 to give more width
          children: [
            _buildActionCard(
              icon: Icons.report_problem,
              title: 'Report Issue',
              subtitle: 'Report problems',
              color: SimpleTheme.warning,
              onTap: () => _navigateToReportIssue(),
            ),
            _buildActionCard(
              icon: Icons.track_changes,
              title: 'Track Issues',
              subtitle: 'Monitor reports',
              color: SimpleTheme.accent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyIssuesScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.map,
              title: 'Issue Map',
              subtitle: 'View nearby issues',
              color: SimpleTheme.success,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IssueMapScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Stay updated',
              color: SimpleTheme.primaryBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SimpleCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10), // Reduced padding from 12 to 10
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ), // Reduced size from 32 to 28
          ),
          const SizedBox(height: 8), // Reduced from 12 to 8
          Text(
            title,
            style: const TextStyle(
              fontSize: 14, // Reduced from 16 to 14
              fontWeight: FontWeight.w600,
              color: SimpleTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2), // Reduced from 4 to 2
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11, // Reduced from 12 to 11
              color: SimpleTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: SimpleTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _showComingSoon('View All'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActivityItem(
          title: 'Pothole on Main Street',
          subtitle: 'Reported 2 days ago',
          status: 'In Progress',
          statusColor: SimpleTheme.accent,
          icon: Icons.construction,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          title: 'Broken Street Light',
          subtitle: 'Reported 1 week ago',
          status: 'Resolved',
          statusColor: SimpleTheme.success,
          icon: Icons.lightbulb,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          title: 'Water Leak Issue',
          subtitle: 'Reported 3 days ago',
          status: 'Pending',
          statusColor: SimpleTheme.warning,
          icon: Icons.water_drop,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return SimpleCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SimpleTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SimpleTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(text: status, color: statusColor),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Text('$feature feature coming soon!'),
          ],
        ),
        backgroundColor: SimpleTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _navigateToReportIssue() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReportIssueScreen()),
    );

    // If issue was submitted successfully, refresh the home screen
    if (result == true) {
      // Optionally refresh data here
      _loadUserData();
    }
  }
}
