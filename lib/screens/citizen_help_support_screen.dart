// screens/citizen_help_support_screen.dart (FIXED VERSION)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/modern_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_button.dart';

class CitizenHelpSupportScreen extends StatefulWidget {
  const CitizenHelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<CitizenHelpSupportScreen> createState() => _CitizenHelpSupportScreenState();
}

class _CitizenHelpSupportScreenState extends State<CitizenHelpSupportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Email form controllers
  final _fromEmailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isComposing = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAnimations();
    _loadUserEmail();
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

  void _loadUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _fromEmailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _fromEmailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final fromEmail = _fromEmailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (fromEmail.isEmpty || subject.isEmpty || message.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(fromEmail)) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    setState(() => _isSending = true);

    try {
      // Send email to Firestore for admin processing
      await FirebaseFirestore.instance.collection('support_emails').add({
        'from': fromEmail,
        'to': 'civiclink.official@gmail.com',
        'subject': subject,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      _showSuccessSnackBar('Email sent successfully! We will respond within 24-48 hours.');
      
      // Clear the form
      _subjectController.clear();
      _messageController.clear();
      setState(() => _isComposing = false);
      
    } catch (e) {
      _showErrorSnackBar('Failed to send email. Please try again.');
    } finally {
      setState(() => _isSending = false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildProfessionalHeader(),
              if (!_isComposing) _buildColorfulTabBar(),
              Expanded(
                child: _isComposing 
                  ? _buildSimpleEmailInterface()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGettingStartedTab(),
                        _buildFeaturesGuideTab(),
                        _buildEmailSupportTab(),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
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
              const Spacer(),
              const Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Icon(Icons.support_agent, size: 32, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'We\'re Here to Help!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Get the most out of CivicLink',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorfulTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rocket_launch, size: 16),
                SizedBox(width: 4),
                Flexible(child: Text('Getting Started', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore, size: 16),
                SizedBox(width: 4),
                Flexible(child: Text('Features', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, size: 16),
                SizedBox(width: 4),
                Flexible(child: Text('Email Support', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGettingStartedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildColorfulStepCard(
            1,
            'Create Your First Report',
            'Tap the "Report Issue" button to get started',
            Icons.add_circle,
            const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
            [
              'Choose a clear, descriptive title',
              'Select the correct category',
              'Add photos for better understanding',
              'Your location is detected automatically',
            ],
          ),
          _buildColorfulStepCard(
            2,
            'Track Your Progress',
            'Monitor all your reports in "My Issues"',
            Icons.timeline,
            const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
            [
              'See real-time status updates',
              'Get notifications when things change',
              'Send reminders for pending issues',
              'View detailed response from officials',
            ],
          ),
          _buildColorfulStepCard(
            3,
            'Explore Community Issues',
            'Check the interactive map for nearby issues',
            Icons.map,
            const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            [
              'Filter by distance and category',
              'Tap markers to see issue details',
              'Find issues in your neighborhood',
              'Switch between map and list views',
            ],
          ),
          const SizedBox(height: 16),
          _buildSuccessTipsCard(),
        ],
      ),
    );
  }

  Widget _buildFeaturesGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFeatureCard(
            'Reporting Issues',
            'Master effective issue reporting',
            Icons.report_gmailerrorred,
            const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
            [
              'Choose descriptive titles',
              'Select accurate categories',
              'Include multiple photos',
              'Write clear descriptions',
              'Set appropriate priority levels',
            ],
          ),
          _buildFeatureCard(
            'Issue Tracking',
            'Stay informed about progress',
            Icons.track_changes,
            const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
            [
              'Check "My Issues" regularly',
              'Understand different statuses',
              'Read official responses',
              'Send polite reminders',
            ],
          ),
          _buildFeatureCard(
            'Community Map',
            'Explore community awareness',
            Icons.public,
            const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            [
              'Use filters for specific issues',
              'Adjust radius for nearby problems',
              'Tap custom locations to explore',
              'Report similar issues you notice',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSupportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contact Information Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Email Icon and Address
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.email,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'civiclink.official@gmail.com',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Response Time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Response: 24-48 hours',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Common Questions Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Color(0xFFFF6B6B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Common Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Question 1
                _buildSimpleQuestionItem(
                  'How do I report an urgent issue?',
                  'Select "Critical" or "High" priority when creating your report.',
                ),
                
                const SizedBox(height: 12),
                
                // Question 2
                _buildSimpleQuestionItem(
                  'Why can\'t I see my issue on the map?',
                  'New issues may take a few minutes to appear.',
                ),
                
                const SizedBox(height: 12),
                
                // Question 3
                _buildSimpleQuestionItem(
                  'How do I get faster responses?',
                  'Include clear photos and detailed descriptions.',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Compose Email Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => setState(() => _isComposing = true),
                borderRadius: BorderRadius.circular(16),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Compose Email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleEmailInterface() {
    return Container(
      color: const Color(0xFF2D3748),
      child: Column(
        children: [
          // Email header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF4299E1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3182CE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.send, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        'Send',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _isComposing = false),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // From field
                  Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A5568),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 50,
                          child: Text(
                            'From:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _fromEmailController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'your.email@example.com',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                  
                  // To field
                  Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A5568),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            'To',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          'civiclink.official@gmail.com',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Spacer(),
                        Text(
                          'Cc',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Bcc',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  // Subject field
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A5568),
                    ),
                    child: TextFormField(
                      controller: _subjectController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Add a subject',
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  
                  // Message body
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A5568),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      child: TextFormField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 14),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Compose your message here...\n\nPlease describe your issue or question in detail.',
                          hintStyle: TextStyle(color: Colors.white54, height: 1.4, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  
                  // Send button
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendEmail,
                      icon: _isSending 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, size: 16),
                      label: Text(_isSending ? 'Sending...' : 'Send Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4299E1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorfulStepCard(
    int step,
    String title,
    String description,
    IconData icon,
    LinearGradient gradient,
    List<String> points,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      step.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(icon, color: Colors.white, size: 24),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: points.map((point) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    IconData icon,
    LinearGradient gradient,
    List<String> features,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: features.map((feature) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events, color: Colors.white, size: 32),
          SizedBox(height: 12),
          Text(
            'Success Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Follow these tips to get the best results from your reports!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleQuestionItem(String question, String answer) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Get Direct Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Our support team is ready to help',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildContactRow(Icons.email, 'civiclink.official@gmail.com'),
          _buildContactRow(Icons.access_time, 'Response: 24-48 hours'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.help_outline, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Common Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuestionItem(
            'How do I report an urgent issue?',
            'Select "Critical" or "High" priority when creating your report.',
          ),
          _buildQuestionItem(
            'Why can\'t I see my issue on the map?',
            'New issues may take a few minutes to appear.',
          ),
          _buildQuestionItem(
            'How do I get faster responses?',
            'Include clear photos and detailed descriptions.',
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.3,
            ),
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}