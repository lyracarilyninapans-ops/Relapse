import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/data/remote/safe_zone_event_remote_source.dart';
import 'package:relapse_flutter/models/safe_zone.dart';
import 'package:relapse_flutter/models/safe_zone_event.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';

// ─── Remote Sources ──────────────────────────────────────────────────────

final safeZoneEventRemoteSourceProvider =
    Provider<SafeZoneEventRemoteSource>((ref) {
  return SafeZoneEventRemoteSource();
});

// ─── Providers (direct cloud access) ─────────────────────────────────────

/// Stream safe zones for selected patient directly from Firestore.
final safeZonesProvider = StreamProvider<List<SafeZone>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final patientId = ref.watch(selectedPatientIdProvider);
  if (authUser == null || patientId == null) return const Stream.empty();
  return ref
      .watch(safeZoneRemoteSourceProvider)
      .watchSafeZones(authUser.uid, patientId);
});

/// The primary (first active) safe zone for the selected patient.
final primarySafeZoneProvider = Provider<SafeZone?>((ref) {
  final zones = ref.watch(safeZonesProvider).valueOrNull;
  if (zones == null || zones.isEmpty) return null;
  return zones.first;
});

/// Recent safe zone events for the selected patient directly from Firestore.
final safeZoneEventsProvider = StreamProvider<List<SafeZoneEvent>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final patientId = ref.watch(selectedPatientIdProvider);
  if (authUser == null || patientId == null) return const Stream.empty();
  return ref
      .watch(safeZoneEventRemoteSourceProvider)
      .watchRecentEvents(authUser.uid, patientId, limit: 20);
});
