import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  /// Formats a DateTime to a readable string like "Mar 12, 2026"
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Formats a DateTime to time string like "09:00 AM"
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('hh:mm a').format(date);
  }

  /// Formats a DateTime to readable string like "Mar 12, 09:00 AM"
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, hh:mm a').format(date);
  }

  /// Returns a relative time string like "2 hours ago", "3 days ago"
  static String timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  /// Returns the number of days until a due date
  static String daysUntilDue(DateTime? dueDate) {
    if (dueDate == null) return '';
    final diff = dueDate.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays == 0) return 'Due Today';
    if (diff.inDays == 1) return 'Due Tomorrow';
    return 'In ${diff.inDays} Days';
  }

  /// Returns initials from a name (e.g., "John Doe" -> "JD")
  static String getInitials(String? name) {
    if (name == null || name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
