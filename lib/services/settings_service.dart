// services/enhanced_settings_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  // Private instance
  static final SettingsService _instance = SettingsService._internal();

  // Factory constructor
  factory SettingsService() => _instance;

  // Private constructor
  SettingsService._internal();

  // Settings properties
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _locationEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';
  bool _darkMode = false;
  bool _biometricEnabled = false;

  // Email preferences
  bool _issueUpdates = true;
  bool _weeklyDigest = false;
  bool _promotionalEmails = false;

  // Privacy settings
  bool _dataCollection = true;
  bool _analyticsEnabled = true;
  bool _crashReporting = true;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emailNotifications => _emailNotifications;
  bool get pushNotifications => _pushNotifications;
  bool get locationEnabled => _locationEnabled;
  String get selectedLanguage => _selectedLanguage;
  String get selectedTheme => _selectedTheme;
  bool get darkMode => _darkMode;
  bool get biometricEnabled => _biometricEnabled;
  bool get issueUpdates => _issueUpdates;
  bool get weeklyDigest => _weeklyDigest;
  bool get promotionalEmails => _promotionalEmails;
  bool get dataCollection => _dataCollection;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get crashReporting => _crashReporting;

  // Initialize settings (load from SharedPreferences)
  Future<void> initializeSettings() async {
    try {
      print("🔧 SettingsService: Initializing settings...");

      SharedPreferences prefs = await SharedPreferences.getInstance();

      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _locationEnabled = prefs.getBool('location_enabled') ?? false;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      _selectedTheme = prefs.getString('selected_theme') ?? 'Light';
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

      // Email preferences
      _issueUpdates = prefs.getBool('issue_updates') ?? true;
      _weeklyDigest = prefs.getBool('weekly_digest') ?? false;
      _promotionalEmails = prefs.getBool('promotional_emails') ?? false;

      // Privacy settings
      _dataCollection = prefs.getBool('data_collection') ?? true;
      _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
      _crashReporting = prefs.getBool('crash_reporting') ?? true;

      print("✅ SettingsService: Settings loaded successfully");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to initialize settings: $e");
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (notificationsEnabled != null) {
        _notificationsEnabled = notificationsEnabled;
        await prefs.setBool('notifications_enabled', notificationsEnabled);
      }

      if (emailNotifications != null) {
        _emailNotifications = emailNotifications;
        await prefs.setBool('email_notifications', emailNotifications);
      }

      if (pushNotifications != null) {
        _pushNotifications = pushNotifications;
        await prefs.setBool('push_notifications', pushNotifications);
      }

      print("✅ SettingsService: Notification settings updated");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to update notification settings: $e");
      rethrow;
    }
  }

  // Update app preferences
  Future<void> updateAppPreferences({
    String? language,
    String? theme,
    bool? darkMode,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (language != null) {
        _selectedLanguage = language;
        await prefs.setString('selected_language', language);
      }

      if (theme != null) {
        _selectedTheme = theme;
        await prefs.setString('selected_theme', theme);
      }

      if (darkMode != null) {
        _darkMode = darkMode;
        await prefs.setBool('dark_mode', darkMode);
      }

      print("✅ SettingsService: App preferences updated");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to update app preferences: $e");
      rethrow;
    }
  }

  // Update privacy settings
  Future<void> updatePrivacySettings({
    bool? locationEnabled,
    bool? biometricEnabled,
    bool? dataCollection,
    bool? analyticsEnabled,
    bool? crashReporting,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (locationEnabled != null) {
        _locationEnabled = locationEnabled;
        await prefs.setBool('location_enabled', locationEnabled);
      }

      if (biometricEnabled != null) {
        _biometricEnabled = biometricEnabled;
        await prefs.setBool('biometric_enabled', biometricEnabled);
      }

      if (dataCollection != null) {
        _dataCollection = dataCollection;
        await prefs.setBool('data_collection', dataCollection);
      }

      if (analyticsEnabled != null) {
        _analyticsEnabled = analyticsEnabled;
        await prefs.setBool('analytics_enabled', analyticsEnabled);
      }

      if (crashReporting != null) {
        _crashReporting = crashReporting;
        await prefs.setBool('crash_reporting', crashReporting);
      }

      print("✅ SettingsService: Privacy settings updated");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to update privacy settings: $e");
      rethrow;
    }
  }

  // Update email preferences
  Future<void> updateEmailPreferences({
    bool? issueUpdates,
    bool? weeklyDigest,
    bool? promotionalEmails,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (issueUpdates != null) {
        _issueUpdates = issueUpdates;
        await prefs.setBool('issue_updates', issueUpdates);
      }

      if (weeklyDigest != null) {
        _weeklyDigest = weeklyDigest;
        await prefs.setBool('weekly_digest', weeklyDigest);
      }

      if (promotionalEmails != null) {
        _promotionalEmails = promotionalEmails;
        await prefs.setBool('promotional_emails', promotionalEmails);
      }

      print("✅ SettingsService: Email preferences updated");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to update email preferences: $e");
      rethrow;
    }
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Clear all settings
      await prefs.clear();

      // Reset to default values
      _notificationsEnabled = true;
      _emailNotifications = true;
      _pushNotifications = true;
      _locationEnabled = false;
      _selectedLanguage = 'English';
      _selectedTheme = 'Light';
      _darkMode = false;
      _biometricEnabled = false;
      _issueUpdates = true;
      _weeklyDigest = false;
      _promotionalEmails = false;
      _dataCollection = true;
      _analyticsEnabled = true;
      _crashReporting = true;

      print("✅ SettingsService: Settings reset to defaults");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to reset settings: $e");
      rethrow;
    }
  }

  // Export settings as JSON (for data export feature)
  Map<String, dynamic> exportSettings() {
    return {
      'app_info': {
        'version': '1.0.0',
        'exported_at': DateTime.now().toIso8601String(),
      },
      'notifications': {
        'notifications_enabled': _notificationsEnabled,
        'email_notifications': _emailNotifications,
        'push_notifications': _pushNotifications,
      },
      'app_preferences': {
        'selected_language': _selectedLanguage,
        'selected_theme': _selectedTheme,
        'dark_mode': _darkMode,
      },
      'privacy': {
        'location_enabled': _locationEnabled,
        'biometric_enabled': _biometricEnabled,
        'data_collection': _dataCollection,
        'analytics_enabled': _analyticsEnabled,
        'crash_reporting': _crashReporting,
      },
      'email_preferences': {
        'issue_updates': _issueUpdates,
        'weekly_digest': _weeklyDigest,
        'promotional_emails': _promotionalEmails,
      },
    };
  }

  // Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Import notifications
      if (settings['notifications'] != null) {
        final notifications = settings['notifications'];
        _notificationsEnabled = notifications['notifications_enabled'] ?? true;
        _emailNotifications = notifications['email_notifications'] ?? true;
        _pushNotifications = notifications['push_notifications'] ?? true;

        await prefs.setBool('notifications_enabled', _notificationsEnabled);
        await prefs.setBool('email_notifications', _emailNotifications);
        await prefs.setBool('push_notifications', _pushNotifications);
      }

      // Import app preferences
      if (settings['app_preferences'] != null) {
        final appPrefs = settings['app_preferences'];
        _selectedLanguage = appPrefs['selected_language'] ?? 'English';
        _selectedTheme = appPrefs['selected_theme'] ?? 'Light';
        _darkMode = appPrefs['dark_mode'] ?? false;

        await prefs.setString('selected_language', _selectedLanguage);
        await prefs.setString('selected_theme', _selectedTheme);
        await prefs.setBool('dark_mode', _darkMode);
      }

      // Import privacy settings
      if (settings['privacy'] != null) {
        final privacy = settings['privacy'];
        _locationEnabled = privacy['location_enabled'] ?? false;
        _biometricEnabled = privacy['biometric_enabled'] ?? false;
        _dataCollection = privacy['data_collection'] ?? true;
        _analyticsEnabled = privacy['analytics_enabled'] ?? true;
        _crashReporting = privacy['crash_reporting'] ?? true;

        await prefs.setBool('location_enabled', _locationEnabled);
        await prefs.setBool('biometric_enabled', _biometricEnabled);
        await prefs.setBool('data_collection', _dataCollection);
        await prefs.setBool('analytics_enabled', _analyticsEnabled);
        await prefs.setBool('crash_reporting', _crashReporting);
      }

      // Import email preferences
      if (settings['email_preferences'] != null) {
        final emailPrefs = settings['email_preferences'];
        _issueUpdates = emailPrefs['issue_updates'] ?? true;
        _weeklyDigest = emailPrefs['weekly_digest'] ?? false;
        _promotionalEmails = emailPrefs['promotional_emails'] ?? false;

        await prefs.setBool('issue_updates', _issueUpdates);
        await prefs.setBool('weekly_digest', _weeklyDigest);
        await prefs.setBool('promotional_emails', _promotionalEmails);
      }

      print("✅ SettingsService: Settings imported successfully");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to import settings: $e");
      rethrow;
    }
  }

  // Get app version and info
  Map<String, String> getAppInfo() {
    return {
      'version': '1.0.0',
      'build': '100',
      'release_date': '2025-01-01',
      'platform': defaultTargetPlatform.name,
    };
  }

  // Check if feature is enabled
  bool isFeatureEnabled(String feature) {
    switch (feature) {
      case 'notifications':
        return _notificationsEnabled;
      case 'location':
        return _locationEnabled;
      case 'biometric':
        return _biometricEnabled;
      case 'analytics':
        return _analyticsEnabled;
      default:
        return false;
    }
  }

  // Get theme mode
  ThemeMode getThemeMode() {
    switch (_selectedTheme.toLowerCase()) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  // Update single setting
  Future<void> updateSingleSetting(String key, dynamic value) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      switch (key) {
        case 'notifications_enabled':
          _notificationsEnabled = value as bool;
          await prefs.setBool(key, value);
          break;
        case 'email_notifications':
          _emailNotifications = value as bool;
          await prefs.setBool(key, value);
          break;
        case 'push_notifications':
          _pushNotifications = value as bool;
          await prefs.setBool(key, value);
          break;
        case 'location_enabled':
          _locationEnabled = value as bool;
          await prefs.setBool(key, value);
          break;
        case 'biometric_enabled':
          _biometricEnabled = value as bool;
          await prefs.setBool(key, value);
          break;
        case 'selected_language':
          _selectedLanguage = value as String;
          await prefs.setString(key, value);
          break;
        case 'selected_theme':
          _selectedTheme = value as String;
          await prefs.setString(key, value);
          break;
        default:
          print("⚠️ Unknown setting key: $key");
          return;
      }

      print("✅ SettingsService: Updated $key to $value");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to update $key: $e");
      rethrow;
    }
  }
}
