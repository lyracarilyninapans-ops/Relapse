import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Add/Setup Patient UI State ─────────────────────────────────────────

final addPatientPairingCodeProvider =
    StateProvider.autoDispose<String>((ref) => '');

final patientSetupNameProvider =
    StateProvider.autoDispose<String>((ref) => '');

final patientSetupAgeProvider =
    StateProvider.autoDispose<String>((ref) => '');

final patientSetupNotesProvider =
    StateProvider.autoDispose<String>((ref) => '');

// ─── Edit Patient UI State ──────────────────────────────────────────────

final editPatientNameProvider =
    StateProvider.autoDispose<String>((ref) => '');

final editPatientAgeProvider =
    StateProvider.autoDispose<String>((ref) => '');

final editPatientNotesProvider =
    StateProvider.autoDispose<String>((ref) => '');

// ─── Edit Caregiver UI State ────────────────────────────────────────────

final editCaregiverNameProvider =
    StateProvider.autoDispose<String>((ref) => '');

final editCaregiverPhoneProvider =
    StateProvider.autoDispose<String>((ref) => '');

final editCaregiverBioProvider =
    StateProvider.autoDispose<String>((ref) => '');
