import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relapse_flutter/models/patient.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';

Patient _patient({
  required String id,
  String name = 'Patient',
  String? pairedWatchId,
}) {
  return Patient(
    id: id,
    caregiverUid: 'caregiver_1',
    name: name,
    pairedWatchId: pairedWatchId,
    createdAt: DateTime(2026, 1, 1),
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('selectedPatientIdProvider', () {
    test('auto-selects paired patient when no explicit selection exists', () async {
      final controller = StreamController<List<Patient>>.broadcast();
      final container = ProviderContainer(
        overrides: [
          patientsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      container.read(selectedPatientIdProvider);
      controller.add([
        _patient(id: 'p1', pairedWatchId: null),
        _patient(id: 'p2', pairedWatchId: 'watch_1'),
      ]);
      await _flush();

      expect(container.read(selectedPatientIdProvider), 'p2');
    });

    test('preserves explicit selection while it remains valid', () async {
      final controller = StreamController<List<Patient>>.broadcast();
      final container = ProviderContainer(
        overrides: [
          patientsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      container.read(selectedPatientIdProvider);
      controller.add([
        _patient(id: 'p1', pairedWatchId: null),
        _patient(id: 'p2', pairedWatchId: 'watch_1'),
      ]);
      await _flush();

      container.read(selectedPatientIdProvider.notifier).selectPatient('p1');
      expect(container.read(selectedPatientIdProvider), 'p1');

      controller.add([
        _patient(id: 'p1', pairedWatchId: null),
        _patient(id: 'p2', pairedWatchId: 'watch_1'),
        _patient(id: 'p3', pairedWatchId: 'watch_2'),
      ]);
      await _flush();

      expect(container.read(selectedPatientIdProvider), 'p1');
    });

    test('falls back when explicit selection is removed by list mutation', () async {
      final controller = StreamController<List<Patient>>.broadcast();
      final container = ProviderContainer(
        overrides: [
          patientsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      container.read(selectedPatientIdProvider);
      controller.add([
        _patient(id: 'p1', pairedWatchId: null),
        _patient(id: 'p2', pairedWatchId: 'watch_1'),
      ]);
      await _flush();

      container.read(selectedPatientIdProvider.notifier).selectPatient('p1');
      expect(container.read(selectedPatientIdProvider), 'p1');

      controller.add([
        _patient(id: 'p2', pairedWatchId: 'watch_1'),
      ]);
      await _flush();

      expect(container.read(selectedPatientIdProvider), 'p2');
    });
  });
}
