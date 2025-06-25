// services/notification_service.dart
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notification service
  Future<void> initialize() async {
    print("🔔 NotificationService: Initializing...");

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize FCM
      await _initializeFCM();

      // Save FCM token to Firestore
      await _saveFCMToken();

      print("✅ NotificationService: Initialized successfully");
    } catch (e) {
      print("❌ NotificationService: Initialization failed: $e");
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    // Request local notification permissions
    if (Platform.isAndroid) {
      final androidImplementation =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.requestNotificationsPermission();
        print("🔔 Android notification permission granted: $granted");
      }
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Save FCM token to user document
  Future<void> _saveFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print("✅ FCM Token saved: ${token.substring(0, 20)}...");
      }
    } catch (e) {
      print("❌ Error saving FCM token: $e");
    }
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Save notification to Firestore
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        body: body,
        data: data ?? {},
        imageUrl: imageUrl,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toMap());

      print("✅ Notification sent to user: $userId");
    } catch (e) {
      print("❌ Error sending notification: $e");
    }
  }

  // Send notification about issue update
  Future<void> sendIssueUpdateNotification({
    required String userId,
    required String issueId,
    required String issueTitle,
    required String newStatus,
    String? adminNotes,
  }) async {
    String title;
    String body;

    switch (newStatus.toLowerCase()) {
      case 'in_progress':
        title = '🔧 Issue Update: In Progress';
        body = 'Your issue "$issueTitle" is now being worked on!';
        break;
      case 'resolved':
        title = '✅ Issue Resolved!';
        body = 'Great news! Your issue "$issueTitle" has been resolved.';
        break;
      case 'rejected':
        title = '❌ Issue Update: Not Approved';
        body = 'Your issue "$issueTitle" could not be processed.';
        break;
      default:
        title = '📢 Issue Update';
        body = 'Your issue "$issueTitle" status has been updated.';
    }

    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: {
        'type': 'issue_update',
        'issueId': issueId,
        'newStatus': newStatus,
        'adminNotes': adminNotes ?? '',
      },
    );
  }

  // Send welcome notification
  Future<void> sendWelcomeNotification(String userId) async {
    await sendNotificationToUser(
      userId: userId,
      title: '🎉 Welcome to CivicLink!',
      body: 'Start reporting community issues and make a difference!',
      data: {'type': 'welcome'},
    );
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    print("📱 Foreground message: ${message.notification?.title}");

    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'CivicLink',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print("👆 Notification tapped: ${message.data}");
    // Navigate to appropriate screen based on notification type
    _navigateBasedOnNotification(message.data);
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'civic_link_channel',
      'CivicLink Notifications',
      channelDescription: 'Notifications for CivicLink app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFF2563EB), // Your app's primary color
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print("👆 Local notification tapped: ${response.payload}");
    // Parse payload and navigate
    if (response.payload != null) {
      // Navigate based on payload
    }
  }

  // Navigate based on notification data
  void _navigateBasedOnNotification(Map<String, dynamic> data) {
    // This will be implemented in the UI layer
    // For now, just print the data
    print("🧭 Navigate to: ${data['type']}");
  }

  // Get user notifications stream
  Stream<List<NotificationModel>> getUserNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Error marking notification as read: $e");
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print("✅ All notifications marked as read");
    } catch (e) {
      print("❌ Error marking all notifications as read: $e");
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print("❌ Error deleting notification: $e");
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .where('isRead', isEqualTo: false)
              .count()
              .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print("❌ Error getting unread count: $e");
      return 0;
    }
  }

  // Subscribe to topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print("✅ Subscribed to topic: $topic");
    } catch (e) {
      print("❌ Error subscribing to topic: $e");
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      print("✅ Unsubscribed from topic: $topic");
    } catch (e) {
      print("❌ Error unsubscribing from topic: $e");
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences({
    required bool pushNotifications,
    required bool issueUpdates,
    required bool systemUpdates,
    required bool emailNotifications,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'notificationPreferences': {
          'pushNotifications': pushNotifications,
          'issueUpdates': issueUpdates,
          'systemUpdates': systemUpdates,
          'emailNotifications': emailNotifications,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });

      // Subscribe/unsubscribe from topics based on preferences
      if (systemUpdates) {
        await subscribeToTopic('system_updates');
      } else {
        await unsubscribeFromTopic('system_updates');
      }

      print("✅ Notification preferences updated");
    } catch (e) {
      print("❌ Error updating notification preferences: $e");
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📱 Background message: ${message.notification?.title}");
  // Handle background message
}
