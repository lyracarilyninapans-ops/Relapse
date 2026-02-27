import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/pairing_info.dart';
import 'package:relapse_flutter/models/watch_status.dart';

/// Firestore data source for watch pairing and status.
class WatchRemoteSource {
  final FirebaseFirestore _firestore;

  WatchRemoteSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _pairingDoc(String uid) {
    return _firestore.collection('users').doc(uid).collection('watchPairing').doc('current');
  }

  DocumentReference<Map<String, dynamic>> _watchStatusDoc(
      String uid, String patientId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('watchStatus')
        .doc('current');
  }

  /// Write a new pairing code to Firestore.
  Future<void> createPairingCode(String uid, String pairingCode) async {
    await _pairingDoc(uid).set(
      PairingInfo(
        pairingCode: pairingCode,
        status: PairingStatus.pending,
      ).toJson(),
    );
  }

  /// Real-time stream of pairing info changes.
  Stream<PairingInfo?> watchPairingInfo(String uid) {
    return _pairingDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PairingInfo.fromJson(doc.data()!);
    });
  }

  /// Get current pairing info.
  Future<PairingInfo?> getPairingInfo(String uid) async {
    final doc = await _pairingDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return PairingInfo.fromJson(doc.data()!);
  }

  /// Update pairing status to unpaired and clear watch ID.
  Future<void> unpairWatch(String uid) async {
    await _pairingDoc(uid).set({
      'pairingCode': '',
      'watchId': null,
      'pairedAt': null,
      'status': PairingStatus.unpaired.name,
    });
  }

  /// Real-time stream of watch status updates.
  Stream<WatchStatus?> watchWatchStatus(String uid, String patientId) {
    return _watchStatusDoc(uid, patientId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return WatchStatus.fromJson(doc.data()!);
    });
  }

  /// Get current watch status.
  Future<WatchStatus?> getWatchStatus(String uid, String patientId) async {
    final doc = await _watchStatusDoc(uid, patientId).get();
    if (!doc.exists || doc.data() == null) return null;
    return WatchStatus.fromJson(doc.data()!);
  }
}
