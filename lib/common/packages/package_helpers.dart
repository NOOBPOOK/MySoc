import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';

// Backend: Formats Timestamp to a human-readable date/time string
String formatHumanFriendlyDate(Timestamp? timestamp) {
  logger.d('formatHumanFriendlyDate started with timestamp: $timestamp');
  if (timestamp == null) {
    logger.d('formatHumanFriendlyDate completed (null timestamp)');
    return 'Unknown Date';
  }
  final date = timestamp.toDate();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final packageDate = DateTime(date.year, date.month, date.day);

  String datePart;
  if (packageDate == today) {
    datePart = 'Today';
  } else if (packageDate == yesterday) {
    datePart = 'Yesterday';
  } else {
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
      'Dec'
    ];
    datePart = "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  final hour =
      date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
  final period = date.hour >= 12 ? 'PM' : 'AM';
  final minuteStr = date.minute.toString().padLeft(2, '0');
  final timePart = "$hour:$minuteStr $period";

  final formatted = "$datePart at $timePart";
  logger.d('formatHumanFriendlyDate completed returning: $formatted');
  return formatted;
}
