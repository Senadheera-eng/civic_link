// screens/settings_screen.dart (FIXED VERSION)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../models/user_model.dart';
import '../theme/modern_theme.dart';
import '../l10n/app_localizations.dart';

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
  bool _biometricEnabled = false;
  String _selectedLanguage = 'English';
  bool _isDarkMode = false;

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

      setState(() {
        _userData = userData;
        _notificationsEnabled = _settingsService.notificationsEnabled;
        _emailNotifications = _settingsService.emailNotifications;
        _pushNotifications = _settingsService.pushNotifications;
        _locationEnabled = _settingsService.locationEnabled;
        _biometricEnabled = _settingsService.biometricEnabled;
        _selectedLanguage = _settingsService.selectedLanguage;
        _isDarkMode = _settingsService.isDarkMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(
        AppLocalizations.of(context)?.failedToLoadSettings ??
            'Failed to load settings: $e',
      );
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

      _showSuccessSnackBar(
        AppLocalizations.of(context)?.profileUpdatedSuccessfully ??
            'Profile updated successfully!',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateNotificationSettings() async {
    setState(() => _isUpdating = true);

    try {
      await _settingsService.updateNotificationSettings(
        notificationsEnabled: _notificationsEnabled,
        emailNotifications: _emailNotifications,
        pushNotifications: _pushNotifications,
      );
      _showSuccessSnackBar(
        AppLocalizations.of(context)?.notificationSettingsUpdated ??
            'Notification settings updated!',
      );
    } catch (e) {
      _showErrorSnackBar(
        AppLocalizations.of(context)?.failedToUpdateSettings ??
            'Failed to update settings: $e',
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateAppPreferences() async {
    setState(() => _isUpdating = true);

    try {
      await _settingsService.updateAppPreferences(
        language: _selectedLanguage,
        darkMode: _isDarkMode,
      );
      _showSuccessSnackBar(
        AppLocalizations.of(context)?.appPreferencesUpdated ??
            'App preferences updated!',
      );

      // Force app restart for immediate theme/language change
      if (mounted) {
        // Small delay to show the success message before restart
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      _showErrorSnackBar(
        AppLocalizations.of(context)?.failedToUpdateSettings ??
            'Failed to update preferences: $e',
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updatePrivacySettings() async {
    setState(() => _isUpdating = true);

    try {
      await _settingsService.updatePrivacySettings(
        locationEnabled: _locationEnabled,
        biometricEnabled: _biometricEnabled,
      );
      _showSuccessSnackBar(
        AppLocalizations.of(context)?.privacySettingsUpdated ??
            'Privacy settings updated!',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update privacy settings: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: ModernTheme.primaryGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  l10n?.loadingSettings ?? 'Loading Settings...',
                  style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.settings ?? 'Settings',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  l10n?.manageAccount ?? 'Manage your account and preferences',
                  style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.profileInformation ?? 'Profile Information',
            style: const TextStyle(
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
                      text:
                          _userData?.isAdmin == true
                              ? (l10n?.admin ?? 'ADMIN')
                              : (l10n?.citizen ?? 'CITIZEN'),
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
    final l10n = AppLocalizations.of(context);

    return _buildSection(l10n?.accountSettings ?? 'Account Settings', [
      _buildSettingsTile(
        icon: Icons.person_outline,
        title: l10n?.editProfile ?? 'Edit Profile',
        subtitle:
            l10n?.updatePersonalInfo ?? 'Update your personal information',
        onTap: _editProfile,
      ),
      _buildSettingsTile(
        icon: Icons.lock_outline,
        title: l10n?.changePassword ?? 'Change Password',
        subtitle: l10n?.updateAccountPassword ?? 'Update your account password',
        onTap: _changePassword,
      ),
      _buildSettingsTile(
        icon: Icons.email_outlined,
        title: l10n?.emailPreferences ?? 'Email Preferences',
        subtitle: l10n?.manageEmailSettings ?? 'Manage email settings',
        onTap: _emailPreferences,
      ),
    ]);
  }

  Widget _buildNotificationSettings() {
    final l10n = AppLocalizations.of(context);

    return _buildSection(l10n?.notifications ?? 'Notifications', [
      _buildSwitchTile(
        icon: Icons.notifications_outlined,
        title: l10n?.enableNotifications ?? 'Enable Notifications',
        subtitle: l10n?.receiveAppNotifications ?? 'Receive app notifications',
        value: _notificationsEnabled,
        onChanged: (value) async {
          setState(() => _notificationsEnabled = value);
          await _updateNotificationSettings();
        },
      ),
      _buildSwitchTile(
        icon: Icons.email_outlined,
        title: l10n?.emailNotifications ?? 'Email Notifications',
        subtitle:
            l10n?.receiveNotificationsViaEmail ??
            'Receive notifications via email',
        value: _emailNotifications,
        onChanged: (value) async {
          setState(() => _emailNotifications = value);
          await _updateNotificationSettings();
        },
      ),
      _buildSwitchTile(
        icon: Icons.phone_android,
        title: l10n?.pushNotifications ?? 'Push Notifications',
        subtitle:
            l10n?.receivePushNotifications ?? 'Receive push notifications',
        value: _pushNotifications,
        onChanged: (value) async {
          setState(() => _pushNotifications = value);
          await _updateNotificationSettings();
        },
      ),
    ]);
  }

  Widget _buildAppPreferences() {
    final l10n = AppLocalizations.of(context);

    return _buildSection(l10n?.appPreferences ?? 'App Preferences', [
      _buildDropdownTile(
        icon: Icons.language,
        title: l10n?.language ?? 'Language',
        subtitle:
            l10n?.choosePreferredLanguage ?? 'Choose your preferred language',
        value: _selectedLanguage,
        items: const ['English', 'Sinhala'],
        onChanged: (value) async {
          setState(() => _selectedLanguage = value!);
          await _updateAppPreferences();
        },
      ),
      _buildSwitchTile(
        icon: Icons.dark_mode_outlined,
        title: l10n?.darkMode ?? 'Dark Mode',
        subtitle: l10n?.switchTheme ?? 'Switch between light and dark theme',
        value: _isDarkMode,
        onChanged: (value) async {
          setState(() => _isDarkMode = value);
          await _updateAppPreferences();
        },
      ),
    ]);
  }

  Widget _buildPrivacySettings() {
    final l10n = AppLocalizations.of(context);

    return _buildSection(l10n?.privacySecurity ?? 'Privacy & Security', [
      _buildSwitchTile(
        icon: Icons.location_on_outlined,
        title: l10n?.locationServices ?? 'Location Services',
        subtitle:
            l10n?.allowLocationAccess ?? 'Allow app to access your location',
        value: _locationEnabled,
        onChanged: (value) async {
          setState(() => _locationEnabled = value);
          await _updatePrivacySettings();
        },
      ),
      _buildSwitchTile(
        icon: Icons.fingerprint,
        title: l10n?.biometricAuth ?? 'Biometric Authentication',
        subtitle: l10n?.useBiometric ?? 'Use fingerprint or face unlock',
        value: _biometricEnabled,
        onChanged: (value) async {
          setState(() => _biometricEnabled = value);
          await _updatePrivacySettings();
        },
      ),
      _buildSettingsTile(
        icon: Icons.security,
        title: l10n?.privacyPolicy ?? 'Privacy Policy',
        subtitle: l10n?.readPrivacyPolicy ?? 'Read our privacy policy',
        onTap: _showPrivacyPolicy,
      ),
      _buildSettingsTile(
        icon: Icons.download_outlined,
        title: l10n?.exportData ?? 'Export Data',
        subtitle: l10n?.downloadAccountData ?? 'Download your account data',
        onTap: _exportData,
      ),
    ]);
  }

  Widget _buildAboutSection() {
    final l10n = AppLocalizations.of(context);

    return _buildSection(l10n?.aboutSupport ?? 'About & Support', [
      _buildSettingsTile(
        icon: Icons.help_outline,
        title: l10n?.helpSupport ?? 'Help & Support',
        subtitle: l10n?.getHelpContact ?? 'Get help or contact support',
        onTap: _helpSupport,
      ),
      _buildSettingsTile(
        icon: Icons.info_outline,
        title: l10n?.aboutCivicLink ?? 'About CivicLink',
        subtitle: l10n?.appVersionInfo ?? 'App version and information',
        onTap: _aboutApp,
      ),
      _buildSettingsTile(
        icon: Icons.rate_review_outlined,
        title: l10n?.rateApp ?? 'Rate App',
        subtitle: l10n?.rateCivicLinkStore ?? 'Rate CivicLink on app store',
        onTap: _rateApp,
      ),
      _buildSettingsTile(
        icon: Icons.share_outlined,
        title: l10n?.shareApp ?? 'Share App',
        subtitle: l10n?.shareCivicLinkFriends ?? 'Share CivicLink with friends',
        onTap: _shareApp,
      ),
    ]);
  }

  Widget _buildAccountManagement() {
    final l10n = AppLocalizations.of(context);

    return _buildSection(l10n?.accountManagement ?? 'Account Management', [
      _buildSettingsTile(
        icon: Icons.logout,
        title: l10n?.signOut ?? 'Sign Out',
        subtitle: l10n?.signOutAccount ?? 'Sign out from your account',
        onTap: _signOut,
        textColor: ModernTheme.primaryBlue,
      ),
      _buildSettingsTile(
        icon: Icons.delete_outline,
        title: l10n?.deleteAccount ?? 'Delete Account',
        subtitle:
            l10n?.permanentlyRemoveAccount ?? 'Permanently remove your account',
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

  void _emailPreferences() {
    _showEmailPreferencesDialog();
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

  void _exportData() {
    _showDialog(
      'Export Data',
      'Your data export will be prepared and sent to your email address. '
          'This may take a few minutes to process.\n\n'
          'The export will include:\n'
          '• Profile information\n'
          '• Reported issues\n'
          '• App settings\n'
          '• Activity history',
      showActions: true,
      confirmText: 'Export',
      onConfirm: () async {
        try {
          final settings = _settingsService.exportSettings();
          _showSuccessSnackBar('Data export initiated! Check your email.');
        } catch (e) {
          _showErrorSnackBar('Failed to export data: $e');
        }
      },
    );
  }

  void _helpSupport() {
    _showDialog(
      'Help & Support',
      'Need help? We\'re here for you!\n\n'
          '📧 Email: support@civiclink.com\n'
          '📞 Phone: +1 (555) 123-4567\n'
          '🌐 Website: www.civiclink.com\n\n'
          'Business Hours:\n'
          'Monday - Friday: 9:00 AM - 6:00 PM\n'
          'Saturday: 10:00 AM - 4:00 PM\n'
          'Sunday: Closed\n\n'
          'You can also visit our website for FAQs and documentation.',
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
          '© 2025 CivicLink Team\n'
          'Made with ❤️ for better communities',
    );
  }

  void _rateApp() {
    _showDialog(
      'Rate CivicLink',
      '⭐ Enjoying CivicLink?\n\n'
          'Your feedback helps us improve and reach more communities! '
          'Would you like to rate us on the app store?\n\n'
          'It only takes a minute and really helps other users discover our app.',
      showActions: true,
      confirmText: 'Rate Now',
      onConfirm: () {
        _showSuccessSnackBar('Redirecting to app store...');
      },
    );
  }

  void _shareApp() {
    _showDialog(
      'Share CivicLink',
      '📢 Help spread the word!\n\n'
          'Share CivicLink with your friends and family to help build '
          'stronger communities together.\n\n'
          '\"Check out CivicLink - an amazing app for reporting and tracking '
          'community issues! Download it now and help make our neighborhood better.\"',
      showActions: true,
      confirmText: 'Share',
      onConfirm: () {
        _showSuccessSnackBar('Opening share dialog...');
      },
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
          'Account deletion is a permanent action. To proceed, please contact our support team at support@civiclink.com with your deletion request.\n\n'
              'We\'ll process your request within 48 hours and send you a confirmation email.',
        );
      },
    );
  }

  // Dialog Methods
  void _showEditProfileDialog() {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: _userData?.fullName);
    final emailController = TextEditingController(text: _userData?.email);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(l10n?.editProfile ?? 'Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n?.fullName ?? 'Full Name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: l10n?.email ?? 'Email',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                    helperText:
                        l10n?.emailCannotBeChanged ?? 'Email cannot be changed',
                  ),
                  enabled: false,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.cancel ?? 'Cancel'),
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
                child: Text(l10n?.save ?? 'Save'),
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

  void _showEmailPreferencesDialog() {
    bool issueUpdates = true;
    bool weeklyDigest = false;
    bool promotionalEmails = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Email Preferences'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: const Text('Issue Updates'),
                        subtitle: const Text(
                          'Get notified about your reported issues',
                        ),
                        value: issueUpdates,
                        onChanged:
                            (value) => setState(() => issueUpdates = value),
                      ),
                      SwitchListTile(
                        title: const Text('Weekly Digest'),
                        subtitle: const Text('Summary of community activities'),
                        value: weeklyDigest,
                        onChanged:
                            (value) => setState(() => weeklyDigest = value),
                      ),
                      SwitchListTile(
                        title: const Text('Promotional Emails'),
                        subtitle: const Text('News and feature updates'),
                        value: promotionalEmails,
                        onChanged:
                            (value) =>
                                setState(() => promotionalEmails = value),
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
                        _showSuccessSnackBar('Email preferences updated!');
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
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

// Supporting classes (add these if they don't exist)
class ModernCard extends StatelessWidget {
  final Widget child;

  const ModernCard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ModernStatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const ModernStatusChip({
    Key? key,
    required this.text,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
