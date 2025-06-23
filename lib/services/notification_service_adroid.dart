import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future initialize() async {
    // Request permissions
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Initialize local notifications for Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      'civic_link_channel',
      'CivicLink Notifications',
      description: 'Notifications for issue updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  Future _showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'civic_link_channel',
      'CivicLink Notifications',
      channelDescription: 'Notifications for issue updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'CivicLink',
      message.notification?.body ?? 'You have a new notification',
      details,
      payload: message.data['issueId'],
    );
  }
}
