import 'dart:ui';
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'CivicLink';
  static const String appTagline = 'Report. Track. Resolve.';

  // User Types
  static const String userTypeCitizen = 'citizen';
  static const String userTypeOfficial = 'official'; // Added official type
  static const String userTypeAdmin = 'admin';

  // Collections
  static const String usersCollection = 'users';
  static const String issuesCollection = 'issues';
  static const String categoriesCollection = 'categories';
  static const String notificationsCollection =
      'notifications'; // Added notifications

  // Issue Status
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved = 'resolved';
  static const String statusRejected = 'rejected';

  // UPDATED: Issue Categories - now only 5 departments
  static const List<String> issueCategories = [
    'Public Safety',
    'Electricity and Power',
    'Water and Sewage',
    'Road and Transportation',
    'Environmental Issues',
  ];

  // NEW: Department information with icons and colors
  static const Map<String, Map<String, dynamic>> departmentInfo = {
    'Public Safety': {
      'icon': Icons.security,
      'emoji': '🚨',
      'color': 0xFFE53E3E,
      'description': 'Police, fire, emergency services',
      'code': 'PS',
    },
    'Electricity and Power': {
      'icon': Icons.electrical_services,
      'emoji': '⚡',
      'color': 0xFF805AD5,
      'description': 'Power supply, electrical infrastructure',
      'code': 'EP',
    },
    'Water and Sewage': {
      'icon': Icons.water_drop,
      'emoji': '💧',
      'color': 0xFF3182CE,
      'description': 'Water supply, drainage, sewerage systems',
      'code': 'WS',
    },
    'Road and Transportation': {
      'icon': Icons.construction,
      'emoji': '🚧',
      'color': 0xFFF6AD55,
      'description': 'Roads, bridges, traffic systems',
      'code': 'RT',
    },
    'Environmental Issues': {
      'icon': Icons.eco,
      'emoji': '🌱',
      'color': 0xFF38A169,
      'description': 'Environmental protection, pollution control',
      'code': 'EI',
    },
  };

  // NEW: Legacy category mapping for backward compatibility
  static const Map<String, String> legacyCategoryMapping = {
    'Road & Transportation': 'Road and Transportation',
    'Water & Sewerage': 'Water and Sewage',
    'Electricity': 'Electricity and Power',
    'Public Safety': 'Public Safety',
    'Waste Management': 'Environmental Issues',
    'Parks & Recreation': 'Environmental Issues',
    'Street Lighting': 'Environmental Issues',
    'Public Buildings': 'Environmental Issues',
    'Traffic Management': 'Environmental Issues',
    'Other': 'Environmental Issues',
  };

  // Priority Levels
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityCritical = 'critical';

  static const List<String> priorityLevels = [
    priorityLow,
    priorityMedium,
    priorityHigh,
    priorityCritical,
  ];

  // Validation
  static const int minPasswordLength = 6;
  static const int maxDescriptionLength = 500;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxImagesPerIssue = 5; // NEW: Limit images per issue

  // API Endpoints (for future AWS integration)
  static const String baseUrl = 'https://your-api-gateway-url.amazonaws.com';
  static const String uploadEndpoint = '/upload';
  static const String issuesEndpoint = '/issues';
  static const String usersEndpoint = '/users';

  // NEW: Helper methods for department management
  static String? getDepartmentEmoji(String category) {
    return departmentInfo[category]?['emoji'];
  }

  static IconData? getDepartmentIcon(String category) {
    return departmentInfo[category]?['icon'];
  }

  static Color? getDepartmentColor(String category) {
    final colorValue = departmentInfo[category]?['color'];
    return colorValue != null ? Color(colorValue) : null;
  }

  static String? getDepartmentDescription(String category) {
    return departmentInfo[category]?['description'];
  }

  static String? getDepartmentCode(String category) {
    return departmentInfo[category]?['code'];
  }

  // NEW: Map legacy categories to new departments
  static String mapLegacyCategory(String oldCategory) {
    return legacyCategoryMapping[oldCategory] ?? 'Environmental Issues';
  }

  // NEW: Validate if category is valid
  static bool isValidCategory(String category) {
    return issueCategories.contains(category);
  }

  // NEW: Validate if priority is valid
  static bool isValidPriority(String priority) {
    return priorityLevels.contains(priority);
  }
}

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color accent = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Status Colors
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusInProgress = Color(0xFF2196F3);
  static const Color statusResolved = Color(0xFF4CAF50);
  static const Color statusRejected = Color(0xFFF44336);

  // NEW: Department colors (matching the new 5 departments)
  static const Color publicSafety = Color(0xFFE53E3E);
  static const Color electricityPower = Color(0xFF805AD5);
  static const Color waterSewage = Color(0xFF3182CE);
  static const Color roadTransportation = Color(0xFFF6AD55);
  static const Color environmentalIssues = Color(0xFF38A169);

  // NEW: Priority colors
  static const Color priorityLowColor = success;
  static const Color priorityMediumColor = warning;
  static const Color priorityHighColor = error;
  static const Color priorityCriticalColor = Color(0xFFDC2626);

  // NEW: Helper method to get priority color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case AppConstants.priorityLow:
        return priorityLowColor;
      case AppConstants.priorityMedium:
        return priorityMediumColor;
      case AppConstants.priorityHigh:
        return priorityHighColor;
      case AppConstants.priorityCritical:
        return priorityCriticalColor;
      default:
        return textSecondary;
    }
  }

  // NEW: Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusPending:
        return statusPending;
      case AppConstants.statusInProgress:
        return statusInProgress;
      case AppConstants.statusResolved:
        return statusResolved;
      case AppConstants.statusRejected:
        return statusRejected;
      default:
        return textSecondary;
    }
  }
}

class AppStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textHint,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // NEW: Additional text styles for enhanced UI
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle statusText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}
