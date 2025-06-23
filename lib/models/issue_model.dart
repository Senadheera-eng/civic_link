// models/issue_model.dart
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

  // Create from Firestore document
  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return IssueModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
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
      'category': category,
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
}

// Issue categories
class IssueCategories {
  static const List<String> categories = [
    'Road & Transportation',
    'Water & Sewerage',
    'Electricity',
    'Public Safety',
    'Waste Management',
    'Parks & Recreation',
    'Street Lighting',
    'Public Buildings',
    'Traffic Management',
    'Environmental Issues',
    'Other',
  ];

  static const Map<String, String> categoryIcons = {
    'Road & Transportation': '🛣️',
    'Water & Sewerage': '💧',
    'Electricity': '⚡',
    'Public Safety': '🚨',
    'Waste Management': '🗑️',
    'Parks & Recreation': '🌳',
    'Street Lighting': '💡',
    'Public Buildings': '🏛️',
    'Traffic Management': '🚦',
    'Environmental Issues': '🌍',
    'Other': '📝',
  };
}

// Issue priorities
class IssuePriorities {
  static const List<String> priorities = ['Low', 'Medium', 'High', 'Critical'];

  static const Map<String, String> priorityDescriptions = {
    'Low': 'Minor issue, can wait',
    'Medium': 'Moderate priority',
    'High': 'Needs attention soon',
    'Critical': 'Urgent, safety concern',
  };
}
