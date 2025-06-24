import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifications =
        Provider.of<NotificationProvider>(context).notifications;

    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body:
          notifications.isEmpty
              ? Center(child: Text("No notifications"))
              : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return ListTile(
                    title: Text(n.title),
                    subtitle: Text(n.message),
                    trailing: Text(
                      "${n.timestamp.hour.toString().padLeft(2, '0')}:${n.timestamp.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(fontSize: 12),
                    ),
                    tileColor: n.isRead ? Colors.white : Colors.blue.shade50,
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Mark all as read",
        child: Icon(Icons.done_all),
        onPressed:
            () =>
                Provider.of<NotificationProvider>(
                  context,
                  listen: false,
                ).markAllAsRead(),
      ),
    );
  }
}
