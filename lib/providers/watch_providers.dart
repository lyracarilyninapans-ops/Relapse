import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/data/remote/watch_remote_source.dart';
import 'package:relapse_flutter/models/pairing_info.dart';
import 'package:relapse_flutter/models/watch_status.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/services/watch_communication_service.dart';

// ─── Remote Source ───────────────────────────────────────────────────────

final watchRemoteSourceProvider = Provider<WatchRemoteSource>((ref) {
  return WatchRemoteSource();
});

// ─── Service ─────────────────────────────────────────────────────────────

final watchServiceProvider = Provider<WatchCommunicationService>((ref) {
  return FirebaseWatchCommunicationService(
    watchSource: ref.watch(watchRemoteSourceProvider),
    patientSource: ref.watch(patientRemoteSourceProvider),
  );
});

// ─── Pairing ─────────────────────────────────────────────────────────────

/// Stream of pairing info for the current user.
final pairingInfoProvider = StreamProvider<PairingInfo?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return ref.watch(watchServiceProvider).watchPairingStatus(authUser.uid);
});

/// Whether a watch is currently paired.
final isPairedProvider = Provider<bool>((ref) {
  final pairing = ref.watch(pairingInfoProvider).valueOrNull;
  return pairing?.status == PairingStatus.paired;
});

// ─── Watch Status ────────────────────────────────────────────────────────

/// Real-time watch status for the selected patient's paired watch.
final watchStatusProvider = StreamProvider<WatchStatus?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final patientId = ref.watch(selectedPatientIdProvider);
  if (authUser == null || patientId == null) return const Stream.empty();
  return ref
      .watch(watchServiceProvider)
      .watchStatus(authUser.uid, patientId);
});

/// Whether the watch is currently connected.
final watchConnectedProvider = Provider<bool>((ref) {
  final status = ref.watch(watchStatusProvider).valueOrNull;
  return status?.isConnected ?? false;
});

/// Watch battery level (null if unknown).
final watchBatteryProvider = Provider<int?>((ref) {
  final status = ref.watch(watchStatusProvider).valueOrNull;
  return status?.batteryLevel;
});
