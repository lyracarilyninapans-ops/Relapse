import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/safe_zone_event.dart';

/// Firestore data source for safe zone events (enter/exit logs).
class SafeZoneEventRemoteSource {
  final FirebaseFirestore _firestore;

  SafeZoneEventRemoteSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _eventCollection(
      String uid, String patientId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('safeZoneEvents');
  }

  /// Stream of recent safe zone events, newest first.
  Stream<List<SafeZoneEvent>> watchRecentEvents(
      String uid, String patientId, {int limit = 20}) {
    return _eventCollection(uid, patientId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SafeZoneEvent.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Fetch safe zone events for a date range.
  Future<List<SafeZoneEvent>> getEvents(
      String uid, String patientId, DateTime start, DateTime end) async {
    final snapshot = await _eventCollection(uid, patientId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map(
            (doc) => SafeZoneEvent.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }
}
