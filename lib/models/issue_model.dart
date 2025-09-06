// models/issue_model.dart (FIXED VERSION)
import 'package:cloud_firestore/cloud_firestore.dart';

class IssueModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String priority;
  final String userId;
  final String userEmail;
  final String userName;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminNotes;
  final String? assignedTo;

  IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.imageUrls,
    required this.createdAt,
    this.updatedAt,
    this.adminNotes,
    this.assignedTo,
  });

  // FIXED: Create from Firestore document WITHOUT automatic category mapping
  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Get the raw category - DON'T map it automatically
    String rawCategory = data['category'] ?? 'Environmental Issues';

    // Only map if it's actually a legacy category that needs mapping
    String finalCategory;
    if (_isLegacyCategory(rawCategory)) {
      finalCategory = _mapLegacyCategory(rawCategory);
      print("📋 Mapping legacy category '$rawCategory' to '$finalCategory'");
    } else {
      // It's already a valid new category, use it as-is
      finalCategory = rawCategory;
      print("📋 Using category as-is: '$finalCategory'");
    }

    return IssueModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: finalCategory, // Use the correct category
      status: data['status'] ?? 'pending',
      priority: data['priority'] ?? 'medium',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'],
      assignedTo: data['assignedTo'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category, // This should preserve the exact category
      'status': status,
      'priority': priority,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminNotes': adminNotes,
      'assignedTo': assignedTo,
    };
  }

  // Copy with updates
  IssueModel copyWith({
    String? title,
    String? description,
    String? category,
    String? status,
    String? priority,
    String? userId,
    String? userEmail,
    String? userName,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminNotes,
    String? assignedTo,
  }) {
    return IssueModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  // Get status color
  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'warning';
      case 'in_progress':
        return 'info';
      case 'resolved':
        return 'success';
      case 'rejected':
        return 'error';
      default:
        return 'secondary';
    }
  }

  // Get priority color
  static String getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'success';
      case 'medium':
        return 'warning';
      case 'high':
        return 'error';
      case 'critical':
        return 'error';
      default:
        return 'secondary';
    }
  }

  // NEW: Check if a category is a legacy category that needs mapping
  static bool _isLegacyCategory(String category) {
    const legacyCategories = [
      'Road & Transportation',
      'Water & Sewerage',
      'Electricity',
      'Waste Management',
      'Parks & Recreation',
      'Street Lighting',
      'Public Buildings',
      'Traffic Management',
      'Other',
    ];
    return legacyCategories.contains(category);
  }

  // FIXED: Map legacy categories to new 5 departments - only for actual legacy categories
  static String _mapLegacyCategory(String oldCategory) {
    switch (oldCategory) {
      case 'Road & Transportation':
        return 'Road and Transportation';
      case 'Water & Sewerage':
        return 'Water and Sewage';
      case 'Electricity':
        return 'Electricity and Power';
      case 'Waste Management':
      case 'Parks & Recreation':
      case 'Street Lighting':
      case 'Public Buildings':
      case 'Traffic Management':
      case 'Other':
        return 'Environmental Issues';
      default:
        // If it's not a known legacy category, return it as-is
        // This prevents valid new categories from being changed
        return oldCategory;
    }
  }

  // NEW: Check if category is valid
  bool get isValidCategory => IssueCategories.categories.contains(category);

  // NEW: Check if priority is valid
  bool get isValidPriority => IssuePriorities.priorities
      .map((p) => p.toLowerCase())
      .contains(priority.toLowerCase());

  // NEW: Check if status is valid
  bool get isValidStatus => [
    'pending',
    'in_progress',
    'resolved',
    'rejected',
  ].contains(status.toLowerCase());
}

// Keep the rest of your classes exactly the same...
class IssueCategories {
  static const List<String> categories = [
    'Public Safety',
    'Electricity and Power',
    'Water and Sewage',
    'Road and Transportation',
    'Environmental Issues',
  ];

