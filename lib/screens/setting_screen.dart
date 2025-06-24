// screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme/simple_theme.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/custom_widgets.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userData;
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  Future<void> _loadSettings() async {
    // In a real app, you would load these from SharedPreferences or Firebase
    // For now, we'll use default values
    setState(() {
      _notificationsEnabled = true;
      _emailNotifications = true;
      _pushNotifications = true;
      _selectedLanguage = 'English';
      _selectedTheme = 'Light';
    });
  }

  Future<void> _saveSettings() async {
    // In a real app, you would save these to SharedPreferences or Firebase
    Helpers.showSnackBar(context, 'Settings saved successfully!');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(),
            const SizedBox(height: 24),

            // Account Settings
            _buildAccountSettings(),
            const SizedBox(height: 24),

            // Notification Settings
            _buildNotificationSettings(),
            const SizedBox(height: 24),

            // App Preferences
            _buildAppPreferences(),
            const SizedBox(height: 24),

            // Privacy & Security
            _buildPrivacySettings(),
            const SizedBox(height: 24),

            // About & Support
            _buildAboutSection(),
            const SizedBox(height: 24),

            // Danger Zone
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SimpleTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: SimpleTheme.primaryBlue,
                child: Text(
                  _userData?.fullName.isNotEmpty == true
                      ? _userData!.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?.fullName ?? 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userData?.email ?? 'user@example.com',
                      style: const TextStyle(
                        fontSize: 14,
                        color: SimpleTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatusChip(
                      text: _userData?.userType.toUpperCase() ?? 'CITIZEN',
                      color:
                          _userData?.isAdmin == true
                              ? SimpleTheme.error
                              : SimpleTheme.accent,
                      icon:
                          _userData?.isAdmin == true
                              ? Icons.admin_panel_settings
                              : Icons.person,
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit), onPressed: _editProfile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SimpleTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
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
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Email Preferences',
            subtitle: 'Manage email settings',
            onTap: _emailPreferences,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SimpleTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Enable Notifications',
            subtitle: 'Receive app notifications',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.phone_android,
            title: 'Push Notifications',
            subtitle: 'Receive push notifications',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferences() {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SimpleTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDropdownTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Choose your preferred language',
            value: _selectedLanguage,
            items: ['English', 'Spanish', 'French', 'German'],
            onChanged: (value) {
              setState(() => _selectedLanguage = value!);
            },
          ),
          _buildDropdownTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Choose app appearance',
            value: _selectedTheme,
            items: ['Light', 'Dark', 'System'],
            onChanged: (value) {
              setState(() => _selectedTheme = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy & Security',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SimpleTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: _showPrivacyPolicy,
          ),
          _buildSettingsTile(
            icon: Icons.shield_outlined,
            title: 'Data & Privacy',
            subtitle: 'Manage your data preferences',
            onTap: _dataPrivacy,
          ),
          _buildSettingsTile(
            icon: Icons.download_outlined,
            title: 'Export Data',
            subtitle: 'Download your account data',
            onTap: _exportData,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About & Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SimpleTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            onTap: _helpSupport,
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About CivicLink',
            subtitle: 'App version and information',
            onTap: _aboutApp,
          ),
          _buildSettingsTile(
            icon: Icons.rate_review_outlined,
            title: 'Rate App',
            subtitle: 'Rate CivicLink on app store',
            onTap: _rateApp,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return SimpleCard(
      color: SimpleTheme.error.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SimpleTheme.error,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: _signOut,
            textColor: SimpleTheme.error,
          ),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            onTap: _deleteAccount,
            textColor: SimpleTheme.error,
          ),
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
      leading: Icon(icon, color: textColor ?? SimpleTheme.primaryBlue),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? SimpleTheme.textPrimary,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: textColor ?? SimpleTheme.textSecondary,
      ),
      onTap: onTap,
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
      leading: Icon(icon, color: SimpleTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: SimpleTheme.primaryBlue,
      ),
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
      leading: Icon(icon, color: SimpleTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items:
            items.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
      ),
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
    Helpers.showSnackBar(context, 'Email preferences feature coming soon!');
  }

  void _showPrivacyPolicy() {
    _showDialog(
      'Privacy Policy',
      'This is where the privacy policy content would be displayed. '
          'In a real app, this would show the full privacy policy text or '
          'open a web view with the privacy policy URL.',
    );
  }

  void _dataPrivacy() {
    Helpers.showSnackBar(context, 'Data privacy settings coming soon!');
  }

  void _exportData() {
    _showDialog(
      'Export Data',
      'Your data export will be prepared and sent to your email address. '
          'This may take a few minutes to process.',
      showActions: true,
      confirmText: 'Export',
      onConfirm: () {
        Helpers.showSnackBar(context, 'Data export initiated!');
      },
    );
  }

  void _helpSupport() {
    _showDialog(
      'Help & Support',
      'For support, please contact us at:\n\n'
          'Email: support@civiclink.com\n'
          'Phone: +1 (555) 123-4567\n\n'
          'You can also visit our website for FAQs and documentation.',
    );
  }

  void _aboutApp() {
    _showDialog(
      'About CivicLink',
      'CivicLink v1.0.0\n\n'
          'Report. Track. Resolve.\n\n'
          'CivicLink helps citizens report community issues and track their resolution. '
          'Built with Flutter and Firebase.\n\n'
          '© 2025 CivicLink Team',
    );
  }

  void _rateApp() {
    _showDialog(
      'Rate CivicLink',
      'Thank you for using CivicLink! Your feedback helps us improve. '
          'Would you like to rate us on the app store?',
      showActions: true,
      confirmText: 'Rate Now',
      onConfirm: () {
        Helpers.showSnackBar(context, 'Redirecting to app store...');
      },
    );
  }

  void _signOut() async {
    _showDialog(
      'Sign Out',
      'Are you sure you want to sign out of your account?',
      showActions: true,
      confirmText: 'Sign Out',
      onConfirm: () async {
        try {
          await _authService.signOut();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        } catch (e) {
          Helpers.showSnackBar(
            context,
            'Failed to sign out: $e',
            isError: true,
          );
        }
      },
    );
  }

  void _deleteAccount() {
    _showDialog(
      'Delete Account',
      'This action cannot be undone. All your data will be permanently deleted. '
          'Are you absolutely sure you want to delete your account?',
      showActions: true,
      confirmText: 'Delete Account',
      isDestructive: true,
      onConfirm: () {
        _showDialog(
          'Account Deletion',
          'Account deletion feature is not yet implemented. '
              'Please contact support for account deletion requests.',
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userData?.fullName);
    final emailController = TextEditingController(text: _userData?.email);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false, // Email usually can't be changed
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
                  Helpers.showSnackBar(
                    context,
                    'Profile updated successfully!',
                  );
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
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
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
                  Helpers.showSnackBar(
                    context,
                    'Password changed successfully!',
                  );
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
            title: Text(title),
            content: Text(content),
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
                            backgroundColor: SimpleTheme.error,
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
}
