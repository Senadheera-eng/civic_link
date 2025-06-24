// services/settings_service.dart
import 'package:flutter/foundation.dart';

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

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emailNotifications => _emailNotifications;
  bool get pushNotifications => _pushNotifications;
  bool get locationEnabled => _locationEnabled;
  String get selectedLanguage => _selectedLanguage;
  String get selectedTheme => _selectedTheme;
  bool get darkMode => _darkMode;
  bool get biometricEnabled => _biometricEnabled;

  // Initialize settings (would typically load from SharedPreferences)
  Future<void> initializeSettings() async {
    try {
      // In a real app, you would load from SharedPreferences here
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      // _emailNotifications = prefs.getBool('email_notifications') ?? true;
      // etc.

      print("🔧 SettingsService: Settings initialized");
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
      if (notificationsEnabled != null) {
        _notificationsEnabled = notificationsEnabled;
        // await _saveToPrefs('notifications_enabled', notificationsEnabled);
      }

      if (emailNotifications != null) {
        _emailNotifications = emailNotifications;
        // await _saveToPrefs('email_notifications', emailNotifications);
      }

      if (pushNotifications != null) {
        _pushNotifications = pushNotifications;
        // await _saveToPrefs('push_notifications', pushNotifications);
      }

      print("🔧 SettingsService: Notification settings updated");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to update notification settings: $e");
    }
  }

  // Update app preferences
  Future<void> updateAppPreferences({
    String? language,
    String? theme,
    bool? darkMode,
  }) async {
    try {
      if (language != null) {
        _selectedLanguage = language;
        // await _saveToPrefs('selected_language', language);
      }

      if (theme != null) {
        _selectedTheme = theme;
        // await _saveToPrefs('selected_theme', theme);
      }

      if (darkMode != null) {
        _darkMode = darkMode;
        // await _saveToPrefs('dark_mode', darkMode);
      }

      print("🔧 SettingsService: App preferences updated");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to update app preferences: $e");
    }
  }

  // Update privacy settings
  Future<void> updatePrivacySettings({
    bool? locationEnabled,
    bool? biometricEnabled,
  }) async {
    try {
      if (locationEnabled != null) {
        _locationEnabled = locationEnabled;
        // await _saveToPrefs('location_enabled', locationEnabled);
      }

      if (biometricEnabled != null) {
        _biometricEnabled = biometricEnabled;
        // await _saveToPrefs('biometric_enabled', biometricEnabled);
      }

      print("🔧 SettingsService: Privacy settings updated");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to update privacy settings: $e");
    }
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      _notificationsEnabled = true;
      _emailNotifications = true;
      _pushNotifications = true;
      _locationEnabled = false;
      _selectedLanguage = 'English';
      _selectedTheme = 'Light';
      _darkMode = false;
      _biometricEnabled = false;

      // In a real app, clear SharedPreferences
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.clear();

      print("🔧 SettingsService: Settings reset to defaults");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to reset settings: $e");
    }
  }

  // Export settings as JSON (for data export feature)
  Map<String, dynamic> exportSettings() {
    return {
      'notifications_enabled': _notificationsEnabled,
      'email_notifications': _emailNotifications,
      'push_notifications': _pushNotifications,
      'location_enabled': _locationEnabled,
      'selected_language': _selectedLanguage,
      'selected_theme': _selectedTheme,
      'dark_mode': _darkMode,
      'biometric_enabled': _biometricEnabled,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  // Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      _notificationsEnabled = settings['notifications_enabled'] ?? true;
      _emailNotifications = settings['email_notifications'] ?? true;
      _pushNotifications = settings['push_notifications'] ?? true;
      _locationEnabled = settings['location_enabled'] ?? false;
      _selectedLanguage = settings['selected_language'] ?? 'English';
      _selectedTheme = settings['selected_theme'] ?? 'Light';
      _darkMode = settings['dark_mode'] ?? false;
      _biometricEnabled = settings['biometric_enabled'] ?? false;

      print("🔧 SettingsService: Settings imported successfully");
      notifyListeners();
    } catch (e) {
      print("❌ SettingsService: Failed to import settings: $e");
    }
  }

  // Helper method to save to SharedPreferences (commented out for now)
  /*
  Future<void> _saveToPrefs(String key, dynamic value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }
  */
}
