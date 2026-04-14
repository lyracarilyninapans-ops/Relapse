import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/data/remote/activity_remote_source.dart';
import 'package:relapse_flutter/data/remote/daily_summary_remote_source.dart';
import 'package:relapse_flutter/data/remote/patient_remote_source.dart';
import 'package:relapse_flutter/data/remote/safe_zone_remote_source.dart';
import 'package:relapse_flutter/data/remote/user_remote_source.dart';
import 'package:relapse_flutter/models/caregiver_profile.dart';
import 'package:relapse_flutter/models/patient.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/settings_providers.dart';

// ─── Remote Source Providers (cloud-first) ──────────────────────────────

final activityRemoteSourceProvider = Provider<ActivityRemoteSource>((ref) {
  final useOptimizedLatestLocationQuery =
      ref.watch(latestLocationOptimizedQueryProvider);
  return ActivityRemoteSource(
    useOptimizedLatestLocationQuery: useOptimizedLatestLocationQuery,
  );
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

class SelectedPatientIdNotifier extends StateNotifier<String?> {
  final Ref _ref;
  bool _hasExplicitSelection = false;

  SelectedPatientIdNotifier(this._ref) : super(null) {
    _ref.listen<AsyncValue<List<Patient>>>(patientsProvider, (previous, next) {
      autoSelectIfNeeded(next.valueOrNull ?? const <Patient>[]);
    });

    autoSelectIfNeeded(_ref.read(patientsProvider).valueOrNull ?? const <Patient>[]);
  }

  /// Explicit user selection that should be preserved while still valid.
  void selectPatient(String? patientId) {
    final patients = _ref.read(patientsProvider).valueOrNull ?? const <Patient>[];
    if (patientId == null) {
      _hasExplicitSelection = false;
      autoSelectIfNeeded(patients);
      return;
    }

    final exists = patients.any((p) => p.id == patientId);
    if (!exists) return;
    _hasExplicitSelection = true;
    state = patientId;
  }

  /// Selects a fallback only when no valid selection exists.
  /// This never overwrites a valid explicit user selection.
  void autoSelectIfNeeded(List<Patient> patients) {
    if (patients.isEmpty) {
      _hasExplicitSelection = false;
      state = null;
      return;
    }

    if (_hasExplicitSelection) {
      final stillValid = state != null && patients.any((p) => p.id == state);
      if (stillValid) return;
      _hasExplicitSelection = false;
    }

    final currentValid = state != null && patients.any((p) => p.id == state);
    if (currentValid) return;

    state = _preferredPatientId(patients);
  }

  String _preferredPatientId(List<Patient> patients) {
    final paired = patients.where(
      (p) => p.pairedWatchId != null && p.pairedWatchId!.isNotEmpty,
    );
    if (paired.isNotEmpty) return paired.first.id;
    return patients.first.id;
  }
}

/// Currently selected patient ID.
final selectedPatientIdProvider =
    StateNotifierProvider<SelectedPatientIdNotifier, String?>((ref) {
  return SelectedPatientIdNotifier(ref);
});

/// Currently selected patient object.
final selectedPatientProvider = Provider<Patient?>((ref) {
  final patients = ref.watch(patientsProvider).valueOrNull;
  final selectedId = ref.watch(selectedPatientIdProvider);
  if (patients == null || patients.isEmpty) return null;

  Patient preferredFallback() {
    final paired = patients.where(
      (p) => p.pairedWatchId != null && p.pairedWatchId!.isNotEmpty,
    );
    if (paired.isNotEmpty) return paired.first;
    return patients.first;
  }

  if (selectedId == null) {
    return preferredFallback();
  }

  for (final patient in patients) {
    if (patient.id == selectedId) return patient;
  }
  return preferredFallback();
});

// ─── Caregiver Profile Provider ─────────────────────────────────────────

/// Stream of the current caregiver's profile.
final caregiverProfileProvider = StreamProvider<CaregiverProfile?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return ref.watch(userRemoteSourceProvider).watchProfile(authUser.uid);
});
