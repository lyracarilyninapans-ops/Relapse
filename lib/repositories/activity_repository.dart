import 'package:relapse_flutter/models/activity_record.dart';
import 'package:relapse_flutter/models/daily_summary.dart';

/// Date range filter for activity queries.
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  static DateRange today() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static DateRange thisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return DateRange(
      start: DateTime(weekStart.year, weekStart.month, weekStart.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static DateRange thisMonth() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }
}

/// Abstract activity repository interface.
abstract class ActivityRepository {
  /// Real-time stream of activity records for a date range.
  Stream<List<ActivityRecord>> watchActivityFeed(
      String patientId, DateRange range);

  /// Latest location record for live tracking.
  Stream<ActivityRecord?> watchLiveLocation(String patientId);

  /// Daily summary (distance, time outside, places).
  Future<DailySummary?> getDailySummary(String patientId, DateTime date);

  /// Real-time daily summary stream.
  Stream<DailySummary?> watchDailySummary(String patientId, DateTime date);

  /// Hourly activity counts for movement chart (24 values).
  Future<List<int>> getHourlyActivity(String patientId, DateTime date);

  /// Location history for timeline view.
  Future<List<ActivityRecord>> getLocationHistory(
      String patientId, DateRange range);
}
