import 'package:intl/intl.dart';

/// Date/time and currency formatting helpers.
class Formatters {
  Formatters._();

  static final NumberFormat _amount = NumberFormat('#,##0.##');

  /// "Rs. 1,500" style money string.
  static String money(double value, String currency) {
    return '$currency ${_amount.format(value)}';
  }

  /// Plain formatted number without the currency symbol.
  static String number(double value) => _amount.format(value);

  /// "Today", "Yesterday" or "Aug 18, 2026".
  static String friendlyDate(DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('MMM d, y').format(date);
  }

  /// "Wednesday, Sep 10" style full date used in the header.
  static String fullDate(DateTime date) =>
      DateFormat('EEEE, MMM d').format(date);

  /// "9:41 AM"
  static String time(DateTime date) => DateFormat('h:mm a').format(date);

  /// "Sep 10, 2026 · 9:41 AM"
  static String dateAndTime(DateTime date) =>
      '${DateFormat('MMM d, y').format(date)} · ${time(date)}';

  /// Time-of-day based greeting.
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

/// Pure date helpers used for grouping and range filtering.
class DateUtilsX {
  DateUtilsX._();

  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime d) => isSameDay(d, DateTime.now());

  /// Monday 00:00 of the week containing [d].
  static DateTime startOfWeek(DateTime d) {
    final day = dayOf(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);

  static bool isInCurrentWeek(DateTime d) {
    final start = startOfWeek(DateTime.now());
    final end = start.add(const Duration(days: 7));
    return !d.isBefore(start) && d.isBefore(end);
  }

  static bool isInCurrentMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }
}
