import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/safe_zone.dart';

/// Firestore data source for safe zone configuration.
class SafeZoneRemoteSource {
  final FirebaseFirestore _firestore;

  SafeZoneRemoteSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _safeZoneCollection(
      String uid, String patientId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('safeZones');
  }

  /// Stream of all active safe zones for a patient.
  Stream<List<SafeZone>> watchSafeZones(String uid, String patientId) {
    return _safeZoneCollection(uid, patientId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SafeZone.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Fetch all safe zones for a patient.
  Future<List<SafeZone>> getSafeZones(String uid, String patientId) async {
    final snapshot = await _safeZoneCollection(uid, patientId).get();
    return snapshot.docs
        .map((doc) => SafeZone.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Create or update a safe zone.
  Future<void> saveSafeZone(
      String uid, String patientId, SafeZone safeZone) async {
    await _safeZoneCollection(uid, patientId)
        .doc(safeZone.id)
        .set(safeZone.toJson(), SetOptions(merge: true));
  }

  /// Delete a safe zone.
  Future<void> deleteSafeZone(
      String uid, String patientId, String zoneId) async {
    await _safeZoneCollection(uid, patientId).doc(zoneId).delete();
  }
}
