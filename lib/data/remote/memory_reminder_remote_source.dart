import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/memory_reminder.dart';

/// Firestore data source for memory reminders.
class MemoryReminderRemoteSource {
  final FirebaseFirestore _firestore;

  MemoryReminderRemoteSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(
      String uid, String patientId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId)
        .collection('memoryReminders');
  }

  /// Stream of all memory reminders for a patient.
  Stream<List<MemoryReminder>> watchReminders(String uid, String patientId) {
    return _collection(uid, patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                MemoryReminder.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Fetch a single reminder.
  Future<MemoryReminder?> getReminder(
      String uid, String patientId, String reminderId) async {
    final doc = await _collection(uid, patientId).doc(reminderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MemoryReminder.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Create or update a memory reminder.
  /// If [reminder.id] is empty, Firestore auto-generates an ID.
  Future<String> saveReminder(
      String uid, String patientId, MemoryReminder reminder) async {
    if (reminder.id.isEmpty) {
      final docRef =
          await _collection(uid, patientId).add(reminder.toJson()..remove('id'));
      return docRef.id;
    } else {
      await _collection(uid, patientId)
          .doc(reminder.id)
          .set(reminder.toJson(), SetOptions(merge: true));
      return reminder.id;
    }
  }

  /// Delete a memory reminder.
  Future<void> deleteReminder(
      String uid, String patientId, String reminderId) async {
    await _collection(uid, patientId).doc(reminderId).delete();
  }
}
