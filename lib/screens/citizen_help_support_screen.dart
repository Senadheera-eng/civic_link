// screens/citizen_help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/modern_theme.dart';

class CitizenHelpSupportScreen extends StatefulWidget {
  const CitizenHelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<CitizenHelpSupportScreen> createState() =>
      _CitizenHelpSupportScreenState();
}

class _CitizenHelpSupportScreenState extends State<CitizenHelpSupportScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Add controllers for email support
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _searchQuery = '';
  int _selectedTabIndex = 0;
  String _selectedPriority = 'Medium';
  bool _isLoading = false;

  final List<String> _categories = [
    'Getting Started',
    'Reporting Issues',
    'Tracking Issues',
    'Account Management',
    'Troubleshooting',
    'Email Support',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
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
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
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
                        _buildSearchBar(),
                        _buildTabBar(),
                        Expanded(child: _buildContent()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Get help and guidance for CivicLink',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ModernTheme.primaryBlue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Search for help topics...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: ModernTheme.primaryBlue),
          suffixIcon: Icon(Icons.mic, color: ModernTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? ModernTheme.primaryGradient : null,
                color: isSelected ? null : ModernTheme.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.transparent
                          : ModernTheme.textTertiary.withOpacity(0.3),
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : ModernTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_selectedTabIndex == 0) _buildGettingStarted(),
          if (_selectedTabIndex == 1) _buildReportingIssues(),
          if (_selectedTabIndex == 2) _buildTrackingIssues(),
          if (_selectedTabIndex == 3) _buildAccountManagement(),
          if (_selectedTabIndex == 4) _buildTroubleshooting(),
          if (_selectedTabIndex == 5) _buildEmailSupport(),
        ],
      ),
    );
  }

  Widget _buildGettingStarted() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🚀 Welcome to CivicLink!'),
        const SizedBox(height: 16),

        _buildGuideCard(
          title: 'What is CivicLink?',
          content:
              'CivicLink is a community problem reporting app that helps citizens report issues like broken roads, streetlight problems, water leaks, and other community concerns directly to local authorities.',
          icon: Icons.info_outline,
        ),

        _buildGuideCard(
          title: 'How it Works',
          content: '''
1. 📍 Report: Take a photo and describe the issue
2. 📍 Location: We automatically detect your location
3. 🏛️ Route: Your report goes to the right department
4. 🔔 Track: Get notifications on progress
5. ✅ Resolve: Issues get fixed faster!
          ''',
          icon: Icons.how_to_reg,
        ),

        _buildGuideCard(
          title: 'First Steps',
          content: '''
• Complete your profile in Settings
• Enable location services for accurate reporting
• Turn on notifications to stay updated
• Explore the map to see community issues
          ''',
          icon: Icons.checklist,
        ),
      ],
    );
  }

  Widget _buildReportingIssues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📝 How to Report Issues'),
        const SizedBox(height: 16),

        _buildGuideCard(
          title: 'Step-by-Step Reporting',
          content: '''
1. Tap "Report Issue" on the home screen
2. Take clear photos of the problem
3. Write a descriptive title
4. Choose the correct category
5. Set priority level (Low/Medium/High/Critical)
6. Add detailed description
7. Confirm location is accurate
8. Submit your report
          ''',
          icon: Icons.assignment,
        ),

        _buildGuideCard(
          title: 'Taking Good Photos',
          content: '''
• Take multiple angles of the issue
• Ensure good lighting
• Include landmarks for context
• Show the full extent of the problem
• Avoid blurry or dark photos
          ''',
          icon: Icons.camera_alt,
        ),

        _buildGuideCard(
          title: 'Choosing Categories',
          content: '''
🚧 Road & Transportation: Potholes, road damage, traffic issues
💧 Water & Sewerage: Leaks, blockages, water quality
⚡ Electricity: Power outages, faulty lines
🛡️ Public Safety: Dangerous areas, security concerns
🗑️ Waste Management: Garbage collection, illegal dumping
🌳 Parks & Recreation: Damaged facilities, maintenance
💡 Street Lighting: Broken lights, dark areas
🏢 Public Buildings: Facility issues
🚦 Traffic Management: Signal problems, signs
🌍 Environmental Issues: Pollution, tree hazards
          ''',
          icon: Icons.category,
        ),

        _buildGuideCard(
          title: 'Priority Levels',
          content: '''
🔴 Critical: Immediate danger to public safety
🟠 High: Significant impact, needs urgent attention
🟡 Medium: Important but not urgent
🟢 Low: Minor issues, can wait for scheduled maintenance
          ''',
          icon: Icons.priority_high,
        ),
      ],
    );
  }

  Widget _buildTrackingIssues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📊 Tracking Your Issues'),
        const SizedBox(height: 16),

        _buildGuideCard(
          title: 'Issue Status Meanings',
          content: '''
⏳ Pending: Your report has been submitted and is awaiting review
🔧 In Progress: Authorities are actively working on the issue
✅ Resolved: The issue has been fixed
❌ Rejected: The report was declined (with reason provided)
          ''',
          icon: Icons.track_changes,
        ),

        _buildGuideCard(
          title: 'Using My Issues Screen',
          content: '''
• View all your reported issues
• Filter by status (All, Pending, In Progress, Resolved)
• Tap any issue to see detailed progress
• Send manual reminders for pending issues
• Track resolution timeline
          ''',
          icon: Icons.list_alt,
        ),

        _buildGuideCard(
          title: 'Notifications',
          content: '''
You'll receive notifications when:
• Your issue status changes
• Authorities add comments or updates
• Resolution is completed
• Reminders are due
          ''',
          icon: Icons.notifications,
        ),

        _buildGuideCard(
          title: 'Manual Reminders',
          content: '''
For issues pending more than 24 hours:
• Go to "My Issues"
• Find the pending issue
• Tap "Send Reminder"
• Add a personal message
• One reminder per day allowed
          ''',
          icon: Icons.schedule_send,
        ),
      ],
    );
  }

  Widget _buildAccountManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('👤 Managing Your Account'),
        const SizedBox(height: 16),

        _buildGuideCard(
          title: 'Profile Settings',
          content: '''
• Update your name and personal information
• Change your password regularly
• Verify your email address
• Upload a profile picture
          ''',
          icon: Icons.person,
        ),

        _buildGuideCard(
          title: 'Notification Preferences',
          content: '''
Customize your notifications:
• Enable/disable push notifications
• Set email notification preferences
• Choose notification types
• Set quiet hours
          ''',
          icon: Icons.settings_applications,
        ),

        _buildGuideCard(
          title: 'Privacy Settings',
          content: '''
• Control location sharing
• Manage data visibility
• Review privacy policy
• Export your data
• Delete account (if needed)
          ''',
          icon: Icons.privacy_tip,
        ),

        _buildGuideCard(
          title: 'App Preferences',
          content: '''
• Switch between light/dark mode
• Change language settings
• Enable/disable sounds
• Update app when available
          ''',
          icon: Icons.tune,
        ),
      ],
    );
  }

  Widget _buildTroubleshooting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🔧 Common Issues & Solutions'),
        const SizedBox(height: 16),

        _buildGuideCard(
          title: 'App Not Loading',
          content: '''
Try these steps:
1. Check your internet connection
2. Close and reopen the app
3. Restart your device
4. Update the app from app store
5. Clear app cache (Android)
          ''',
          icon: Icons.refresh,
        ),

        _buildGuideCard(
          title: 'Location Issues',
          content: '''
If location is not working:
1. Enable location services in device settings
2. Grant location permission to CivicLink
3. Turn on "High Accuracy" location mode
4. Restart the app
5. Check if GPS is working in other apps
          ''',
          icon: Icons.location_off,
        ),

        _buildGuideCard(
          title: 'Camera Problems',
          content: '''
Camera not working:
1. Grant camera permission to CivicLink
2. Check if camera works in other apps
3. Restart the app
4. Clear app cache
5. Update the app
          ''',
          icon: Icons.camera_alt,
        ),

        _buildGuideCard(
          title: 'Notification Issues',
          content: '''
Not receiving notifications:
1. Check notification settings in app
2. Enable notifications in device settings
3. Check "Do Not Disturb" mode
4. Update the app
5. Re-login to your account
          ''',
          icon: Icons.notifications_off,
        ),

        _buildGuideCard(
          title: 'Login Problems',
          content: '''
Can't login:
1. Check email and password
2. Use "Forgot Password" option
3. Check internet connection
4. Clear app cache
5. Contact support if issue persists
          ''',
          icon: Icons.login,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ModernTheme.textPrimary,
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String content,
    required IconData icon,
    Widget? customContent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ModernTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ModernTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (customContent != null)
              customContent
            else
              Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  color: ModernTheme.textSecondary,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSupport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📧 Contact Support Team'),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ModernTheme.accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ModernTheme.accent.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.support_agent, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Message Directly',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Compose and send your support request directly through the app.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Email Composition Form
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ModernTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ModernTheme.primaryBlue.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ModernTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.email,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Compose Support Message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ModernTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // To Field (Read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ModernTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ModernTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: ModernTheme.primaryBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'To: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ModernTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'CivicLink Support Team',
                      style: TextStyle(
                        color: ModernTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Subject Field
              const Text(
                'Subject *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ModernTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'Brief description of your issue...',
                  prefixIcon: const Icon(
                    Icons.subject,
                    color: ModernTheme.primaryBlue,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ModernTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ModernTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ModernTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Message Field
              const Text(
                'Message *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ModernTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: '''Please describe your issue in detail...

Include:
• What you were trying to do
• What happened instead
• Any error messages you saw
• Steps to reproduce the issue
• Your device information (if relevant)

The more details you provide, the better we can help you!''',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ModernTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ModernTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ModernTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 20),

              // Priority Selection
              const Text(
                'Priority Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ModernTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityChip(
                    'Low',
                    ModernTheme.success,
                    Icons.low_priority,
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                    'Medium',
                    ModernTheme.warning,
                    Icons.priority_high,
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                    'High',
                    ModernTheme.error,
                    Icons.report_problem,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendSupportMessage,
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.send, size: 20),
                  label: Text(
                    _isLoading ? 'Sending...' : 'Send Message',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ModernTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Quick Tips
        _buildGuideCard(
          title: 'Tips for Better Support',
          content: '''
🎯 Be specific: Describe exactly what you were doing when the issue occurred.

📱 Include device info: Mention your device type and app version if relevant.

📷 Screenshots help: If you can't attach images here, describe what you see.

🕐 Check response: We typically respond within 24-48 hours during business days.

🚨 Urgent issues: For safety emergencies, contact local authorities first.
          ''',
          icon: Icons.lightbulb,
        ),

        // Contact Info
        _buildGuideCard(
          title: 'Alternative Contact Methods',
          content: '''
📧 Direct Email: civiclink.official@gmail.com
📞 Phone Support: Available during business hours
🌐 Website: Visit our help center for FAQs

Business Hours:
Monday - Friday: 9:00 AM - 6:00 PM
Saturday: 10:00 AM - 4:00 PM
Sunday: Closed
          ''',
          icon: Icons.contact_support,
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String priority, Color color, IconData icon) {
    final isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                priority,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendSupportMessage() async {
    // Validate form
    if (_subjectController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a subject for your message');
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your message');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate sending email (replace with actual email service)
      await _simulateEmailSending();

      // Clear form
      _subjectController.clear();
      _messageController.clear();
      setState(() => _selectedPriority = 'Medium');

      // Show success message
      _showSuccessSnackBar(
        'Message sent successfully! We\'ll respond within 24-48 hours.',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to send message. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _simulateEmailSending() async {
    // This simulates the email sending process
    // In a real app, you would integrate with an email service like:
    // - EmailJS
    // - SendGrid
    // - Firebase Functions with Nodemailer
    // - Your own backend API

    await Future.delayed(const Duration(seconds: 2));

    // Here you would make the actual API call to send the email
    print('Sending support email:');
    print('To: civiclink.official@gmail.com');
    print('Subject: ${_subjectController.text}');
    print('Priority: $_selectedPriority');
    print('Message: ${_messageController.text}');
  }

  void _copyEmail() {
    // This method is no longer needed
  }

  void _showEmailDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.email, color: ModernTheme.primaryBlue),
                SizedBox(width: 12),
                Text('Contact Support'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send an email to our support team:'),
                SizedBox(height: 12),
                SelectableText(
                  'civiclink.official@gmail.com',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.primaryBlue,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Include your issue description and any relevant screenshots for faster assistance.',
                  style: TextStyle(
                    color: ModernTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _copyEmail();
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Email'),
              ),
            ],
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: ModernTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: ModernTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Helper widget for ModernCard (if not already defined)
class ModernCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool elevated;

  const ModernCard({
    Key? key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.elevated = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? ModernTheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow:
            elevated
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
                : ModernTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}
