import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/data/remote/activity_remote_source.dart';
import 'package:relapse_flutter/data/remote/daily_summary_remote_source.dart';
import 'package:relapse_flutter/data/remote/patient_remote_source.dart';
import 'package:relapse_flutter/data/remote/safe_zone_remote_source.dart';
import 'package:relapse_flutter/data/remote/user_remote_source.dart';
import 'package:relapse_flutter/models/caregiver_profile.dart';
import 'package:relapse_flutter/models/patient.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';

// ─── Remote Source Providers (cloud-first) ──────────────────────────────

final activityRemoteSourceProvider = Provider<ActivityRemoteSource>((ref) {
  return ActivityRemoteSource();
});

final dailySummaryRemoteSourceProvider =
    Provider<DailySummaryRemoteSource>((ref) {
  return DailySummaryRemoteSource();
});

final patientRemoteSourceProvider = Provider<PatientRemoteSource>((ref) {
  return PatientRemoteSource();
});

final safeZoneRemoteSourceProvider = Provider<SafeZoneRemoteSource>((ref) {
  return SafeZoneRemoteSource();
});

final userRemoteSourceProvider = Provider<UserRemoteSource>((ref) {
  return UserRemoteSource();
});

// ─── Patient Providers (cloud-first) ────────────────────────────────────

/// Stream of all patients for the current user.
final patientsProvider = StreamProvider<List<Patient>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return ref.watch(patientRemoteSourceProvider).watchPatients(authUser.uid);
});

/// Currently selected patient ID.
/// Prefers the patient with an active watch pairing; falls back to first.
final selectedPatientIdProvider = StateProvider<String?>((ref) {
  final patients = ref.watch(patientsProvider).valueOrNull;
  if (patients == null || patients.isEmpty) return null;
  // Prefer the patient that currently has a paired watch.
  final paired = patients.where((p) => p.pairedWatchId != null && p.pairedWatchId!.isNotEmpty);
  if (paired.isNotEmpty) return paired.first.id;
  return patients.first.id;
});

/// Currently selected patient object.
final selectedPatientProvider = Provider<Patient?>((ref) {
  final patients = ref.watch(patientsProvider).valueOrNull;
  final selectedId = ref.watch(selectedPatientIdProvider);
  if (patients == null || patients.isEmpty) return null;
  if (selectedId == null) {
    // Fallback: prefer paired patient, then first.
    final paired = patients.where((p) => p.pairedWatchId != null && p.pairedWatchId!.isNotEmpty);
    return paired.isNotEmpty ? paired.first : patients.first;
  }
  try {
    return patients.firstWhere((p) => p.id == selectedId);
  } catch (_) {
    // Selected ID is stale — pick the paired patient or first.
    final paired = patients.where((p) => p.pairedWatchId != null && p.pairedWatchId!.isNotEmpty);
    final fallback = paired.isNotEmpty ? paired.first : patients.first;
    Future.microtask(() {
      ref.read(selectedPatientIdProvider.notifier).state = fallback.id;
    });
    return fallback;
  }
});

// ─── Caregiver Profile Provider ─────────────────────────────────────────

/// Stream of the current caregiver's profile.
final caregiverProfileProvider = StreamProvider<CaregiverProfile?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return ref.watch(userRemoteSourceProvider).watchProfile(authUser.uid);
});
