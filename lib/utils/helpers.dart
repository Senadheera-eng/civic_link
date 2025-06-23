import 'package:civic_link/utils/constants.dart';
import 'package:flutter/material.dart';

class Helpers {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  static String formatDate(DateTime date) {
    // Simple date formatting without intl package
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  static String formatDateTime(DateTime dateTime) {
    final timeStr = _formatTime(dateTime);
    return '${formatDate(dateTime)} $timeStr';
  }

  static String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    return '$hour:$minute $period';
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusPending:
        return AppColors.statusPending;
      case AppConstants.statusInProgress:
        return AppColors.statusInProgress;
      case AppConstants.statusResolved:
        return AppColors.statusResolved;
      case AppConstants.statusRejected:
        return AppColors.statusRejected;
      default:
        return AppColors.textSecondary;
    }
  }

  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusInProgress:
        return 'In Progress';
      case AppConstants.statusResolved:
        return 'Resolved';
      case AppConstants.statusRejected:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }
}
