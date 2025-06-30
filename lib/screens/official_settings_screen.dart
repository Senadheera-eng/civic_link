// screens/official_settings_screen.dart (FIXED VERSION)
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../theme/modern_theme.dart';

class OfficialSettingsScreen extends StatefulWidget {
  @override
  _OfficialSettingsScreenState createState() => _OfficialSettingsScreenState();
}

class _OfficialSettingsScreenState extends State<OfficialSettingsScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  final NotificationService _notificationService = NotificationService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  UserModel? _userData;
  bool _isLoading = true;

  // General Settings
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  // Official-specific Settings
  bool _autoAssignIssues = false;
  bool _urgentNotifications = true;
  bool _statusUpdateNotifications = true;
  bool _weeklyReportsEnabled = true;
  bool _showResolutionTime = true;
  bool _enableQuickActions = true;
  String _workingHours = '9:00 AM - 5:00 PM';
  int _maxDailyAssignments = 10;

  final List<String> _languages = ['English', 'Sinhala'];
  final List<String> _workingHourOptions = [
    '24/7 (Always Available)',
    '9:00 AM - 5:00 PM',
    '8:00 AM - 6:00 PM',
    '10:00 AM - 4:00 PM',
    'Custom Hours',
  ];

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
      final userData = await _authService.getUserData();
      await _settingsService.initializeSettings();

      setState(() {
        _userData = userData;
        _isDarkMode = _settingsService.isDarkMode;
        _selectedLanguage = _settingsService.selectedLanguage;
        _notificationsEnabled = _settingsService.notificationsEnabled;
        _soundEnabled = _settingsService.soundEnabled;
        _isLoading = false;
      });

      // Load official-specific settings
      await _loadOfficialSettings();
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOfficialSettings() async {
    setState(() {
      _autoAssignIssues = _settingsService.getOfficialSetting(
        'auto_assign_issues',
        false,
      );
      _urgentNotifications = _settingsService.getOfficialSetting(
        'urgent_notifications',
        true,
      );
      _statusUpdateNotifications = _settingsService.getOfficialSetting(
        'status_update_notifications',
        true,
      );
      _weeklyReportsEnabled = _settingsService.getOfficialSetting(
        'weekly_reports',
        true,
      );
      _showResolutionTime = _settingsService.getOfficialSetting(
        'show_resolution_time',
        true,
      );
      _enableQuickActions = _settingsService.getOfficialSetting(
        'enable_quick_actions',
        true,
      );
      _workingHours = _settingsService.getOfficialSetting(
        'working_hours',
        '9:00 AM - 5:00 PM',
      );
      _maxDailyAssignments = _settingsService.getOfficialSetting(
        'max_daily_assignments',
        10,
      );
    });
  }

  Future<void> _saveOfficialSetting(String key, dynamic value) async {
    await _settingsService.saveOfficialSetting(key, value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await _settingsService.setDarkMode(value);
  }

  Future<void> _changeLanguage(String? language) async {
    if (language != null) {
      setState(() => _selectedLanguage = language);
      await _settingsService.setLanguage(language);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _settingsService.setNotifications(value);

    if (value) {
      try {
        await _notificationService.initialize();
      } catch (e) {
        print('Notification initialization failed: $e');
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _showConfirmDialog(
      'Sign Out',
      'Are you sure you want to sign out?',
    );

    if (confirmed == true) {
      try {
        await _authService.signOut();
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        _showErrorSnackBar('Failed to sign out: $e');
      }
    }
  }

  Future<void> _exportData() async {
    _showInfoSnackBar('Data export feature coming soon...');
  }

  Future<void> _clearCache() async {
    _showInfoSnackBar('Cache cleared successfully');
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: ModernTheme.primaryBlue,
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
            child: CircularProgressIndicator(color: Colors.white),
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
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildProfileSection(),
                        const SizedBox(height: 32),
                        _buildGeneralSettings(),
                        const SizedBox(height: 32),
                        _buildOfficialSettings(),
                        const SizedBox(height: 32),
                        _buildNotificationSettings(),
                        const SizedBox(height: 32),
                        _buildDataSettings(),
                        const SizedBox(height: 32),
                        _buildSignOutSection(),
                        const SizedBox(height: 24),
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
                  'Official Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage your preferences',
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return ModernCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: ModernTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?.fullName ?? 'Official',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ModernTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _userData?.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: ModernTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ModernTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_userData?.department ?? 'Unknown'} Department',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ModernTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildGeneralSettings() {
    return _buildSettingsSection(
      title: 'General Settings',
      icon: Icons.settings,
      children: [
        _buildSwitchTile(
          title: 'Dark Mode',
          subtitle: 'Use dark theme across the app',
          value: _isDarkMode,
          onChanged: _toggleDarkMode,
          icon: Icons.dark_mode,
        ),
        _buildDropdownTile(
          title: 'Language',
          subtitle: 'Change app language',
          value: _selectedLanguage,
          items: _languages,
          onChanged: _changeLanguage,
          icon: Icons.language,
        ),
        _buildSwitchTile(
          title: 'Notifications',
          subtitle: 'Receive push notifications',
          value: _notificationsEnabled,
          onChanged: _toggleNotifications,
          icon: Icons.notifications,
        ),
        _buildSwitchTile(
          title: 'Sound Effects',
          subtitle: 'Play sounds for notifications',
          value: _soundEnabled,
          onChanged: (value) {
            setState(() => _soundEnabled = value);
            _settingsService.setSoundEnabled(value);
          },
          icon: Icons.volume_up,
        ),
      ],
    );
  }

  Widget _buildOfficialSettings() {
    return _buildSettingsSection(
      title: 'Official Preferences',
      icon: Icons.admin_panel_settings,
      children: [
        _buildSwitchTile(
          title: 'Auto-Assign Issues',
          subtitle: 'Automatically assign new issues to you',
          value: _autoAssignIssues,
          onChanged: (value) {
            setState(() => _autoAssignIssues = value);
            _saveOfficialSetting('auto_assign_issues', value);
          },
          icon: Icons.assignment_ind,
        ),
        _buildSwitchTile(
          title: 'Show Resolution Time',
          subtitle: 'Display resolution time metrics',
          value: _showResolutionTime,
          onChanged: (value) {
            setState(() => _showResolutionTime = value);
            _saveOfficialSetting('show_resolution_time', value);
          },
          icon: Icons.timer,
        ),
        _buildSwitchTile(
          title: 'Quick Actions',
          subtitle: 'Enable quick action buttons',
          value: _enableQuickActions,
          onChanged: (value) {
            setState(() => _enableQuickActions = value);
            _saveOfficialSetting('enable_quick_actions', value);
          },
          icon: Icons.flash_on,
        ),
        _buildDropdownTile(
          title: 'Working Hours',
          subtitle: 'Set your availability',
          value: _workingHours,
          items: _workingHourOptions,
          onChanged: (value) {
            if (value != null) {
              setState(() => _workingHours = value);
              _saveOfficialSetting('working_hours', value);
            }
          },
          icon: Icons.schedule,
        ),
        _buildSliderTile(
          title: 'Max Daily Assignments',
          subtitle: 'Maximum issues assigned per day',
          value: _maxDailyAssignments.toDouble(),
          min: 1,
          max: 50,
          divisions: 49,
          onChanged: (value) {
            setState(() => _maxDailyAssignments = value.round());
            _saveOfficialSetting('max_daily_assignments', value.round());
          },
          icon: Icons.assignment,
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSettingsSection(
      title: 'Notification Preferences',
      icon: Icons.notifications_active,
      children: [
        _buildSwitchTile(
          title: 'Urgent Issue Alerts',
          subtitle: 'Get notified for urgent issues',
          value: _urgentNotifications,
          onChanged: (value) {
            setState(() => _urgentNotifications = value);
            _saveOfficialSetting('urgent_notifications', value);
          },
          icon: Icons.priority_high,
        ),
        _buildSwitchTile(
          title: 'Status Updates',
          subtitle: 'Notifications for issue status changes',
          value: _statusUpdateNotifications,
          onChanged: (value) {
            setState(() => _statusUpdateNotifications = value);
            _saveOfficialSetting('status_update_notifications', value);
          },
          icon: Icons.update,
        ),
        _buildSwitchTile(
          title: 'Weekly Reports',
          subtitle: 'Receive weekly performance reports',
          value: _weeklyReportsEnabled,
          onChanged: (value) {
            setState(() => _weeklyReportsEnabled = value);
            _saveOfficialSetting('weekly_reports', value);
          },
          icon: Icons.bar_chart,
        ),
      ],
    );
  }

  Widget _buildDataSettings() {
    return _buildSettingsSection(
      title: 'Data & Privacy',
      icon: Icons.privacy_tip,
      children: [
        _buildActionTile(
          title: 'Export Data',
          subtitle: 'Download your data and reports',
          onTap: _exportData,
          icon: Icons.download,
        ),
        _buildActionTile(
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          onTap: _clearCache,
          icon: Icons.clear_all,
        ),
      ],
    );
  }

  Widget _buildSignOutSection() {
    return ModernCard(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ModernTheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: ModernTheme.error),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ModernTheme.error,
          ),
        ),
        subtitle: const Text('Sign out of your account'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _signOut,
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ModernTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ModernCard(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: ModernTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: ModernTheme.primaryBlue,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ModernTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ModernTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),

          // Title and Subtitle
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Dropdown
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ModernTheme.primaryBlue.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: value,
                onChanged: onChanged,
                underline: const SizedBox(),
                isExpanded: true, // This ensures proper width
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
                dropdownColor: Theme.of(context).cardColor,
                items:
                    items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required IconData icon,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: ModernTheme.primaryBlue),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('$subtitle: ${value.round()}'),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: ModernTheme.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: ModernTheme.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

// Supporting ModernCard widget (use your existing one, but here's a fallback)
class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const ModernCard({
    Key? key,
    required this.child,
    this.onTap,
    this.color,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
