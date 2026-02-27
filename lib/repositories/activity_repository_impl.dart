import 'package:relapse_flutter/data/remote/activity_remote_source.dart';
import 'package:relapse_flutter/data/remote/daily_summary_remote_source.dart';
import 'package:relapse_flutter/models/activity_record.dart';
import 'package:relapse_flutter/models/daily_summary.dart';
import 'package:relapse_flutter/repositories/activity_repository.dart';

/// Firestore-backed implementation of [ActivityRepository].
///
/// Requires the authenticated user's UID to scope queries.
class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteSource _activitySource;
  final DailySummaryRemoteSource _summarySource;
  final String _uid;

  ActivityRepositoryImpl({
    required ActivityRemoteSource activitySource,
    required DailySummaryRemoteSource summarySource,
    required String uid,
  })  : _activitySource = activitySource,
        _summarySource = summarySource,
        _uid = uid;

  @override
  Stream<List<ActivityRecord>> watchActivityFeed(
      String patientId, DateRange range) {
    return _activitySource.watchActivityRecords(
        _uid, patientId, range.start);
  }

  @override
  Stream<ActivityRecord?> watchLiveLocation(String patientId) {
    return _activitySource.watchLatestLocation(_uid, patientId);
  }

  @override
  Future<DailySummary?> getDailySummary(String patientId, DateTime date) {
    return _summarySource.getDailySummary(_uid, patientId, date);
  }

  @override
  Stream<DailySummary?> watchDailySummary(String patientId, DateTime date) {
    return _summarySource.watchDailySummary(_uid, patientId, date);
  }

  @override
  Future<List<int>> getHourlyActivity(String patientId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final records = await _activitySource.getActivityRecords(
        _uid, patientId, start, end);

    // Group by hour and count
    final hourlyCounts = List<int>.filled(24, 0);
    for (final record in records) {
      hourlyCounts[record.timestamp.hour]++;
    }
    return hourlyCounts;
  }

  @override
  Future<List<ActivityRecord>> getLocationHistory(
      String patientId, DateRange range) {
    return _activitySource.getLocationHistory(
        _uid, patientId, range.start, range.end);
  }
}
