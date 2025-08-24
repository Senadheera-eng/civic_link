// services/settings_service.dart (UPDATED VERSION)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

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

  // Getters for general settings
  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;

  // Getters for official settings
  bool get autoAssignIssues => _autoAssignIssues;
  bool get urgentNotifications => _urgentNotifications;
  bool get statusUpdateNotifications => _statusUpdateNotifications;
  bool get weeklyReportsEnabled => _weeklyReportsEnabled;
  bool get showResolutionTime => _showResolutionTime;
  bool get enableQuickActions => _enableQuickActions;
  String get workingHours => _workingHours;
  int get maxDailyAssignments => _maxDailyAssignments;

  Future<void> initializeSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      print("✅ Settings service initialized successfully");
    } catch (e) {
      print("❌ Failed to initialize settings: $e");
    }
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    // Load general settings
    _isDarkMode = _prefs!.getBool('dark_mode') ?? false;
    _selectedLanguage = _prefs!.getString('language') ?? 'English';
    _notificationsEnabled = _prefs!.getBool('notifications_enabled') ?? true;
    _soundEnabled = _prefs!.getBool('sound_enabled') ?? true;

    // Load official settings
    _autoAssignIssues = _prefs!.getBool('official_auto_assign_issues') ?? false;
    _urgentNotifications =
        _prefs!.getBool('official_urgent_notifications') ?? true;
    _statusUpdateNotifications =
        _prefs!.getBool('official_status_update_notifications') ?? true;
    _weeklyReportsEnabled = _prefs!.getBool('official_weekly_reports') ?? true;
    _showResolutionTime =
        _prefs!.getBool('official_show_resolution_time') ?? true;
    _enableQuickActions =
        _prefs!.getBool('official_enable_quick_actions') ?? true;
    _workingHours =
        _prefs!.getString('official_working_hours') ?? '9:00 AM - 5:00 PM';
    _maxDailyAssignments =
        _prefs!.getInt('official_max_daily_assignments') ?? 10;

    notifyListeners();
  }

  // General Settings Methods
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs?.setBool('dark_mode', value);
    notifyListeners();
    print("🎨 Dark mode ${value ? 'enabled' : 'disabled'}");
  }

  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    await _prefs?.setString('language', language);
    notifyListeners();
    print("🌍 Language changed to $language");
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool('notifications_enabled', value);
    notifyListeners();
    print("🔔 Notifications ${value ? 'enabled' : 'disabled'}");
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs?.setBool('sound_enabled', value);
    notifyListeners();
    print("🔊 Sound ${value ? 'enabled' : 'disabled'}");
  }

  // Official Settings Methods
  Future<void> setAutoAssignIssues(bool value) async {
    _autoAssignIssues = value;
    await _prefs?.setBool('official_auto_assign_issues', value);
    notifyListeners();
    print("📋 Auto-assign issues ${value ? 'enabled' : 'disabled'}");
  }

  Future<void> setUrgentNotifications(bool value) async {
    _urgentNotifications = value;
    await _prefs?.setBool('official_urgent_notifications', value);
    notifyListeners();
    print("🚨 Urgent notifications ${value ? 'enabled' : 'disabled'}");
  }

  Future<void> setStatusUpdateNotifications(bool value) async {
    _statusUpdateNotifications = value;
    await _prefs?.setBool('official_status_update_notifications', value);
    notifyListeners();
    print("📱 Status update notifications ${value ? 'enabled' : 'disabled'}");
  }

  Future<void> setWeeklyReports(bool value) async {
    _weeklyReportsEnabled = value;
    await _prefs?.setBool('official_weekly_reports', value);
    notifyListeners();
    print("📊 Weekly reports ${value ? 'enabled' : 'disabled'}");
  }

  Future<void> setShowResolutionTime(bool value) async {
    _showResolutionTime = value;
    await _prefs?.setBool('official_show_resolution_time', value);
    notifyListeners();
    print("⏱️ Show resolution time ${value ? 'enabled' : 'disabled'}");
  }

  Future<void> setQuickActions(bool value) async {
    _enableQuickActions = value;
    await _prefs?.setBool('official_enable_quick_actions', value);
    notifyListeners();
    print("⚡ Quick actions ${value ? 'enabled' : 'disabled'}");
  }

  Future<void> setWorkingHours(String hours) async {
    _workingHours = hours;
    await _prefs?.setString('official_working_hours', hours);
    notifyListeners();
    print("🕒 Working hours set to $hours");
  }

  Future<void> setMaxDailyAssignments(int max) async {
    _maxDailyAssignments = max;
    await _prefs?.setInt('official_max_daily_assignments', max);
    notifyListeners();
    print("📝 Max daily assignments set to $max");
  }

  // Generic method to get official settings
  T getOfficialSetting<T>(String key, T defaultValue) {
    if (_prefs == null) return defaultValue;

    switch (T) {
      case bool:
        return (_prefs!.getBool('official_$key') ?? defaultValue) as T;
      case int:
        return (_prefs!.getInt('official_$key') ?? defaultValue) as T;
      case String:
        return (_prefs!.getString('official_$key') ?? defaultValue) as T;
      case double:
        return (_prefs!.getDouble('official_$key') ?? defaultValue) as T;
      default:
        return defaultValue;
    }
  }

  // Generic method to save official settings
  Future<void> saveOfficialSetting<T>(String key, T value) async {
    if (_prefs == null) return;

    switch (T) {
      case bool:
        await _prefs!.setBool('official_$key', value as bool);
        break;
      case int:
        await _prefs!.setInt('official_$key', value as int);
        break;
      case String:
        await _prefs!.setString('official_$key', value as String);
        break;
      case double:
        await _prefs!.setDouble('official_$key', value as double);
        break;
    }

    // Update internal state based on key
    _updateInternalState(key, value);
    notifyListeners();
    print("💾 Official setting '$key' saved: $value");
  }

  void _updateInternalState<T>(String key, T value) {
    switch (key) {
      case 'auto_assign_issues':
        _autoAssignIssues = value as bool;
        break;
      case 'urgent_notifications':
        _urgentNotifications = value as bool;
        break;
      case 'status_update_notifications':
        _statusUpdateNotifications = value as bool;
        break;
      case 'weekly_reports':
        _weeklyReportsEnabled = value as bool;
        break;
      case 'show_resolution_time':
        _showResolutionTime = value as bool;
        break;
      case 'enable_quick_actions':
        _enableQuickActions = value as bool;
        break;
      case 'working_hours':
        _workingHours = value as String;
        break;
      case 'max_daily_assignments':
        _maxDailyAssignments = value as int;
        break;
    }
  }

  // Method to reset all settings to defaults
  Future<void> resetAllSettings() async {
    if (_prefs == null) return;

    // Clear all preferences
    await _prefs!.clear();

    // Reset to defaults
    _isDarkMode = false;
    _selectedLanguage = 'English';
    _notificationsEnabled = true;
    _soundEnabled = true;
    _autoAssignIssues = false;
    _urgentNotifications = true;
    _statusUpdateNotifications = true;
    _weeklyReportsEnabled = true;
    _showResolutionTime = true;
    _enableQuickActions = true;
    _workingHours = '9:00 AM - 5:00 PM';
    _maxDailyAssignments = 10;

    notifyListeners();
    print("🔄 All settings reset to defaults");
  }

  // Method to reset only official settings
  Future<void> resetOfficialSettings() async {
    if (_prefs == null) return;

    // Remove official settings
    final keys = _prefs!.getKeys().where((key) => key.startsWith('official_'));
    for (final key in keys) {
      await _prefs!.remove(key);
    }

    // Reset official settings to defaults
    _autoAssignIssues = false;
    _urgentNotifications = true;
    _statusUpdateNotifications = true;
    _weeklyReportsEnabled = true;
    _showResolutionTime = true;
    _enableQuickActions = true;
    _workingHours = '9:00 AM - 5:00 PM';
    _maxDailyAssignments = 10;

    notifyListeners();
    print("🔄 Official settings reset to defaults");
  }

  // Export settings as Map for backup
  Map<String, dynamic> exportSettings() {
    return {
      'general': {
        'dark_mode': _isDarkMode,
        'language': _selectedLanguage,
        'notifications_enabled': _notificationsEnabled,
        'sound_enabled': _soundEnabled,
      },
      'official': {
        'auto_assign_issues': _autoAssignIssues,
        'urgent_notifications': _urgentNotifications,
        'status_update_notifications': _statusUpdateNotifications,
        'weekly_reports': _weeklyReportsEnabled,
        'show_resolution_time': _showResolutionTime,
        'enable_quick_actions': _enableQuickActions,
        'working_hours': _workingHours,
        'max_daily_assignments': _maxDailyAssignments,
      },
    };
  }

  // Import settings from Map (for restore)
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (_prefs == null) return;

    try {
      // Import general settings
      if (settings.containsKey('general')) {
        final general = settings['general'] as Map<String, dynamic>;
        if (general.containsKey('dark_mode')) {
          await setDarkMode(general['dark_mode'] as bool);
        }
        if (general.containsKey('language')) {
          await setLanguage(general['language'] as String);
        }
        if (general.containsKey('notifications_enabled')) {
          await setNotifications(general['notifications_enabled'] as bool);
        }
        if (general.containsKey('sound_enabled')) {
          await setSoundEnabled(general['sound_enabled'] as bool);
        }
      }

      // Import official settings
      if (settings.containsKey('official')) {
        final official = settings['official'] as Map<String, dynamic>;
        if (official.containsKey('auto_assign_issues')) {
          await setAutoAssignIssues(official['auto_assign_issues'] as bool);
        }
        if (official.containsKey('urgent_notifications')) {
          await setUrgentNotifications(
            official['urgent_notifications'] as bool,
          );
        }
        if (official.containsKey('status_update_notifications')) {
          await setStatusUpdateNotifications(
            official['status_update_notifications'] as bool,
          );
        }
        if (official.containsKey('weekly_reports')) {
          await setWeeklyReports(official['weekly_reports'] as bool);
        }
        if (official.containsKey('show_resolution_time')) {
          await setShowResolutionTime(official['show_resolution_time'] as bool);
        }
        if (official.containsKey('enable_quick_actions')) {
          await setQuickActions(official['enable_quick_actions'] as bool);
        }
        if (official.containsKey('working_hours')) {
          await setWorkingHours(official['working_hours'] as String);
        }
        if (official.containsKey('max_daily_assignments')) {
          await setMaxDailyAssignments(
            official['max_daily_assignments'] as int,
          );
        }
      }

      print("📥 Settings imported successfully");
    } catch (e) {
      print("❌ Failed to import settings: $e");
    }
  }
}
