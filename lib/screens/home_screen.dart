// screens/home_screen.dart (UPDATED FOR 5 DEPARTMENTS)
import 'package:civic_link/screens/issue_map_screen.dart';
import 'package:civic_link/screens/my_issue_sreen.dart';
import 'package:civic_link/screens/notifications_screen.dart';
import 'package:civic_link/services/notification_service.dart';
import 'package:civic_link/screens/setting_screen.dart'
    hide ModernStatusChip, ModernCard;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Add this for StreamSubscription
import '../services/auth_service.dart';
import '../services/issue_service.dart';
import '../models/user_model.dart';
import '../models/issue_model.dart';
import '../theme/modern_theme.dart';
import 'report_issue_screen.dart';
import 'issue_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final IssueService _issueService = IssueService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserModel? _userData;
  List<IssueModel> _userIssues = [];
  bool _isLoading = true;

  // Statistics
  int _resolvedCount = 0;
  int _pendingCount = 0;
  int _thisMonthCount = 0;

  // Add stream subscription for real-time updates
  StreamSubscription<List<IssueModel>>? _issuesSubscription;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
    _setupRealTimeUpdates(); // Add this line
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _issuesSubscription?.cancel(); // Cancel subscription
    super.dispose();
  }

  // NEW: Setup real-time updates
  void _setupRealTimeUpdates() {
    print("🔄 Setting up real-time updates for home screen");

    // Cancel existing subscription to avoid duplicates
    _issuesSubscription?.cancel();
    _issuesSubscription = _issueService.getUserIssuesStream().listen(
      (issues) {
        print("📊 Home screen received ${issues.length} issues from stream");
        if (mounted) {
          setState(() {
            _userIssues = issues;
            _calculateStatistics(issues);
          });
          // Check for new issues and show notification
          _checkForNewIssues(issues);
        }
      },
      onError: (error) {
        print("❌ Error in issues stream: $error");
        // Retry setup after a delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _setupRealTimeUpdates();
          }
        });
      },
    );
  }

  Future<void> _loadData() async {
    try {
      print(
        "🏠 Loading home screen data... (${DateTime.now()})",
      ); // Enhanced logging

      // Load user data
      final userData = await _authService.getUserData();

      // Load user's issues (this will also trigger the stream)
      final userIssues = await _issueService.getUserIssues();

      // Calculate statistics
      _calculateStatistics(userIssues);

      if (mounted) {
        setState(() {
          _userData = userData;
          _userIssues = userIssues;
          _isLoading = false;
        });
      }

      print("✅ Home screen data loaded successfully");
    } catch (e) {
      print("❌ Error loading home screen data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateStatistics(List<IssueModel> issues) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    _resolvedCount =
        issues
            .where((issue) => issue.status.toLowerCase() == 'resolved')
            .length;

    _pendingCount =
        issues.where((issue) => issue.status.toLowerCase() == 'pending').length;

    _thisMonthCount =
        issues.where((issue) => issue.createdAt.isAfter(currentMonth)).length;

    print(
      "📊 Updated stats: Resolved: $_resolvedCount, Pending: $_pendingCount, This Month: $_thisMonthCount",
    );
  }

  // NEW: Check for new issues and show notifications
  void _checkForNewIssues(List<IssueModel> newIssues) {
    // Only check if we already had issues loaded (not on first load)
    if (_userIssues.isEmpty) return;

    final now = DateTime.now();
    final recentIssues =
        newIssues
            .where(
              (issue) =>
                  now.difference(issue.createdAt).inMinutes <
                      2 && // Very recent
                  issue.status.toLowerCase() == 'pending',
            )
            .toList();

    // Check if there are more issues than before
    final previousCount = _userIssues.length;
    final newCount = newIssues.length;

    if (newCount > previousCount) {
      final additionalIssues = newCount - previousCount;
      _showSuccessSnackBar(
        'Your issue has been submitted successfully! You now have $newCount total issues.',
      );
    }
  }

  Future<void> _signOut() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: const ModernCard(
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Signing out...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      await _authService.signOut();
      Navigator.of(context).pop();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $e'),
          backgroundColor: ModernTheme.error,
        ),
      );
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 12),
            Text('Profile editing available in Settings'),
          ],
        ),
        backgroundColor: ModernTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // UPDATED: Navigate to report issue and refresh on return
  void _navigateToReportIssue() async {
    print("🚀 Navigating to report issue screen...");

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ModernReportIssueScreen()),
    );

    // Check if an issue was successfully submitted
    if (result == true) {
      print("✅ Issue submitted successfully, refreshing home screen...");

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Issue submitted successfully!'),
            ],
          ),
          backgroundColor: ModernTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Force refresh the data
      await _loadData();
      _setupRealTimeUpdates();
    }
  }

  // Test method (you can remove this later)
  Future<void> _testFirestoreConnection() async {
    try {
      print("🧪 Starting Firestore connection test...");

      // Test basic authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ No user authenticated");
        _showErrorSnackBar("No user authenticated");
        return;
      }

      print("👤 Current user: ${user.email} (${user.uid})");
      print("🔒 Email verified: ${user.emailVerified}");

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Testing Firestore connection...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Test Firestore network connectivity
      print("🌐 Testing Firestore network...");
      await FirebaseFirestore.instance.enableNetwork();
      print("✅ Firestore network enabled");

      // Test reading issues
      print("📋 Testing issues read access...");
      final issuesQuery =
          await FirebaseFirestore.instance
              .collection('issues')
              .where('userId', isEqualTo: user.uid)
              .limit(5)
              .get();
      print("✅ Issues query successful: ${issuesQuery.docs.length} docs found");

      // Test reading notifications
      print("🔔 Testing notifications read access...");
      final notificationsQuery =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .limit(5)
              .get();
      print(
        "✅ Notifications query successful: ${notificationsQuery.docs.length} docs found",
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Firestore test passed! Issues: ${issuesQuery.docs.length}, Notifications: ${notificationsQuery.docs.length}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print("❌ Firestore test failed: $e");

      String errorMessage = 'Connection test failed';

      if (e is FirebaseException) {
        print("🔥 Firebase Exception: ${e.code} - ${e.message}");
        switch (e.code) {
          case 'permission-denied':
            errorMessage = 'Permission denied - Check Firestore rules';
            break;
          case 'unavailable':
            errorMessage = 'Service unavailable - Check internet';
            break;
          case 'unauthenticated':
            errorMessage = 'Not authenticated - Please login again';
            break;
          default:
            errorMessage = 'Firebase error: ${e.code}';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
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

  // Show success message
  void _showSuccessSnackBar(String message) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: ModernTheme.primaryGradient,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'Loading CivicLink...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
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
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildQuickStats(),
                              const SizedBox(height: 32),
                              _buildQuickActions(),
                              const SizedBox(height: 32),
                              _buildRecentActivity(),
                              const SizedBox(height: 40), // Bottom padding
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // Test button (remove this when everything works)
      floatingActionButton: FloatingActionButton(
        onPressed: _testFirestoreConnection,
        backgroundColor: Colors.red,
        child: const Icon(Icons.bug_report, color: Colors.white),
        tooltip: 'Test Firestore Connection',
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CivicLink',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Report. Track. Resolve.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Menu with Settings
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                      ),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'profile':
                          _editProfile();
                          break;
                        case 'settings':
                          _navigateToSettings();
                          break;
                        case 'logout':
                          _signOut();
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person),
                                SizedBox(width: 12),
                                Text('Profile'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(Icons.settings),
                                SizedBox(width: 12),
                                Text('Settings'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 12),
                                Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Welcome Message
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData?.fullName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _userData?.isAdmin == true
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _userData?.userType.toUpperCase() ?? 'CITIZEN',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: ModernTheme.accentGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Live',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AnimatedCounter(
                count: _resolvedCount,
                label: 'Resolved',
                color: ModernTheme.success,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedCounter(
                count: _pendingCount,
                label: 'Pending',
                color: ModernTheme.warning,
                icon: Icons.pending_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedCounter(
                count: _thisMonthCount,
                label: 'This Month',
                color: ModernTheme.info,
                icon: Icons.trending_up_outlined,
              ),
            ),
          ],
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ModernTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          children: [
            _buildGradientActionCard(
              icon: Icons.report_problem_outlined,
              title: 'Report Issue',
              subtitle: 'Report new problems',
              gradient: ModernTheme.errorGradient,
              onTap: () => _navigateToReportIssue(),
            ),
            _buildGradientActionCard(
              icon: Icons.track_changes_outlined,
              title: 'Track Issues',
              subtitle: 'Monitor your reports',
              gradient: ModernTheme.accentGradient,
              onTap: () async {
                print("📱 Navigating to My Issues screen...");
                // Handle return from My Issues screen

                // Also handle return from My Issues screen
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyIssuesScreen(),
                  ),
                );
                // Refresh if needed
                if (result == true) {
                  await _loadData();
                }
              },
            ),
            _buildGradientActionCard(
              icon: Icons.map_outlined,
              title: 'Issue Map',
              subtitle: 'View nearby issues',
              gradient: ModernTheme.successGradient,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IssueMapScreen(),
                  ),
                );
              },
            ),
            _buildNotificationActionCard(),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationActionCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: ModernTheme.warningGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ModernTheme.warningGradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    // Notification badge
                    FutureBuilder<int>(
                      future: NotificationService().getUnreadCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();

                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Stay updated',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    // Get the most recent 3 issues
    final recentIssues = _userIssues.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                print("📋 Navigating to view all issues...");
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyIssuesScreen(),
                  ),
                );
                if (result == true) {
                  await _loadData();
                }
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: ModernTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Show real issues or empty state
        if (recentIssues.isEmpty)
          _buildEmptyActivityState()
        else
          ...recentIssues
              .map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActivityItem(issue),
                ),
              )
              .toList(),
      ],
    );
  }

  Widget _buildEmptyActivityState() {
    return ModernCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: ModernTheme.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No issues reported yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by reporting your first community issue',
            style: TextStyle(fontSize: 14, color: ModernTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GradientButton(
            text: 'Report Issue',
            onPressed: () => _navigateToReportIssue(),
            icon: Icons.add,
            width: 140,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IssueModel issue) {
    final statusColor = _getStatusColor(issue.status);
    final gradient = _getGradientForCategory(issue.category);

    return ModernCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IssueDetailScreen(issue: issue),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(issue.category),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ModernTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'Reported ${_getTimeAgo(issue.createdAt)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ModernTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          ModernStatusChip(
            text: _getStatusText(issue.status),
            color: statusColor,
          ),
        ],
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

  // UPDATED: Map categories to new 5 departments
  LinearGradient _getGradientForCategory(String category) {
    switch (category) {
      case 'Road and Transportation':
      case 'Road & Transportation':
        return ModernTheme.warningGradient;
      case 'Water and Sewage':
      case 'Water & Sewerage':
        return ModernTheme.primaryGradient;
      case 'Electricity and Power':
      case 'Electricity':
        return ModernTheme.accentGradient;
      case 'Public Safety':
        return ModernTheme.errorGradient;
      case 'Environmental Issues':
        return ModernTheme.successGradient;
      default:
        return ModernTheme.accentGradient;
    }
  }

  // UPDATED: Map icons to new 5 departments
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Road and Transportation':
      case 'Road & Transportation':
        return Icons.construction;
      case 'Water and Sewage':
      case 'Water & Sewerage':
        return Icons.water_drop;
      case 'Electricity and Power':
      case 'Electricity':
        return Icons.electrical_services;
      case 'Public Safety':
        return Icons.security;
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.rocket_launch, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('$feature feature coming soon!')),
          ],
        ),
        backgroundColor: ModernTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Add these widget definitions at the bottom of your home_screen.dart file
// ModernCard Widget

// ModernStatusChip Widget

// AnimatedCounter Widget
class AnimatedCounter extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const AnimatedCounter({
    Key? key,
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
