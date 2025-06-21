import 'dart:ui';

import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'CivicLink';
  static const String appTagline = 'Report. Track. Resolve.';

  // User Types
  static const String userTypeCitizen = 'citizen';
  static const String userTypeAdmin = 'admin';

  // Collections
  static const String usersCollection = 'users';
  static const String issuesCollection = 'issues';
  static const String categoriesCollection = 'categories';

  // Issue Status
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved = 'resolved';
  static const String statusRejected = 'rejected';

  // Issue Categories
  static const List<String> issueCategories = [
    'Road & Transportation',
    'Water & Sewerage',
    'Electricity',
    'Public Safety',
    'Waste Management',
    'Parks & Recreation',
    'Street Lighting',
    'Other',
  ];

  // Priority Levels
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityCritical = 'critical';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxDescriptionLength = 500;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  // API Endpoints (for future AWS integration)
  static const String baseUrl = 'https://your-api-gateway-url.amazonaws.com';
  static const String uploadEndpoint = '/upload';
  static const String issuesEndpoint = '/issues';
  static const String usersEndpoint = '/users';
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
}
