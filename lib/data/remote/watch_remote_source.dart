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

  DocumentReference<Map<String, dynamic>> _patientDoc(
      String uid, String patientId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId);
  }

  /// Look up a pairing code created by the watch in `watchPairingCodes/{code}`
  /// and claim it for this caregiver. Returns the watchId on success.
  Future<String> claimPairingCode(String uid, String code) async {
    final docRef =
        _firestore.collection('watchPairingCodes').doc(code);
    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Invalid pairing code');
    }
    final data = doc.data()!;
    if (data['status'] != 'pending') {
      throw Exception('Pairing code already used');
    }
    final watchId = data['watchId'] as String? ?? '';

    // Claim the code: mark it as claimed (not yet fully paired).
    // The watch should treat 'claimed' as "in-progress" — full pairing
    // happens after the caregiver finishes patient profile setup.
    await docRef.update({
      'caregiverUid': uid,
      'status': 'claimed',
      'claimedAt': FieldValue.serverTimestamp(),
    });

    // Also persist the pairing in the caregiver's own document
    // with 'pending' status; it becomes 'paired' after patient profile setup.
    await _pairingDoc(uid).set(
      PairingInfo(
        pairingCode: code,
        watchId: watchId,
        pairedAt: DateTime.now(),
        status: PairingStatus.pending,
      ).toJson(),
    );

    return watchId;
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
  /// Also marks the global watchPairingCodes doc as unpaired so the watch
  /// can detect the change via its Firestore listener.
  Future<void> unpairWatch(String uid) async {
    // 1. Read the current pairing code before we overwrite the doc.
    final pairingDoc = await _pairingDoc(uid).get();
    final pairingCode = pairingDoc.data()?['pairingCode'] as String? ?? '';

    // 2. Clear the caregiver's pairing document.
    await _pairingDoc(uid).set({
      'pairingCode': '',
      'watchId': null,
      'pairedAt': null,
      'status': PairingStatus.unpaired.name,
    });

    // 3. Also update the global pairing-code document so the watch detects it.
    if (pairingCode.isNotEmpty) {
      try {
        await _firestore
            .collection('watchPairingCodes')
            .doc(pairingCode)
            .update({'status': 'unpaired'});
      } catch (_) {
        // Code doc may already be deleted by the watch — ignore.
      }
    }
  }

  /// Finalize pairing — set both the caregiver's local pairing doc
  /// AND the global watchPairingCodes doc to 'paired'.
  /// Also writes [patientName] and [patientId] so the watch can use them.
  Future<void> finalizePairing(String uid, {required String patientName, required String patientId}) async {
    // 1. Update the caregiver's own pairing document.
    final pairingDoc = await _pairingDoc(uid).get();
    final pairingCode = pairingDoc.data()?['pairingCode'] as String? ?? '';

    await _pairingDoc(uid).update({
      'status': PairingStatus.paired.name,
      'pairedAt': FieldValue.serverTimestamp(),
    });

    // 2. Update the global pairing-code document so the watch sees 'paired'
    //    and also include the patient name & ID for the watch to use.
    if (pairingCode.isNotEmpty) {
      await _firestore.collection('watchPairingCodes').doc(pairingCode).update({
        'status': 'paired',
        'pairedAt': FieldValue.serverTimestamp(),
        'patientName': patientName,
        'patientId': patientId,
      });
    }
  }

  /// Real-time stream of watch status updates.
  /// The watch writes `watchStatus` as a map field on the patient document.
  Stream<WatchStatus?> watchWatchStatus(String uid, String patientId) {
    return _patientDoc(uid, patientId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      final statusMap = data['watchStatus'] as Map<String, dynamic>?;
      if (statusMap == null) return null;
      return WatchStatus.fromJson(statusMap);
    });
  }

  /// Push updated patient info to the watchPairingCodes document
  /// so the watch can pick up name / ID changes in real time.
  Future<void> updatePatientInfo(String uid, {required String patientName, String? patientId}) async {
    final pairingDoc = await _pairingDoc(uid).get();
    final pairingCode = pairingDoc.data()?['pairingCode'] as String? ?? '';
    if (pairingCode.isEmpty) return;

    final updateData = <String, dynamic>{'patientName': patientName};
    if (patientId != null) updateData['patientId'] = patientId;

    await _firestore.collection('watchPairingCodes').doc(pairingCode).update(updateData);
  }

  /// Get current watch status.
  Future<WatchStatus?> getWatchStatus(String uid, String patientId) async {
    final doc = await _patientDoc(uid, patientId).get();
    if (!doc.exists || doc.data() == null) return null;
    final statusMap = doc.data()!['watchStatus'] as Map<String, dynamic>?;
    if (statusMap == null) return null;
    return WatchStatus.fromJson(statusMap);
  }
}
