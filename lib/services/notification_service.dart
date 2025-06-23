// services/notification_service.dart (Android-Only Version)
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Background message handler - must be top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notifications for Android
  Future<void> initialize() async {
    print('🔔 Initializing Notification Service for Android');

    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permissions');
    } else {
      print('❌ User declined notification permissions');
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        if (details.payload != null) {
          _handleNotificationTap(details.payload);
        }
      },
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'civic_link_channel',
      'CivicLink Notifications',
      description: 'Notifications for issue updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Set foreground notification options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Received foreground message');
      _handleForegroundMessage(message);
      _saveNotificationToFirestore(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification opened app from background');
      if (message.data['issueId'] != null) {
        _handleNotificationTap(message.data['issueId']);
      }
    });

    // Check if app was opened from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data['issueId'] != null) {
      print('🔔 App opened from terminated state via notification');
      _handleNotificationTap(initialMessage.data['issueId']);
    }

    // Get and save FCM token
    await _saveToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateToken);
  }

  // Save FCM token to Firestore
  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print('🔔 FCM Token: $token');

        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
            'platform': 'android',
          });
        }
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // Update token on refresh
  Future<void> _updateToken(String token) async {
    print('🔔 FCM Token refreshed');
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'CivicLink',
        body: notification.body ?? 'You have a new notification',
        payload: message.data['issueId'],
        imageUrl: android?.imageUrl,
      );
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      'civic_link_channel',
      'CivicLink Notifications',
      channelDescription: 'Notifications for issue updates',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(body),
      // Add image if available
      largeIcon: imageUrl != null ? FilePathAndroidBitmap(imageUrl) : null,
      // Custom color
      color: const Color(0xFF2196F3),
      // Auto cancel when tapped
      autoCancel: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  // Handle notification tap
  void _handleNotificationTap(String? issueId) {
    if (issueId != null) {
      // This will be handled by the app's navigation
      // You'll need to implement navigation from your main app
      print('🔔 Navigate to issue: $issueId');
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('notifications').add({
          'userId': user.uid,
          'title': message.notification?.title ?? 'Notification',
          'body': message.notification?.body ?? '',
          'data': message.data,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': 'android',
        });
      }
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  // Get user notifications from Firestore
  Stream<List<NotificationModel>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to last 50 notifications
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get unread notification count
  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final unreadDocs =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .where('read', isEqualTo: false)
            .get();

    for (final doc in unreadDocs.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final userNotifications =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .get();

    for (final doc in userNotifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

// Notification Model
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: data['data'] ?? {},
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }
}
