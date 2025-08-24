// screens/citizen_help_support_screen.dart (PROFESSIONAL GUIDELINES ONLY)
import 'package:flutter/material.dart';
import '../theme/modern_theme.dart';

class CitizenHelpSupportScreen extends StatefulWidget {
  const CitizenHelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<CitizenHelpSupportScreen> createState() =>
      _CitizenHelpSupportScreenState();
}

class _CitizenHelpSupportScreenState extends State<CitizenHelpSupportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildModernHeader(),
                _buildUltraModernTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGettingStartedTab(),
                      _buildReportingTab(),
                      _buildTrackingTab(),
                      _buildMapExplorationTab(),
                      _buildTipsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF667EEA)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'Help & User Guide',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 3,
                width: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white54, Colors.white, Colors.white54],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildUltraModernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(6),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF6B7280),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          splashFactory: NoSplash.splashFactory,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          tabs: [
            _buildModernTab(Icons.rocket_launch_rounded, 'Getting Started', 0),
            _buildModernTab(Icons.report_gmailerrorred_rounded, 'Reporting', 1),
            _buildModernTab(Icons.track_changes_rounded, 'Tracking', 2),
            _buildModernTab(Icons.map_rounded, 'Map Explorer', 3),
            _buildModernTab(Icons.auto_awesome_rounded, 'Pro Tips', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTab(IconData icon, String label, int index) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;
        return Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration:
              isSelected
                  ? BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  )
                  : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                child: Text(label),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGettingStartedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildStepByStepCard('Your First Steps with CivicLink', [
            StepItem(
              number: 1,
              title: 'Create Your Account',
              description:
                  'Sign up as a citizen to start reporting community issues',
              details: [
                'Choose "Citizen" during registration',
                'Complete your profile with accurate information',
                'Verify your email address',
                'Enable location services for better reporting',
              ],
              icon: Icons.person_add_rounded,
              color: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
            ),
            StepItem(
              number: 2,
              title: 'Explore the Dashboard',
              description:
                  'Familiarize yourself with the main features and navigation',
              details: [
                'Home screen shows your issue statistics',
                'Quick actions for common tasks',
                'Recent activity and notifications',
                'Easy access to all major features',
              ],
              icon: Icons.dashboard_rounded,
              color: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
            ),
            StepItem(
              number: 3,
              title: 'Set Up Notifications',
              description:
                  'Stay informed about your reports and community updates',
              details: [
                'Enable push notifications in settings',
                'Choose notification preferences',
                'Set quiet hours if needed',
                'Get real-time updates on your issues',
              ],
              icon: Icons.notifications_active_rounded,
              color: const LinearGradient(
                colors: [Color(0xFFFD79A8), Color(0xFFFDCB6E)],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildFeatureOverviewCard(),
        ],
      ),
    );
  }

  Widget _buildReportingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStepByStepCard('Perfect Report in 8 Steps', [
            StepItem(
              number: 1,
              title: 'Choose the Right Category',
              description:
                  'Select the most accurate category for faster routing',
              details: [
                'Road & Transportation: Potholes, traffic issues, broken roads',
                'Water & Sewerage: Water leaks, drainage problems, pipe issues',
                'Public Safety: Security concerns, dangerous areas, lighting',
                'Waste Management: Garbage collection, illegal dumping',
                'Electricity: Power outages, damaged cables, street lighting',
              ],
              icon: Icons.category_rounded,
              color: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
            ),
            StepItem(
              number: 2,
              title: 'Write a Clear Title',
              description: 'Make your title specific and actionable',
              details: [
                'Use specific locations: "Main Street pothole near City Mall"',
                'Include the problem type: "Water leak causing road damage"',
                'Avoid vague titles like "Problem here" or "Fix this"',
                'Keep it under 50 characters for better readability',
              ],
              icon: Icons.title_rounded,
              color: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
            ),
            StepItem(
              number: 3,
              title: 'Set the Right Priority',
              description:
                  'Help officials understand the urgency of your report',
              details: [
                'Critical: Immediate danger (gas leaks, major accidents)',
                'High: Safety risks (broken traffic lights, deep potholes)',
                'Medium: Quality of life issues (noise, minor damage)',
                'Low: Cosmetic problems (faded signs, minor wear)',
              ],
              icon: Icons.priority_high_rounded,
              color: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
            ),
            StepItem(
              number: 4,
              title: 'Add Quality Photos',
              description:
                  'Visual evidence makes your report 10x more effective',
              details: [
                'Take photos in good lighting conditions',
                'Include wide shots for context and close-ups for detail',
                'Show the extent of the problem clearly',
                'Multiple angles provide complete picture',
                'Include reference objects for scale when helpful',
              ],
              icon: Icons.photo_camera_rounded,
              color: const LinearGradient(
                colors: [Color(0xFFFD79A8), Color(0xFFFDCB6E)],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildDosDontsCard(),
        ],
      ),
    );
  }

  Widget _buildTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusGuideCard(),
          const SizedBox(height: 24),
          _buildStepByStepCard('Effective Tracking Strategy', [
            StepItem(
              number: 1,
              title: 'Monitor "My Issues" Regularly',
              description: 'Stay updated on all your reported issues',
              details: [
                'Check your issues dashboard weekly',
                'Use filters to organize by status',
                'Track resolution timeframes',
                'Note patterns in response times',
              ],
              icon: Icons.monitor_rounded,
              color: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
            ),
            StepItem(
              number: 2,
              title: 'Understand Official Responses',
              description: 'Learn how to interpret updates from authorities',
              details: [
                'Read admin notes carefully for detailed updates',
                'Check timestamps to track progress speed',
                'Look for assignment information',
                'Understand estimated completion dates',
              ],
              icon: Icons.admin_panel_settings_rounded,
              color: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
            ),
            StepItem(
              number: 3,
              title: 'Use Smart Reminders',
              description: 'Know when and how to follow up professionally',
              details: [
                'Wait at least 7 days before first reminder',
                'Use the built-in reminder feature',
                'Be polite and professional in messages',
                'Provide additional information if available',
              ],
              icon: Icons.notifications_active_rounded,
              color: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildNotificationTipsCard(),
        ],
      ),
    );
  }

  Widget _buildMapExplorationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMapFeaturesCard(),
          const SizedBox(height: 24),
          _buildStepByStepCard('Advanced Map Features', [
            StepItem(
              number: 1,
              title: 'Smart Filtering System',
              description: 'Find exactly what you\'re looking for',
              details: [
                'Filter by category to see specific issue types',
                'Adjust radius to explore different areas',
                'Use status filters to see resolved vs pending',
                'Combine filters for precise searches',
              ],
              icon: Icons.filter_alt_rounded,
              color: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
            ),
            StepItem(
              number: 2,
              title: 'Location Intelligence',
              description: 'Leverage location-based insights',
              details: [
                'Tap anywhere on map to explore that area',
                'Set custom search locations beyond your area',
                'Discover issue patterns in different neighborhoods',
                'Compare issue density across locations',
              ],
              icon: Icons.location_on_rounded,
              color: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
            ),
            StepItem(
              number: 3,
              title: 'Community Awareness',
              description: 'Stay informed about your surroundings',
              details: [
                'Check for issues before planning routes',
                'Report similar problems you encounter',
                'Support others by providing additional information',
                'Use insights for community advocacy',
              ],
              icon: Icons.groups_rounded,
              color: const LinearGradient(
                colors: [Color(0xFFFD79A8), Color(0xFFFDCB6E)],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProTipsCard(),
          const SizedBox(height: 24),
          _buildTimingTipsCard(),
          const SizedBox(height: 24),
          _buildCommunityImpactCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.waving_hand_rounded, color: Colors.white, size: 52),
          SizedBox(height: 18),
          Text(
            'Welcome to CivicLink!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Your powerful tool for community improvement',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepByStepCard(String title, List<StepItem> steps) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: 0.3,
              ),
            ),
          ),
          ...steps.map((step) => _buildStepItem(step)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStepItem(StepItem step) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: step.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: step.color.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              step.number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          step.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            step.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        children: [
          Column(
            children:
                step.details
                    .map(
                      (detail) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 8, right: 16),
                              decoration: BoxDecoration(
                                gradient: step.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: step.color.colors.first.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                detail,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF374151),
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Features at a Glance',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            Icons.report_problem_rounded,
            'Issue Reporting',
            'Submit detailed reports with photos and location',
            const Color(0xFFFF6B6B),
          ),
          _buildFeatureItem(
            Icons.track_changes_rounded,
            'Progress Tracking',
            'Monitor your issues from submission to resolution',
            const Color(0xFF4ECDC4),
          ),
          _buildFeatureItem(
            Icons.map_rounded,
            'Interactive Map',
            'Explore community issues on an interactive map',
            const Color(0xFF667EEA),
          ),
          _buildFeatureItem(
            Icons.notifications_rounded,
            'Smart Notifications',
            'Get real-time updates on your reports and community',
            const Color(0xFFFD79A8),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosDontsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reporting Do\'s and Don\'ts',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withOpacity(0.1),
                            const Color(0xFF10B981).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'DO',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                [
                                      '✓ Be specific and detailed',
                                      '✓ Include clear photos',
                                      '✓ Use accurate location',
                                      '✓ Choose correct category',
                                      '✓ Set appropriate priority',
                                    ]
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 3,
                                        ),
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFEF4444).withOpacity(0.1),
                            const Color(0xFFEF4444).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.cancel_rounded,
                              color: Color(0xFFEF4444),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'DON\'T',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                [
                                      '✗ Use vague descriptions',
                                      '✗ Submit blurry photos',
                                      '✗ Wrong location info',
                                      '✗ Duplicate reports',
                                      '✗ Inappropriate content',
                                    ]
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 3,
                                        ),
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
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

  Widget _buildStatusGuideCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Understanding Issue Status',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusItem(
            'Pending',
            'Issue has been submitted and is awaiting review',
            const Color(0xFFF59E0B),
            Icons.pending_rounded,
          ),
          _buildStatusItem(
            'In Progress',
            'Officials are actively working on resolving the issue',
            const Color(0xFF3B82F6),
            Icons.construction_rounded,
          ),
          _buildStatusItem(
            'Resolved',
            'Issue has been fixed and marked as complete',
            const Color(0xFF10B981),
            Icons.check_circle_rounded,
          ),
          _buildStatusItem(
            'Rejected',
            'Issue was reviewed but cannot be addressed',
            const Color(0xFFEF4444),
            Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String status,
    String description,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTipsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFD79A8), Color(0xFFFDCB6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFD79A8).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Smart Notification Tips',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enable notifications to stay updated on your issues and get instant alerts when officials respond to your reports.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMapFeaturesCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Map Features Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          _buildMapFeatureItem(
            Icons.filter_alt_rounded,
            'Smart Filters',
            'Filter issues by category, status, distance, and more',
            const Color(0xFF3B82F6),
          ),
          _buildMapFeatureItem(
            Icons.my_location_rounded,
            'Location Services',
            'Auto-detect your location or select custom areas',
            const Color(0xFF10B981),
          ),
          _buildMapFeatureItem(
            Icons.zoom_in_rounded,
            'Interactive Zoom',
            'Zoom in/out to explore different neighborhood levels',
            const Color(0xFFF59E0B),
          ),
          _buildMapFeatureItem(
            Icons.info_rounded,
            'Issue Details',
            'Tap any marker to see full issue information',
            const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFeatureItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.06), color.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProTipsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Expert Pro Tips',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProTipItem(
            '📸 Photography Mastery',
            'Take photos during daylight hours for better visibility. Include context shots (wide view) and detail shots (close-up) for complete documentation.',
          ),
          _buildProTipItem(
            '📍 Location Precision',
            'Use the most specific address possible. Include nearby landmarks or businesses to help officials locate the exact spot quickly.',
          ),
          _buildProTipItem(
            '⏰ Timing Strategy',
            'Report issues early in the week (Monday-Wednesday) for faster response times. Avoid reporting during holidays or weekends unless urgent.',
          ),
          _buildProTipItem(
            '🔄 Follow-up Protocol',
            'Wait at least 7 business days before sending first reminder. Use polite, professional language and provide any new relevant information.',
          ),
          _buildProTipItem(
            '🎯 Priority Setting',
            'Reserve "Critical" for genuine emergencies only. Most issues are "Medium" priority - overusing "High" reduces effectiveness.',
          ),
        ],
      ),
    );
  }

  Widget _buildProTipItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFFAFBFC)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingTipsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Optimal Timing Guide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Best times to report: Monday-Wednesday 9AM-11AM for fastest response. Emergency issues can be reported 24/7.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityImpactCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Maximize Community Impact',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Quality reports lead to faster resolutions. Your detailed, well-documented issues help officials prioritize and allocate resources effectively.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class StepItem {
  final int number;
  final String title;
  final String description;
  final List<String> details;
  final IconData icon;
  final LinearGradient color;

  StepItem({
    required this.number,
    required this.title,
    required this.description,
    required this.details,
    required this.icon,
    required this.color,
  });
}