  static const Map<String, String> categoryIcons = {
    'Public Safety': '🚨',
    'Electricity and Power': '⚡',
    'Water and Sewage': '💧',
    'Road and Transportation': '🚧',
    'Environmental Issues': '🌱',
  };

  static const Map<String, String> categoryDescriptions = {
    'Public Safety': 'Police, fire, emergency services',
    'Electricity and Power': 'Power supply, electrical infrastructure',
    'Water and Sewage': 'Water supply, drainage, sewerage systems',
    'Road and Transportation': 'Roads, bridges, traffic systems',
    'Environmental Issues': 'Environmental protection, pollution control',
  };

  static const Map<String, int> categoryColors = {
    'Public Safety': 0xFFE53E3E, // Red
    'Electricity and Power': 0xFF805AD5, // Purple
    'Water and Sewage': 0xFF3182CE, // Blue
    'Road and Transportation': 0xFFF6AD55, // Orange
    'Environmental Issues': 0xFF38A169, // Green
  };

  static String getIcon(String category) => categoryIcons[category] ?? '📋';
  static String getDescription(String category) =>
      categoryDescriptions[category] ?? 'General issue';
  static int getColorValue(String category) =>
      categoryColors[category] ?? 0xFF718096;

  static bool isValidCategory(String category) => categories.contains(category);

  static String mapLegacyCategory(String oldCategory) {
    switch (oldCategory) {
      case 'Road & Transportation':
        return 'Road and Transportation';
      case 'Water & Sewerage':
        return 'Water and Sewage';
      case 'Electricity':
        return 'Electricity and Power';
      case 'Public Safety':
        return 'Public Safety';
      case 'Waste Management':
      case 'Parks & Recreation':
      case 'Street Lighting':
      case 'Public Buildings':
      case 'Traffic Management':
      case 'Environmental Issues':
      case 'Other':
        return 'Environmental Issues';
      default:
        return 'Environmental Issues';
    }
  }
}

class IssuePriorities {
  static const List<String> priorities = ['Low', 'Medium', 'High', 'Critical'];

  static const Map<String, String> priorityDescriptions = {
    'Low': 'Minor issue, can wait',
    'Medium': 'Moderate priority',
    'High': 'Needs attention soon',
    'Critical': 'Urgent, safety concern',
  };

  static const Map<String, int> priorityColors = {
    'Low': 0xFF4CAF50, // Green
    'Medium': 0xFFFF9800, // Orange
    'High': 0xFFE53E3E, // Red
    'Critical': 0xFFDC2626, // Dark Red
  };

  static String getDescription(String priority) =>
      priorityDescriptions[priority] ?? 'Unknown priority';
  static int getColorValue(String priority) =>
      priorityColors[priority] ?? 0xFF718096;
  static bool isValidPriority(String priority) =>
      priorities.map((p) => p.toLowerCase()).contains(priority.toLowerCase());
}

class IssueStatuses {
  static const List<String> statuses = [
    'Pending',
    'In Progress',
    'Resolved',
    'Rejected',
  ];

  static const Map<String, String> statusDescriptions = {
    'Pending': 'Issue reported, waiting for review',
    'In Progress': 'Issue is being worked on',
    'Resolved': 'Issue has been fixed',
    'Rejected': 'Issue was rejected or invalid',
  };

  static const Map<String, int> statusColors = {
    'Pending': 0xFFFF9800, // Orange
    'In Progress': 0xFF2196F3, // Blue
    'Resolved': 0xFF4CAF50, // Green
    'Rejected': 0xFFF44336, // Red
  };

  static String getDescription(String status) {
    final normalizedStatus = _normalizeStatus(status);
    return statusDescriptions[normalizedStatus] ?? 'Unknown status';
  }

  static int getColorValue(String status) {
    final normalizedStatus = _normalizeStatus(status);
    return statusColors[normalizedStatus] ?? 0xFF718096;
  }

  static bool isValidStatus(String status) {
    return [
      'pending',
      'in_progress',
      'resolved',
      'rejected',
    ].contains(status.toLowerCase());
  }

  static String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
