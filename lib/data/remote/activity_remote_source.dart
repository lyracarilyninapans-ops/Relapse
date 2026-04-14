import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/activity_record.dart';

/// Firestore data source for activity records.
class ActivityRemoteSource {
  final FirebaseFirestore _firestore;
  final bool _useOptimizedLatestLocationQuery;

  ActivityRemoteSource({
    FirebaseFirestore? firestore,
    bool useOptimizedLatestLocationQuery = true,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _useOptimizedLatestLocationQuery = useOptimizedLatestLocationQuery;

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
  /// Uses a server-side eventType filter to reduce reads.
  /// Keep legacy query path available as a fallback during rollout.
  Stream<ActivityRecord?> watchLatestLocation(String uid, String patientId) {
    if (!_useOptimizedLatestLocationQuery) {
      return _watchLatestLocationLegacy(uid, patientId);
    }

    return Stream<ActivityRecord?>.multi((controller) {
      StreamSubscription<ActivityRecord?>? subscription;

      void listenLegacy() {
        subscription?.cancel();
        subscription = _watchLatestLocationLegacy(uid, patientId).listen(
          controller.add,
          onError: controller.addError,
        );
      }

      subscription = _watchLatestLocationOptimized(uid, patientId).listen(
        controller.add,
        onError: (Object error, StackTrace stackTrace) {
          if (_isMissingIndexError(error)) {
            listenLegacy();
            return;
          }
          controller.addError(error, stackTrace);
        },
      );

      controller.onCancel = () async {
        await subscription?.cancel();
      };
    });
  }

  Stream<ActivityRecord?> _watchLatestLocationOptimized(
    String uid,
    String patientId,
  ) {
    return _activityCollection(uid, patientId)
        .where(
          'eventType',
          isEqualTo: ActivityEventType.locationUpdate.firestoreValue,
        )
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      final data = doc.data();
      final hasCoordinates =
          data['latitude'] != null && data['longitude'] != null;
      if (!hasCoordinates) return null;
      return ActivityRecord.fromJson({...data, 'id': doc.id});
    });
  }

  Stream<ActivityRecord?> _watchLatestLocationLegacy(
    String uid,
    String patientId,
  ) {
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

  bool _isMissingIndexError(Object error) {
    if (error is! FirebaseException) return false;
    if (error.code != 'failed-precondition') return false;
    final message = (error.message ?? '').toLowerCase();
    return message.contains('index');
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
