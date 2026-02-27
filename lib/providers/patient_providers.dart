import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/data/remote/activity_remote_source.dart';
import 'package:relapse_flutter/data/remote/daily_summary_remote_source.dart';
import 'package:relapse_flutter/data/remote/patient_remote_source.dart';
import 'package:relapse_flutter/data/remote/safe_zone_remote_source.dart';
import 'package:relapse_flutter/data/remote/user_remote_source.dart';
import 'package:relapse_flutter/models/caregiver_profile.dart';
import 'package:relapse_flutter/models/patient.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/repositories/activity_repository.dart';
import 'package:relapse_flutter/repositories/activity_repository_impl.dart';

// ─── Remote Source Providers ────────────────────────────────────────────

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

// ─── Repository Provider ────────────────────────────────────────────────

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final uid = authUser?.uid ?? '';
  return ActivityRepositoryImpl(
    activitySource: ref.watch(activityRemoteSourceProvider),
    summarySource: ref.watch(dailySummaryRemoteSourceProvider),
    uid: uid,
  );
});

// ─── Patient Providers ──────────────────────────────────────────────────

/// Stream of all patients for the current user.
final patientsProvider = StreamProvider<List<Patient>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return ref.watch(patientRemoteSourceProvider).watchPatients(authUser.uid);
});

/// Currently selected patient ID (first patient by default).
final selectedPatientIdProvider = StateProvider<String?>((ref) {
  final patients = ref.watch(patientsProvider).valueOrNull;
  if (patients != null && patients.isNotEmpty) {
    return patients.first.id;
  }
  return null;
});

/// Currently selected patient object.
final selectedPatientProvider = Provider<Patient?>((ref) {
  final patients = ref.watch(patientsProvider).valueOrNull;
  final selectedId = ref.watch(selectedPatientIdProvider);
  if (patients == null || selectedId == null) return null;
  try {
    return patients.firstWhere((p) => p.id == selectedId);
  } catch (_) {
    return patients.isNotEmpty ? patients.first : null;
  }
});

// ─── Caregiver Profile Provider ─────────────────────────────────────────

/// Stream of the current caregiver's profile.
final caregiverProfileProvider = StreamProvider<CaregiverProfile?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return ref.watch(userRemoteSourceProvider).watchProfile(authUser.uid);
});
