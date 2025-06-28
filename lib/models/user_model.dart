// models/user_model.dart (COMPLETE ENHANCED VERSION)
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String userType;
  final String? department; // New field for officials
  final String? employeeId; // New field for officials
  final String profilePicture;
  final DateTime? createdAt;
  final bool isVerified; // New field for account verification
  final bool isActive; // New field for account status
  final DateTime? verifiedAt; // When account was verified
  final String? verifiedBy; // Who verified the account
  final Map<String, dynamic>? metadata; // Additional user metadata

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.userType,
    this.department,
    this.employeeId,
    this.profilePicture = '',
    this.createdAt,
    this.isVerified = false,
    this.isActive = true,
    this.verifiedAt,
    this.verifiedBy,
    this.metadata,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      userType: data['userType'] ?? 'citizen',
      department: data['department'],
      employeeId: data['employeeId'],
      profilePicture: data['profilePicture'] ?? '',
      createdAt: data['createdAt']?.toDate(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      verifiedAt: data['verifiedAt']?.toDate(),
      verifiedBy: data['verifiedBy'],
      metadata:
          data['metadata'] != null
              ? Map<String, dynamic>.from(data['metadata'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'userType': userType,
      'department': department,
      'employeeId': employeeId,
      'profilePicture': profilePicture,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'isVerified': isVerified,
      'isActive': isActive,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'metadata': metadata,
    };
  }

  // Role checking methods
  bool get isAdmin => false; // Remove admin functionality
  bool get isCitizen => userType == 'citizen';
  bool get isOfficial => userType == 'official';

  // Department-specific methods
  bool get hasDepartment => department != null && department!.isNotEmpty;

  String get displayRole {
    switch (userType) {
      case 'official':
        return hasDepartment ? '$department Official' : 'Government Official';
      case 'citizen':
      default:
        return 'Citizen';
    }
  }

  String get displayName {
    if (isOfficial && employeeId != null) {
      return '$fullName (ID: $employeeId)';
    }
    return fullName;
  }

  String get shortDisplayName {
    final names = fullName.split(' ');
    if (names.length > 1) {
      return '${names.first} ${names.last[0]}.';
    }
    return fullName;
  }

  // Account status methods
  String get accountStatus {
    if (!isActive) return 'Inactive';
    if (isOfficial && !isVerified) return 'Pending Verification';
    if (isVerified) return 'Verified';
    return 'Active';
  }

  bool get canAccessDepartmentFeatures {
    return isOfficial && isVerified && isActive;
  }

  // Copy method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? userType,
    String? department,
    String? employeeId,
    String? profilePicture,
    DateTime? createdAt,
    bool? isVerified,
    bool? isActive,
    DateTime? verifiedAt,
    String? verifiedBy,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      userType: userType ?? this.userType,
      department: department ?? this.department,
      employeeId: employeeId ?? this.employeeId,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  // Validation methods
  bool get canManageIssues => isOfficial && isVerified;
  bool get canReportIssues => true; // Both citizens and officials can report
  bool get canViewAllIssues => false; // Remove admin-only features
  bool get canVerifyAccounts => false;

  // Check if user can manage issues in a specific category
  bool canManageCategory(String category) {
    if (isAdmin) return true;
    if (isOfficial && hasDepartment && isVerified) {
      return department == category;
    }
    return false;
  }

  // Get user initials for avatar
  String get initials {
    final names = fullName.trim().split(' ');
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names.first[0]}${names.last[0]}'.toUpperCase();
  }

  // Get verification badge info
  Map<String, dynamic> get verificationBadge {
    if (isOfficial && isVerified) {
      return {
        'text': 'VERIFIED',
        'color': 0xFF10B981, // Green
        'icon': 'verified',
      };
    }
    if (isOfficial && !isVerified) {
      return {
        'text': 'PENDING',
        'color': 0xFFF59E0B, // Amber
        'icon': 'pending',
      };
    }
    return {
      'text': 'CITIZEN',
      'color': 0xFF06B6D4, // Cyan
      'icon': 'person',
    };
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, fullName: $fullName, userType: $userType, department: $department, employeeId: $employeeId, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      userType: json['userType'] ?? 'citizen',
      department: json['department'],
      employeeId: json['employeeId'],
      profilePicture: json['profilePicture'] ?? '',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      verifiedAt:
          json['verifiedAt'] != null
              ? DateTime.parse(json['verifiedAt'])
              : null,
      verifiedBy: json['verifiedBy'],
      metadata: json['metadata'],
    );
  }
}

