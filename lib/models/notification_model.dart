class NotificationModel {
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}
