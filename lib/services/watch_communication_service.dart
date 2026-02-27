import 'dart:math';

import 'package:relapse_flutter/data/remote/patient_remote_source.dart';
import 'package:relapse_flutter/data/remote/watch_remote_source.dart';
import 'package:relapse_flutter/models/pairing_info.dart';
import 'package:relapse_flutter/models/patient.dart';
import 'package:relapse_flutter/models/watch_status.dart';

/// Service managing watch pairing flow and status monitoring.
///
/// Operates through Firestore — the watch writes its status and pairing
/// responses there, and this service listens for changes.
abstract class WatchCommunicationService {
  /// Generate a pairing code and write it to Firestore.
  Future<String> generatePairingCode(String uid);

  /// Stream pairing info to detect when the watch pairs.
  Stream<PairingInfo?> watchPairingStatus(String uid);

  /// Complete pairing by creating the patient record.
  Future<Patient> completePairing({
    required String uid,
    required String name,
    int? age,
    String? notes,
    required String watchId,
  });

  /// Unpair the watch and clean up.
  Future<void> unpairWatch(String uid);

  /// Stream watch connectivity and battery status.
  Stream<WatchStatus?> watchStatus(String uid, String patientId);
}

class FirebaseWatchCommunicationService implements WatchCommunicationService {
  final WatchRemoteSource _watchSource;
  final PatientRemoteSource _patientSource;

  FirebaseWatchCommunicationService({
    required WatchRemoteSource watchSource,
    required PatientRemoteSource patientSource,
  })  : _watchSource = watchSource,
        _patientSource = patientSource;

  @override
  Future<String> generatePairingCode(String uid) async {
    final code = _generateCode();
    await _watchSource.createPairingCode(uid, code);
    return code;
  }

  @override
  Stream<PairingInfo?> watchPairingStatus(String uid) {
    return _watchSource.watchPairingInfo(uid);
  }

  @override
  Future<Patient> completePairing({
    required String uid,
    required String name,
    int? age,
    String? notes,
    required String watchId,
  }) async {
    final patient = Patient(
      id: '', // will be set by Firestore
      caregiverUid: uid,
      name: name,
      age: age,
      notes: notes,
      pairedWatchId: watchId,
      createdAt: DateTime.now(),
    );
    await _patientSource.savePatient(uid, patient);
    return patient;
  }

  @override
  Future<void> unpairWatch(String uid) async {
    await _watchSource.unpairWatch(uid);
  }

  @override
  Stream<WatchStatus?> watchStatus(String uid, String patientId) {
    return _watchSource.watchWatchStatus(uid, patientId);
  }

  /// Generate a random 6-digit numeric pairing code.
  String _generateCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }
}
