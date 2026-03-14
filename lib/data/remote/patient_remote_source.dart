import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/patient.dart';

/// Firestore data source for patient data.
class PatientRemoteSource {
  final FirebaseFirestore _firestore;

  PatientRemoteSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _patientCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('patients');
  }

  /// Stream of all patients for a user.
  Stream<List<Patient>> watchPatients(String uid) {
    return _patientCollection(uid).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Patient.fromJson({...doc.data(), 'id': doc.id}))
        .toList());
  }

  /// Fetch a single patient.
  Future<Patient?> getPatient(String uid, String patientId) async {
    final doc = await _patientCollection(uid).doc(patientId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Patient.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Create or update a patient. Returns the document ID.
  Future<String> savePatient(String uid, Patient patient) async {
    if (patient.id.isEmpty) {
      // Auto-generate a Firestore document ID for new patients.
      final docRef = await _patientCollection(uid).add(patient.toJson());
      return docRef.id;
    } else {
      await _patientCollection(uid)
          .doc(patient.id)
          .set(patient.toJson(), SetOptions(merge: true));
      return patient.id;
    }
  }

  /// Delete a patient.
  Future<void> deletePatient(String uid, String patientId) async {
    await _patientCollection(uid).doc(patientId).delete();
  }

  /// Clear the paired watch ID from a patient record.
  Future<void> clearPairedWatch(String uid, String patientId) async {
    await _patientCollection(uid).doc(patientId).update({
      'pairedWatchId': FieldValue.delete(),
    });
  }

  /// Update reminder cooldown setting used by watch reminder trigger logic.
  Future<void> setReminderCooldownMinutes(
      String uid, String patientId, int minutes) async {
    await _patientCollection(uid).doc(patientId).set({
      'settings': {
        'reminderCooldownMinutes': minutes,
      }
    }, SetOptions(merge: true));
  }
}
