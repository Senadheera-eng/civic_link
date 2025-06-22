// screens/home_screen.dart (COLORFUL PROFESSIONAL VERSION)
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  UserModel? _userData;
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<Animation<Offset>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    // Create staggered animations for feature cards with valid intervals
    _cardAnimations = List.generate(4, (index) {
      double startTime = 0.2 + (index * 0.1);
      double endTime = 0.6 + (index * 0.1); // Fixed: ensure end <= 1.0
      
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          startTime,
          endTime.clamp(0.0, 1.0), // Ensure end doesn't exceed 1.0
          curve: Curves.easeOutBack,
        ),
      ));
    });
    
    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE3F2FD),
              Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Picture
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Welcome Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _userData?.fullName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StatusBadge(
                      text: _userData?.userType.toUpperCase() ?? 'CITIZEN',
                      color: Colors.white,
                      icon: _userData?.isAdmin == true ? Icons.admin_panel_settings : Icons.person,
                    ),
                  ],
                ),
              ),
              
              // Menu Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'logout') _signOut();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline),
                          SizedBox(width: 8),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined),
                          SizedBox(width: 8),
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
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Active Reports',
            value: '3',
            icon: Icons.report_problem,
            gradient: AppTheme.warningGradient,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Resolved',
            value: '12',
            icon: Icons.check_circle,
            gradient: AppTheme.successGradient,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'This Month',
            value: '8',
            icon: Icons.trending_up,
            gradient: [AppTheme.info, AppTheme.accent],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions Title
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'What would you like to do today?',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Feature Cards Grid
          SizedBox(
            height: 320, // Fixed height to prevent rendering issues
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1, // Adjusted aspect ratio
              children: [
                AnimatedBuilder(
                  animation: _cardAnimations[0],
                  builder: (context, child) {
                    return SlideTransition(
                      position: _cardAnimations[0],
                      child: FeatureCard(
                        icon: Icons.report_problem,
                        title: 'Report Issue',
                        subtitle: 'Report community problems',
                        gradient: AppTheme.warningGradient,
                        onTap: () => _showComingSoon('Report Issue'),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _cardAnimations[1],
                  builder: (context, child) {
                    return SlideTransition(
                      position: _cardAnimations[1],
                      child: FeatureCard(
                        icon: Icons.track_changes,
                        title: 'Track Issues',
                        subtitle: 'Monitor your reports',
                        gradient: [AppTheme.info, AppTheme.accent],
                        onTap: () => _showComingSoon('Issue Tracking'),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _cardAnimations[2],
                  builder: (context, child) {
                    return SlideTransition(
                      position: _cardAnimations[2],
                      child: FeatureCard(
                        icon: Icons.map,
                        title: 'Issue Map',
                        subtitle: 'View nearby issues',
                        gradient: AppTheme.successGradient,
                        onTap: () => _showComingSoon('Issue Map'),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _cardAnimations[3],
                  builder: (context, child) {
                    return SlideTransition(
                      position: _cardAnimations[3],
                      child: FeatureCard(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Stay updated',
                        gradient: AppTheme.primaryGradient,
                        onTap: () => _showComingSoon('Notifications'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Recent Activity Section
          _buildRecentActivity(),
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
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _showComingSoon('View All'),
              child: const Text('View All'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Activity Cards
        _buildActivityCard(
          title: 'Pothole on Main Street',
          subtitle: 'Reported 2 days ago',
          status: 'In Progress',
          statusColor: AppTheme.info,
          icon: Icons.construction,
        ),
        
        const SizedBox(height: 12),
        
        _buildActivityCard(
          title: 'Broken Street Light',
          subtitle: 'Reported 1 week ago',
          status: 'Resolved',
          statusColor: AppTheme.success,
          icon: Icons.lightbulb,
        ),
        
        const SizedBox(height: 12),
        
        _buildActivityCard(
          title: 'Water Leak Issue',
          subtitle: 'Reported 3 days ago',
          status: 'Pending',
          statusColor: AppTheme.warning,
          icon: Icons.water_drop,
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 24),
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
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          StatusBadge(
            text: status,
            color: statusColor,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction, color: Colors.white),
            const SizedBox(width: 8),
            Text('$feature feature coming soon!'),
          ],
        ),
        backgroundColor: AppTheme.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

