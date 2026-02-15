import 'package:intl/intl.dart';

/// Utility functions for date operations
class DateUtils {
  // Private constructor to prevent instantiation
  DateUtils._();
  
  /// Get today's date at midnight (normalized)
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  /// Format date as 'EEEE, MMM d, yyyy' (e.g., Monday, Jan 1, 2024)
  static String formatDateLong(DateTime date) {
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }
  
  /// Format date as 'MMM d' (e.g., Jan 1)
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM d').format(date);
  }
  
  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
  
  /// Get the start of the week (Monday)
  static DateTime getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
  
  /// Get the end of the week (Sunday)
  static DateTime getEndOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }
  
  /// Check if a date is in the current week
  static bool isInCurrentWeek(DateTime date) {
    final today = DateUtils.today;
    final startOfWeek = getStartOfWeek(today);
    final endOfWeek = getEndOfWeek(today);
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }
  
  /// Get a unique string key for a date (format: yyyy-MM-dd)
  static String getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  /// Parse a date key back to DateTime
  static DateTime? parseDateKey(String key) {
    try {
      return DateFormat('yyyy-MM-dd').parse(key);
    } catch (e) {
      return null;
    }
  }
}
