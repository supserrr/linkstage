import '../../domain/entities/event_entity.dart';

/// Utilities for event date comparisons (upcoming vs past).
abstract final class EventDateUtils {
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// True if the event is upcoming: not completed, and date is today or later
  /// (or null, for drafts without a date).
  static bool isUpcomingEvent(EventEntity e) {
    if (e.status == EventStatus.completed) return false;
    if (e.date == null) return true;
    final eventDay = DateTime(e.date!.year, e.date!.month, e.date!.day);
    return eventDay.isAfter(_today) || _isSameDay(eventDay, _today);
  }

  /// True if the event is past: completed, or date is before today.
  static bool isPastEvent(EventEntity e) {
    if (e.status == EventStatus.completed) return true;
    if (e.date == null) return false;
    final eventDay = DateTime(e.date!.year, e.date!.month, e.date!.day);
    return eventDay.isBefore(_today);
  }
}
