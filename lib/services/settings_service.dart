// services/settings_service.dart (FINAL FIXED VERSION)
import 'package:flutter/foundation.dart';
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
  bool _isDarkMode = false;
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
  bool get isDarkMode => _isDarkMode;
  bool get biometricEnabled => _biometricEnabled;
  bool get issueUpdates => _issueUpdates;
  bool get weeklyDigest => _weeklyDigest;
  bool get promotionalEmails => _promotionalEmails;
  bool get dataCollection => _dataCollection;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get crashReporting => _crashReporting;

  // Get locale for the app
  String get localeCode {
    switch (_selectedLanguage) {
      case 'Sinhala':
        return 'si_LK';
      case 'English':
      default:
        return 'en_US';
    }
  }

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
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
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
      print("🌙 Dark mode: $_isDarkMode");
      print("🌍 Language: $_selectedLanguage");

      // Notify listeners that settings have been loaded
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

  // Update app preferences with proper notification
  Future<void> updateAppPreferences({String? language, bool? darkMode}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool shouldNotify = false;

      if (language != null && language != _selectedLanguage) {
        _selectedLanguage = language;
        await prefs.setString('selected_language', language);
        print("🌍 Language changed to: $language");
        shouldNotify = true;
      }

      if (darkMode != null && darkMode != _isDarkMode) {
        _isDarkMode = darkMode;
        await prefs.setBool('is_dark_mode', darkMode);
        print("🌙 Dark mode changed to: $darkMode");
        shouldNotify = true;
      }

      if (shouldNotify) {
        print(
          "✅ SettingsService: App preferences updated, notifying listeners",
        );
        notifyListeners();
      }
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

  // Force update theme
  Future<void> toggleDarkMode() async {
    await updateAppPreferences(darkMode: !_isDarkMode);
  }

  // Force update language
  Future<void> changeLanguage(String language) async {
    await updateAppPreferences(language: language);
  }

  // Export settings as JSON
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
        'is_dark_mode': _isDarkMode,
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
}
