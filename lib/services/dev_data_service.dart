// services/dev_data_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/issue_model.dart';
import '../services/notification_service.dart';

class DevDataService {
  static final DevDataService _instance = DevDataService._internal();
  factory DevDataService() => _instance;
  DevDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if this is a fresh install and seed data if needed
  Future<void> checkAndSeedData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print("🌱 DevDataService: Checking if data seeding is needed...");

      // Check if user has any issues
      final userIssues =
          await _firestore
              .collection('issues')
              .where('userId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (userIssues.docs.isEmpty) {
        print(
          "🌱 DevDataService: No issues found, seeding development data...",
        );
        await _seedDevelopmentData();
      } else {
        print("✅ DevDataService: User already has data, skipping seeding");
      }
    } catch (e) {
      print("❌ DevDataService: Error checking/seeding data: $e");
    }
  }

  Future<void> _seedDevelopmentData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Create sample issues
      await _createSampleIssues(user);

      // Create sample notifications
      await _createSampleNotifications(user.uid);

      print("✅ DevDataService: Development data seeded successfully");
    } catch (e) {
      print("❌ DevDataService: Error seeding development data: $e");
    }
  }

  Future<void> _createSampleIssues(User user) async {
    final sampleIssues = [
      {
        'title': 'Broken Streetlight on Main Road',
        'description':
            'The streetlight near the park has been broken for a week, making it dangerous for pedestrians at night.',
        'category': 'Street Lighting',
        'priority': 'High',
        'status': 'pending',
        'address': 'Main Road, Near Central Park',
        'latitude': 6.9271,
        'longitude': 79.8612,
      },
      {
        'title': 'Pothole on Highway',
        'description':
            'Large pothole causing traffic issues and potential vehicle damage.',
        'category': 'Road & Transportation',
        'priority': 'Medium',
        'status': 'in_progress',
        'address': 'Highway A1, Kadugannawa',
        'latitude': 7.2533,
        'longitude': 80.5169,
      },
      {
        'title': 'Water Leak in Residential Area',
        'description': 'Water pipe burst causing flooding in the street.',
        'category': 'Water & Sewerage',
        'priority': 'Critical',
        'status': 'resolved',
        'address': 'Residential Street 15',
        'latitude': 6.9319,
        'longitude': 79.8478,
        'adminNotes': 'Fixed by municipal water department on emergency basis.',
      },
      {
        'title': 'Illegal Dumping Site',
        'description':
            'People are dumping garbage in the empty lot, creating health hazards.',
        'category': 'Waste Management',
        'priority': 'Medium',
        'status': 'pending',
        'address': 'Empty Lot, Station Road',
        'latitude': 7.2906,
        'longitude': 80.6337,
      },
      {
        'title': 'Park Maintenance Required',
        'description':
            'Playground equipment needs repair and grass cutting is overdue.',
        'category': 'Parks & Recreation',
        'priority': 'Low',
        'status': 'in_progress',
        'address': 'Community Park, Wellness Road',
        'latitude': 6.9147,
        'longitude': 79.8721,
      },
    ];

    for (int i = 0; i < sampleIssues.length; i++) {
      final issueData = sampleIssues[i];
      final createdAt = DateTime.now().subtract(Duration(days: i + 1));

      await _firestore.collection('issues').add({
        'title': issueData['title'],
        'description': issueData['description'],
        'category': issueData['category'],
        'priority': issueData['priority'],
        'status': issueData['status'],
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? 'Development User',
        'address': issueData['address'],
        'latitude': issueData['latitude'],
        'longitude': issueData['longitude'],
        'imageUrls': <String>[], // Empty for development
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt':
            issueData['status'] != 'pending'
                ? Timestamp.fromDate(createdAt.add(Duration(hours: 2)))
                : null,
        'adminNotes': issueData['adminNotes'],
      });

      print("✅ Created sample issue: ${issueData['title']}");
    }
  }

  Future<void> _createSampleNotifications(String userId) async {
    final sampleNotifications = [
      {
        'title': '🎉 Welcome to CivicLink!',
        'body':
            'Thank you for joining CivicLink. Start reporting community issues and make a difference!',
        'type': 'welcome',
        'isRead': false,
      },
      {
        'title': '✅ Issue Status Updated',
        'body':
            'Your issue "Water Leak in Residential Area" has been resolved.',
        'type': 'issue_update',
        'isRead': false,
      },
      {
        'title': '🔧 Issue In Progress',
        'body':
            'Your issue "Pothole on Highway" is now being worked on by the Road Department.',
        'type': 'issue_update',
        'isRead': true,
      },
      {
        'title': '📢 System Update',
        'body':
            'CivicLink has been updated with new features and improvements.',
        'type': 'system_update',
        'isRead': true,
      },
    ];

    for (int i = 0; i < sampleNotifications.length; i++) {
      final notificationData = sampleNotifications[i];
      final createdAt = DateTime.now().subtract(Duration(hours: i * 6));

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': notificationData['title'],
        'body': notificationData['body'],
        'data': {'type': notificationData['type']},
        'isRead': notificationData['isRead'],
        'createdAt': Timestamp.fromDate(createdAt),
        'readAt':
            notificationData['isRead'] == true
                ? Timestamp.fromDate(createdAt.add(Duration(minutes: 30)))
                : null,
      });

      print("✅ Created sample notification: ${notificationData['title']}");
    }
  }

  // Method to manually trigger data seeding (for testing)
  Future<void> forceSeedData() async {
    print("🌱 DevDataService: Force seeding development data...");
    await _seedDevelopmentData();
  }

  // Method to clear all development data
  Future<void> clearDevelopmentData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print("🧹 DevDataService: Clearing development data...");

      // Delete user's issues
      final userIssues =
          await _firestore
              .collection('issues')
              .where('userId', isEqualTo: user.uid)
              .get();

      final batch = _firestore.batch();
      for (var doc in userIssues.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's notifications
      final userNotifications =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .get();

      for (var doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print("✅ DevDataService: Development data cleared");
    } catch (e) {
      print("❌ DevDataService: Error clearing development data: $e");
    }
  }
}
