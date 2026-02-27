import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/data/remote/safe_zone_event_remote_source.dart';
import 'package:relapse_flutter/models/safe_zone.dart';
import 'package:relapse_flutter/models/safe_zone_event.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/repositories/safe_zone_repository.dart';
import 'package:relapse_flutter/repositories/safe_zone_repository_impl.dart';

// ─── Remote Sources ──────────────────────────────────────────────────────

final safeZoneEventRemoteSourceProvider =
    Provider<SafeZoneEventRemoteSource>((ref) {
  return SafeZoneEventRemoteSource();
});

// ─── Repository ──────────────────────────────────────────────────────────

final safeZoneRepositoryProvider = Provider<SafeZoneRepository>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final uid = authUser?.uid ?? '';
  return SafeZoneRepositoryImpl(
    safeZoneSource: ref.watch(safeZoneRemoteSourceProvider),
    eventSource: ref.watch(safeZoneEventRemoteSourceProvider),
    uid: uid,
  );
});

// ─── Providers ───────────────────────────────────────────────────────────

/// Stream safe zones for selected patient.
final safeZonesProvider = StreamProvider<List<SafeZone>>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return const Stream.empty();
  return ref.watch(safeZoneRepositoryProvider).watchSafeZones(patientId);
});

/// The primary (first active) safe zone for the selected patient.
final primarySafeZoneProvider = Provider<SafeZone?>((ref) {
  final zones = ref.watch(safeZonesProvider).valueOrNull;
  if (zones == null || zones.isEmpty) return null;
  return zones.first;
});

/// Recent safe zone events for the selected patient.
final safeZoneEventsProvider = StreamProvider<List<SafeZoneEvent>>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return const Stream.empty();
  return ref
      .watch(safeZoneRepositoryProvider)
      .watchRecentEvents(patientId, limit: 20);
});
