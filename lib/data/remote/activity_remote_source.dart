import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/activity_record.dart';

/// Firestore data source for activity records.
class ActivityRemoteSource {
  final FirebaseFirestore _firestore;

  ActivityRemoteSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _activityCollection(
      String uid, String patientId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('activityRecords');
  }

  /// Real-time stream of activity records since [since].
  Stream<List<ActivityRecord>> watchActivityRecords(
      String uid, String patientId, DateTime since) {
    return _activityCollection(uid, patientId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityRecord.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream of the latest location update record.
  Stream<ActivityRecord?> watchLatestLocation(String uid, String patientId) {
    return _activityCollection(uid, patientId)
        .where('eventType', isEqualTo: ActivityEventType.locationUpdate.name)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return ActivityRecord.fromJson({...doc.data(), 'id': doc.id});
    });
  }

  /// Fetch activity records for a date range.
  Future<List<ActivityRecord>> getActivityRecords(
      String uid, String patientId, DateTime start, DateTime end) async {
    final snapshot = await _activityCollection(uid, patientId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ActivityRecord.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Fetch location-type records for a date range.
  Future<List<ActivityRecord>> getLocationHistory(
      String uid, String patientId, DateTime start, DateTime end) async {
    final snapshot = await _activityCollection(uid, patientId)
        .where('eventType', isEqualTo: ActivityEventType.locationUpdate.name)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ActivityRecord.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }
}
