// helpers/notification_helpers.dart
// Add these helper functions to trigger notifications for different events

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationHelpers {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send notification when issue is created
  static Future<void> sendIssueCreatedNotification({
    required String issueId,
    required String issueTitle,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': _auth.currentUser?.uid,
        'title': 'Issue Reported Successfully',
        'body':
            'Your issue "$issueTitle" has been submitted and will be reviewed soon.',
        'data': {'issueId': issueId, 'type': 'issue_created'},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send notification when issue status changes
  static Future<void> sendStatusUpdateNotification({
    required String userId,
    required String issueId,
    required String issueTitle,
    required String newStatus,
    String? adminNotes,
  }) async {
    try {
      String body;
      switch (newStatus.toLowerCase()) {
        case 'in_progress':
          body = 'Your issue "$issueTitle" is now being worked on.';
          break;
        case 'resolved':
          body = 'Good news! Your issue "$issueTitle" has been resolved.';
          break;
        case 'rejected':
          body =
              'Your issue "$issueTitle" has been rejected. ${adminNotes != null ? "Reason: $adminNotes" : ""}';
          break;
        default:
          body =
              'Your issue "$issueTitle" status has been updated to $newStatus.';
      }

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Issue Status Update',
        'body': body,
        'data': {
          'issueId': issueId,
          'type': 'status_update',
          'newStatus': newStatus,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send notification when admin adds a note
  static Future<void> sendAdminNoteNotification({
    required String userId,
    required String issueId,
    required String issueTitle,
    required String adminNote,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Admin Response',
        'body':
            'An administrator has added a note to your issue "$issueTitle".',
        'data': {'issueId': issueId, 'type': 'admin_note', 'note': adminNote},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send notification for nearby issues (for future feature)
  static Future<void> sendNearbyIssueNotification({
    required String userId,
    required String issueId,
    required String issueTitle,
    required String category,
    required double distance,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Issue Reported Near You',
        'body':
            'A $category issue "$issueTitle" was reported ${distance.toStringAsFixed(1)}km from your location.',
        'data': {
          'issueId': issueId,
          'type': 'nearby_issue',
          'distance': distance,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}

// Update your issue_service.dart to trigger notifications
// Add this to the submitIssue method after successfully creating the issue:

// In issue_service.dart, after creating the issue:
/*
// Send notification
await NotificationHelpers.sendIssueCreatedNotification(
  issueId: docRef.id,
  issueTitle: title,
);
*/