// Department definitions class
class Departments {
  static const List<Map<String, dynamic>> all = [
    {
      'name': 'Road & Transportation',
      'code': 'ROAD_TRANSPORT',
      'description': 'Roads, bridges, traffic systems, public transport',
      'contact': 'roads@civiclink.gov',
      'color': 0xFFF59E0B, // Amber
      'icon': 'construction',
      'priority_categories': ['High', 'Critical'],
      'sla_hours': 24, // Service Level Agreement in hours
    },
    {
      'name': 'Water & Sewerage',
      'code': 'WATER_SEWERAGE',
      'description': 'Water supply, drainage, sewerage systems',
      'contact': 'water@civiclink.gov',
      'color': 0xFF2563EB, // Blue
      'icon': 'water_drop',
      'priority_categories': ['Critical'],
      'sla_hours': 4,
    },
    {
      'name': 'Electricity',
      'code': 'ELECTRICITY',
      'description': 'Power supply, electrical infrastructure',
      'contact': 'power@civiclink.gov',
      'color': 0xFF06B6D4, // Cyan
      'icon': 'electrical_services',
      'priority_categories': ['High', 'Critical'],
      'sla_hours': 8,
    },
    {
      'name': 'Public Safety',
      'code': 'PUBLIC_SAFETY',
      'description': 'Police, fire department, emergency services',
      'contact': 'safety@civiclink.gov',
      'color': 0xFFEF4444, // Red
      'icon': 'security',
      'priority_categories': ['Critical'],
      'sla_hours': 1,
    },
    {
      'name': 'Waste Management',
      'code': 'WASTE_MANAGEMENT',
      'description': 'Garbage collection, recycling, waste disposal',
      'contact': 'waste@civiclink.gov',
      'color': 0xFF10B981, // Emerald
      'icon': 'delete',
      'priority_categories': ['Medium', 'High'],
      'sla_hours': 48,
    },
    {
      'name': 'Parks & Recreation',
      'code': 'PARKS_RECREATION',
      'description': 'Parks, playgrounds, recreation facilities',
      'contact': 'parks@civiclink.gov',
      'color': 0xFF4CAF50, // Green
      'icon': 'park',
      'priority_categories': ['Low', 'Medium'],
      'sla_hours': 72,
    },
    {
      'name': 'Street Lighting',
      'code': 'STREET_LIGHTING',
      'description': 'Street lights, public lighting systems',
      'contact': 'lighting@civiclink.gov',
      'color': 0xFFFFC107, // Yellow
      'icon': 'lightbulb',
      'priority_categories': ['Medium', 'High'],
      'sla_hours': 24,
    },
    {
      'name': 'Public Buildings',
      'code': 'PUBLIC_BUILDINGS',
      'description': 'Government buildings, public facilities',
      'contact': 'buildings@civiclink.gov',
      'color': 0xFF9C27B0, // Purple
      'icon': 'business',
      'priority_categories': ['Low', 'Medium', 'High'],
      'sla_hours': 48,
    },
    {
      'name': 'Traffic Management',
      'code': 'TRAFFIC_MANAGEMENT',
      'description': 'Traffic signals, road signs, traffic control',
      'contact': 'traffic@civiclink.gov',
      'color': 0xFFFF5722, // Deep Orange
      'icon': 'traffic',
      'priority_categories': ['High', 'Critical'],
      'sla_hours': 12,
    },
    {
      'name': 'Environmental Issues',
      'code': 'ENVIRONMENTAL',
      'description': 'Environmental protection, pollution control',
      'contact': 'environment@civiclink.gov',
      'color': 0xFF8BC34A, // Light Green
      'icon': 'eco',
      'priority_categories': ['Medium', 'High', 'Critical'],
      'sla_hours': 24,
    },
  ];

  // Helper methods
  static List<String> get names =>
      all.map((dept) => dept['name'] as String).toList();

  static Map<String, dynamic>? getByName(String name) {
    try {
      return all.firstWhere((dept) => dept['name'] == name);
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? getByCode(String code) {
    try {
      return all.firstWhere((dept) => dept['code'] == code);
    } catch (e) {
      return null;
    }
  }

  static String? getContactEmail(String departmentName) {
    final dept = getByName(departmentName);
    return dept?['contact'];
  }

  static int? getDepartmentColor(String departmentName) {
    final dept = getByName(departmentName);
    return dept?['color'];
  }

  static String? getDepartmentCode(String departmentName) {
    final dept = getByName(departmentName);
    return dept?['code'];
  }

  static int? getSlaHours(String departmentName) {
    final dept = getByName(departmentName);
    return dept?['sla_hours'];
  }

  static List<String> getPriorityCategories(String departmentName) {
    final dept = getByName(departmentName);
    return dept?['priority_categories']?.cast<String>() ?? [];
  }

  static bool isDepartmentValid(String departmentName) {
    return names.contains(departmentName);
  }

  static List<Map<String, dynamic>> getDepartmentsByPriority(String priority) {
    return all.where((dept) {
      final categories = dept['priority_categories'] as List<String>?;
      return categories?.contains(priority) ?? false;
    }).toList();
  }
}

// User types enum for better type safety
enum UserType {
  citizen,
  official,
  admin;

  String get displayName {
    switch (this) {
      case UserType.citizen:
        return 'Citizen';
      case UserType.official:
        return 'Official';
      case UserType.admin:
        return 'Administrator';
    }
  }

  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'citizen':
        return UserType.citizen;
      case 'official':
        return UserType.official;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.citizen;
    }
  }
}

// User verification status enum
enum VerificationStatus {
  pending,
  verified,
  rejected;

  String get displayName {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending Verification';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
}
