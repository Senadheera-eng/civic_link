// services/notification_service.dart
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

// Background message handler - must be top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // You can process the message here if needed
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

  // Initialize notifications
  Future<void> initialize() async {
    print('🔔 Initializing Notification Service');

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure FCM
    await _configureFCM();

    // Get and save FCM token
    await _getAndSaveToken();
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    print('🔔 Permission status: ${settings.authorizationStatus}');
  }

  // Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization
    final iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS foreground notification
      },
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        _handleNotificationTap(details.payload);
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'civic_link_channel',
        'CivicLink Notifications',
        description: 'Notifications for issue updates',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  // Configure FCM
  Future<void> _configureFCM() async {
    // Set foreground notification presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
      _saveNotificationToFirestore(message);
    });

    // Message opened app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Message opened app: ${message.messageId}');
      _handleNotificationTap(message.data['issueId']);
    });

    // Check if app was opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🔔 App opened from terminated state');
      _handleNotificationTap(initialMessage.data['issueId']);
    }
  }

  // Get and save FCM token
  Future<void> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      print('🔔 FCM Token: $token');

      if (token != null) {
        final user = _auth.currentUser;
        if (user != null) {
          // Save token to user document
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
        }
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        print('🔔 FCM Token refreshed: $newToken');
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': newToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'CivicLink',
        body: notification.body ?? 'You have a new notification',
        payload: data['issueId'],
      );
    }
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
      channelDescription: 'Notifications for issue updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Handle notification tap
  void _handleNotificationTap(String? issueId) {
    if (issueId != null) {
      // Navigate to issue detail screen
      // You'll need to implement navigation from your main app
      print('🔔 Navigate to issue: $issueId');
    }
  }

  // Save notification to Firestore for history
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
        });
      }
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  // Get user notifications
  Stream<List<NotificationModel>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        final unreadNotifications =
            await _firestore
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .where('read', isEqualTo: false)
                .get();

        for (final doc in unreadNotifications.docs) {
          batch.update(doc.reference, {
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
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

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  // Subscribe to topic (for group notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('🔔 Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('🔔 Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
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
