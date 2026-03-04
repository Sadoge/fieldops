import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final _date = DateFormat('MMM d, y');
  static final _dateTime = DateFormat('MMM d, y • HH:mm');

  static String formatDate(DateTime dt) => _date.format(dt.toLocal());
  static String formatDateTime(DateTime dt) => _dateTime.format(dt.toLocal());

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dt);
  }

  static String relativeDeadline(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    final label = _compactDuration(diff.abs());
    return diff.isNegative ? '$label overdue' : 'due in $label';
  }

  static String _compactDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      final minutes = duration.inMinutes == 0 ? 1 : duration.inMinutes;
      return '${minutes}m';
    }
    if (duration.inHours < 24) return '${duration.inHours}h';
    if (duration.inDays < 7) return '${duration.inDays}d';
    return '${(duration.inDays / 7).ceil()}w';
  }
}
