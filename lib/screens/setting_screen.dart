// screens/settings_screen.dart (UPDATED VERSION)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../models/user_model.dart';
import '../theme/modern_theme.dart';
import 'citizen_help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  UserModel? _userData;
  bool _isLoading = true;
  bool _isUpdating = false;

  // Settings state
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _locationEnabled = false;
  String _selectedLanguage = 'English';
  bool _isDarkMode = false;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
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

  void _helpSupport() {
    // Check if user is a citizen to show comprehensive help
    if (_userData?.userType == 'citizen') {
      // Navigate to the comprehensive Citizen Help & Support screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CitizenHelpSupportScreen(),
        ),
      );
    } else {
      // For officials, show simple contact dialog
      _showDialog(
        'Help & Support',
        'Need help? Contact our support team!\n\n'
            '📧 Email: civiclink.official@gmail.com\n'
            '📞 Phone: +1 (555) 123-4567\n'
            '🌐 Website: www.civiclink.com\n\n'
            'Business Hours:\n'
            'Monday - Friday: 9:00 AM - 6:00 PM\n'
            'Saturday: 10:00 AM - 4:00 PM\n'
            'Sunday: Closed\n\n'
            'For technical issues, please include your account type (Official) and department information.',
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load user data
      final userData = await _authService.getUserData();

      // Load settings from SettingsService
      await _settingsService.initializeSettings();

      // Load additional settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _userData = userData;
        _notificationsEnabled = _settingsService.notificationsEnabled;
        _selectedLanguage = _settingsService.selectedLanguage;
        _isDarkMode = _settingsService.isDarkMode;
        _soundEnabled = _settingsService.soundEnabled;

        // Load from SharedPreferences for settings not in SettingsService
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _locationEnabled = prefs.getBool('location_enabled') ?? false;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load settings: $e');
    }
  }

  Future<void> _updateUserProfile(String newName) async {
    setState(() => _isUpdating = true);

    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userData!.uid)
          .update({'fullName': newName});

      // Update local userData
      setState(() {
        _userData = UserModel(
          uid: _userData!.uid,
          email: _userData!.email,
          fullName: newName,
          userType: _userData!.userType,
          profilePicture: _userData!.profilePicture,
          createdAt: _userData!.createdAt,
        );
      });

      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateNotificationSettings() async {
    setState(() => _isUpdating = true);

    try {
      // Update using SettingsService
      await _settingsService.setNotifications(_notificationsEnabled);

      // Save additional notification settings to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('push_notifications', _pushNotifications);

      _showSuccessSnackBar('Notification settings updated!');
    } catch (e) {
      _showErrorSnackBar('Failed to update settings: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateAppPreferences() async {
    setState(() => _isUpdating = true);

    try {
      // Update using SettingsService methods
      await _settingsService.setLanguage(_selectedLanguage);
      await _settingsService.setDarkMode(_isDarkMode);

      _showSuccessSnackBar('App preferences updated!');

      // Force app restart for immediate theme/language change
      if (mounted) {
        // Small delay to show the success message before restart
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update preferences: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updatePrivacySettings() async {
    setState(() => _isUpdating = true);

    try {
      // Save privacy settings to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_enabled', _locationEnabled);

      _showSuccessSnackBar('Privacy settings updated!');
    } catch (e) {
      _showErrorSnackBar('Failed to update privacy settings: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  // NEW: Send email functionality
  Future<void> _sendEmailToSupport() async {
    final String email = 'civiclink.official@gmail.com';
    final String subject =
        'CivicLink Support - ${_userData?.userType ?? 'User'}';
    final String body =
        'Hello CivicLink Support Team,\n\nI need assistance with:\n\n[Please describe your issue here]\n\nUser Details:\nName: ${_userData?.fullName ?? 'Unknown'}\nEmail: ${_userData?.email ?? 'Unknown'}\nAccount Type: ${_userData?.userType ?? 'Unknown'}\n\nThank you for your support.';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // If can't launch email app, show dialog with email details
        _showEmailFallbackDialog(email, subject, body);
      }
    } catch (e) {
      _showEmailFallbackDialog(email, subject, body);
    }
  }

  void _showEmailFallbackDialog(String email, String subject, String body) {
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please copy the details below and send an email manually:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildCopyableField('Email:', email),
                  const SizedBox(height: 12),
                  _buildCopyableField('Subject:', subject),
                  const SizedBox(height: 12),
                  const Text(
                    'Message:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(body, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Copy email to clipboard
                  _copyToClipboard(email);
                  Navigator.pop(context);
                  _showSuccessSnackBar('Email address copied to clipboard!');
                },
                child: const Text('Copy Email'),
              ),
            ],
          ),
    );
  }

  Widget _buildCopyableField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(String text) async {
    // Implementation would depend on the clipboard package
    // For now, we'll just show that it's copied
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
                  'Loading Settings...',
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
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildProfileSection(),
                          const SizedBox(height: 32),
                          _buildAccountSettings(),
                          const SizedBox(height: 24),
                          _buildNotificationSettings(),
                          const SizedBox(height: 24),
                          _buildAppPreferences(),
                          const SizedBox(height: 24),
                          _buildPrivacySettings(),
                          const SizedBox(height: 24),
                          _buildAboutSection(),
                          const SizedBox(height: 24),
                          _buildAccountManagement(),
                          const SizedBox(height: 40),
                        ],
                      ),
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
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage your account and preferences',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isUpdating)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: ModernTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ModernTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _userData?.fullName.isNotEmpty == true
                        ? _userData!.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?.fullName ?? 'User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData?.email ?? 'user@example.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ModernStatusChip(
                      text: _userData?.isAdmin == true ? 'ADMIN' : 'CITIZEN',
                      color:
                          _userData?.isAdmin == true
                              ? ModernTheme.error
                              : ModernTheme.accent,
                      icon:
                          _userData?.isAdmin == true
                              ? Icons.admin_panel_settings
                              : Icons.person,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: ModernTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: ModernTheme.primaryBlue),
                  onPressed: _editProfile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return _buildSection('Account Settings', [
      _buildSettingsTile(
        icon: Icons.person_outline,
        title: 'Edit Profile',
        subtitle: 'Update your personal information',
        onTap: _editProfile,
      ),
      _buildSettingsTile(
        icon: Icons.lock_outline,
        title: 'Change Password',
        subtitle: 'Update your account password',
        onTap: _changePassword,
      ),
      // REMOVED: Email Preferences
    ]);
  }

  Widget _buildNotificationSettings() {
    return _buildSection('Notifications', [
      _buildSwitchTile(
        icon: Icons.notifications_outlined,
        title: 'Enable Notifications',
        subtitle: 'Receive app notifications',
        value: _notificationsEnabled,
        onChanged: (value) async {
          setState(() => _notificationsEnabled = value);
          await _updateNotificationSettings();
        },
      ),
      _buildSwitchTile(
        icon: Icons.email_outlined,
        title: 'Email Notifications',
        subtitle: 'Receive notifications via email',
        value: _emailNotifications,
        onChanged: (value) async {
          setState(() => _emailNotifications = value);
          await _updateNotificationSettings();
        },
      ),
      _buildSwitchTile(
        icon: Icons.phone_android,
        title: 'Push Notifications',
        subtitle: 'Receive push notifications',
        value: _pushNotifications,
        onChanged: (value) async {
          setState(() => _pushNotifications = value);
          await _updateNotificationSettings();
        },
      ),
    ]);
  }

  Widget _buildAppPreferences() {
    return _buildSection('App Preferences', [
      _buildDropdownTile(
        icon: Icons.language,
        title: 'Language',
        subtitle: 'Choose your preferred language',
        value: _selectedLanguage,
        items: const ['English', 'Sinhala'],
        onChanged: (value) async {
          setState(() => _selectedLanguage = value!);
          await _updateAppPreferences();
        },
      ),
      _buildSwitchTile(
        icon: Icons.dark_mode_outlined,
        title: 'Dark Mode',
        subtitle: 'Switch between light and dark theme',
        value: _isDarkMode,
        onChanged: (value) async {
          setState(() => _isDarkMode = value);
          await _updateAppPreferences();
        },
      ),
      _buildSwitchTile(
        icon: Icons.volume_up,
        title: 'Sound Effects',
        subtitle: 'Play sounds for notifications',
        value: _soundEnabled,
        onChanged: (value) async {
          setState(() => _soundEnabled = value);
          await _settingsService.setSoundEnabled(value);
        },
      ),
    ]);
  }

  Widget _buildPrivacySettings() {
    return _buildSection('Privacy & Security', [
      _buildSwitchTile(
        icon: Icons.location_on_outlined,
        title: 'Location Services',
        subtitle: 'Allow app to access your location',
        value: _locationEnabled,
        onChanged: (value) async {
          setState(() => _locationEnabled = value);
          await _updatePrivacySettings();
        },
      ),
      // REMOVED: Biometric Authentication
      _buildSettingsTile(
        icon: Icons.security,
        title: 'Privacy Policy',
        subtitle: 'Read our privacy policy',
        onTap: _showPrivacyPolicy,
      ),
      // REMOVED: Export Data
    ]);
  }

  Widget _buildAboutSection() {
    return _buildSection('About & Support', [
      _buildSettingsTile(
        icon: Icons.help_outline,
        title: 'Help & Support',
        subtitle: 'Get help or contact support',
        onTap: _helpSupport,
      ),
      // NEW: Contact Support via Email
      _buildSettingsTile(
        icon: Icons.email_outlined,
        title: 'Contact Support',
        subtitle: 'Send email to civiclink.official@gmail.com',
        onTap: _sendEmailToSupport,
      ),
      _buildSettingsTile(
        icon: Icons.info_outline,
        title: 'About CivicLink',
        subtitle: 'App version and information',
        onTap: _aboutApp,
      ),
      // REMOVED: Rate App and Share App
    ]);
  }

  Widget _buildAccountManagement() {
    return _buildSection('Account Management', [
      _buildSettingsTile(
        icon: Icons.logout,
        title: 'Sign Out',
        subtitle: 'Sign out from your account',
        onTap: _signOut,
        textColor: ModernTheme.primaryBlue,
      ),
      _buildSettingsTile(
        icon: Icons.delete_outline,
        title: 'Delete Account',
        subtitle: 'Permanently remove your account',
        onTap: _deleteAccount,
        textColor: ModernTheme.error,
      ),
    ]);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return ModernCard(
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
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? ModernTheme.primaryBlue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? ModernTheme.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color:
            textColor ??
            Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ModernTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ModernTheme.primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: ModernTheme.primaryBlue,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ModernTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ModernTheme.primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: ModernTheme.primaryBlue.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          underline: const SizedBox(),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          dropdownColor: Theme.of(context).cardColor,
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  // Action Methods
  void _editProfile() {
    _showEditProfileDialog();
  }

  void _changePassword() {
    _showChangePasswordDialog();
  }

  void _showPrivacyPolicy() {
    _showDialog(
      'Privacy Policy',
      'This is where the privacy policy content would be displayed. '
          'In a real app, this would show the full privacy policy text or '
          'open a web view with the privacy policy URL.\n\n'
          'Your privacy is important to us. We collect only the necessary '
          'information to provide our services and never share your personal '
          'data with third parties without your consent.',
    );
  }

  void _aboutApp() {
    _showDialog(
      'About CivicLink',
      'CivicLink v1.0.0\n\n'
          '🏛️ Report. Track. Resolve.\n\n'
          'CivicLink helps citizens report community issues and track their resolution. '
          'Built with Flutter and Firebase for a seamless experience.\n\n'
          '✨ Features:\n'
          '• Report community issues\n'
          '• Track issue status\n'
          '• Location-based mapping\n'
          '• Real-time notifications\n'
          '• Admin dashboard\n\n'
          '📧 Support: civiclink.official@gmail.com\n'
          '🌐 Website: www.civiclink.com\n\n'
          '© 2025 CivicLink Team\n'
          'Made with ❤️ for better communities',
    );
  }

  void _signOut() async {
    _showDialog(
      'Sign Out',
      '👋 Are you sure you want to sign out?\n\n'
          'You can always sign back in anytime to continue reporting '
          'and tracking community issues.',
      showActions: true,
      confirmText: 'Sign Out',
      onConfirm: () async {
        try {
          setState(() => _isUpdating = true);
          await _authService.signOut();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        } catch (e) {
          setState(() => _isUpdating = false);
          _showErrorSnackBar('Failed to sign out: $e');
        }
      },
    );
  }

  void _deleteAccount() {
    _showDialog(
      'Delete Account',
      '⚠️ This action cannot be undone!\n\n'
          'Deleting your account will permanently remove:\n'
          '• Your profile information\n'
          '• All reported issues\n'
          '• App settings and preferences\n'
          '• Activity history\n\n'
          'Are you absolutely sure you want to delete your account?',
      showActions: true,
      confirmText: 'Delete Account',
      isDestructive: true,
      onConfirm: () {
        _showDialog(
          'Account Deletion',
          'Account deletion is a permanent action. To proceed, please contact our support team at civiclink.official@gmail.com with your deletion request.\n\n'
              'We\'ll process your request within 48 hours and send you a confirmation email.',
        );
      },
    );
  }

  // Dialog Methods
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userData?.fullName);
    final emailController = TextEditingController(text: _userData?.email);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    helperText: 'Email cannot be changed',
                  ),
                  enabled: false,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty && newName != _userData?.fullName) {
                    Navigator.pop(context);
                    await _updateUserProfile(newName);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessSnackBar('Password changed successfully!');
                },
                child: const Text('Change Password'),
              ),
            ],
          ),
    );
  }

  void _showDialog(
    String title,
    String content, {
    bool showActions = false,
    String confirmText = 'OK',
    bool isDestructive = false,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            content: Text(
              content,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            actions: [
              if (showActions) ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm?.call();
                  },
                  style:
                      isDestructive
                          ? ElevatedButton.styleFrom(
                            backgroundColor: ModernTheme.error,
                            foregroundColor: Colors.white,
                          )
                          : null,
                  child: Text(confirmText),
                ),
              ] else ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
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
}
