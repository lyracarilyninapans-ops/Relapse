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

  /// Real-time stream of activity records since [start] and before [end].
  Stream<List<ActivityRecord>> watchActivityRecords(
      String uid, String patientId, DateTime start, DateTime end) {
    return _activityCollection(uid, patientId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityRecord.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream of the latest location update record.
  /// Uses orderBy(timestamp) on the full collection and filters client-side
  /// to avoid requiring a Firestore composite index on (eventType, timestamp).
  Stream<ActivityRecord?> watchLatestLocation(String uid, String patientId) {
    return _activityCollection(uid, patientId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      // 1) Prefer most recent location_update with valid coordinates.
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final hasCoordinates = data['latitude'] != null && data['longitude'] != null;
        if (hasCoordinates &&
            data['eventType'] == ActivityEventType.locationUpdate.firestoreValue) {
          return ActivityRecord.fromJson({...data, 'id': doc.id});
        }
      }

      // 2) Fallback: most recent record with coordinates regardless of event type.
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final hasCoordinates = data['latitude'] != null && data['longitude'] != null;
        if (hasCoordinates) {
          return ActivityRecord.fromJson({...data, 'id': doc.id});
        }
      }

      // 3) No coordinate-bearing record found.
      return null;
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
  /// Fetches all records in the range and filters client-side to avoid
  /// requiring a Firestore composite index on (eventType, timestamp).
  Future<List<ActivityRecord>> getLocationHistory(
      String uid, String patientId, DateTime start, DateTime end) async {
    final snapshot = await _activityCollection(uid, patientId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: false)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => ActivityRecord.fromJson({...doc.data(), 'id': doc.id}))
        .where((record) => record.eventType == ActivityEventType.locationUpdate)
        .toList();
  }
}
