import 'package:flutter_riverpod/flutter_riverpod.dart';

final addPatientPairingCodeProvider =
    StateProvider.autoDispose<String>((ref) => '');

final patientSetupNameProvider =
    StateProvider.autoDispose<String>((ref) => '');

final patientSetupAgeProvider =
    StateProvider.autoDispose<String>((ref) => '');

final patientSetupNotesProvider =
    StateProvider.autoDispose<String>((ref) => '');

final editPatientNameProvider =
    StateProvider.autoDispose<String>((ref) => 'John Doe');

final editPatientAgeProvider =
    StateProvider.autoDispose<String>((ref) => '72');

final editPatientNotesProvider = StateProvider.autoDispose<String>(
  (ref) => 'Enjoys gardening and classical music.',
);

final editCaregiverNameProvider =
    StateProvider.autoDispose<String>((ref) => 'Jane Caregiver');

final editCaregiverPhoneProvider =
    StateProvider.autoDispose<String>((ref) => '+1 555-0123');

final editCaregiverBioProvider = StateProvider.autoDispose<String>(
  (ref) => 'Caring for my father with early-stage dementia.',
);

final safeZoneIsInsideProvider = StateProvider.autoDispose<bool>((ref) => true);
