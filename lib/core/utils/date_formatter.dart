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
}
