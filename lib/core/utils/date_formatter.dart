import 'package:intl/intl.dart';

/// Utility class for formatting dates and times in chat context
class DateFormatter {
  DateFormatter._();

  /// Formats a timestamp for chat list (e.g. "2:30 PM", "Yesterday", "Mon", "12/25/24")
  static String formatChatListTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEE').format(dateTime); // Mon, Tue, etc.
    } else {
      return DateFormat('M/d/yy').format(dateTime);
    }
  }

  /// Formats a timestamp for message bubble (e.g. "2:30 PM")
  static String formatMessageTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Formats a timestamp for message group header (e.g. "Today", "Yesterday", "Monday, Dec 25")
  static String formatMessageGroupHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else if (dateTime.year == now.year) {
      return DateFormat('MMMM d').format(dateTime);
    } else {
      return DateFormat('MMMM d, yyyy').format(dateTime);
    }
  }

  /// Formats "last seen" text (e.g. "last seen today at 2:30 PM")
  static String formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final time = DateFormat('h:mm a').format(dateTime);

    if (messageDate == today) {
      return 'last seen today at $time';
    } else if (messageDate == yesterday) {
      return 'last seen yesterday at $time';
    } else {
      final date = DateFormat('M/d/yy').format(dateTime);
      return 'last seen $date at $time';
    }
  }

  /// Formats voice note duration (e.g. "1:23")
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
