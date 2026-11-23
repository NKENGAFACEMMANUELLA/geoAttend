import 'package:intl/intl.dart';

class Fmt {
  Fmt._();
  static String time(DateTime? d) => d == null ? '--' : DateFormat('hh:mm a').format(d);
  static String dateShort(DateTime d) => DateFormat('MMM d').format(d);
  static String dateLong(DateTime d) => DateFormat('MMM d, yyyy').format(d);
  static String dateFull(DateTime d) => DateFormat('EEEE, MMM d, yyyy').format(d);
  static String dateTime(DateTime d) => DateFormat('MMM d, yyyy  hh:mm a').format(d);
  static String duration(Duration d) => '${d.inHours}h ${d.inMinutes % 60}m';

  static String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static DateTime atTime(DateTime date, int hour, int minute) =>
      DateTime(date.year, date.month, date.day, hour, minute);
}
