import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/daily_summary.dart';

/// Firestore data source for daily summaries.
class DailySummaryRemoteSource {
  final FirebaseFirestore _firestore;

  DailySummaryRemoteSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _summaryDoc(
      String uid, String patientId, String dateKey) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('dailySummaries')
        .doc(dateKey);
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Fetch daily summary for a specific date.
  Future<DailySummary?> getDailySummary(
      String uid, String patientId, DateTime date) async {
    final doc = await _summaryDoc(uid, patientId, _dateKey(date)).get();
    if (!doc.exists || doc.data() == null) return null;
    return DailySummary.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Real-time stream of daily summary updates.
  Stream<DailySummary?> watchDailySummary(
      String uid, String patientId, DateTime date) {
    return _summaryDoc(uid, patientId, _dateKey(date))
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DailySummary.fromJson({...doc.data()!, 'id': doc.id});
    });
  }
}
