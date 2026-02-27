import 'package:flutter_test/flutter_test.dart';
import 'package:relapse_flutter/models/safe_zone.dart';

void main() {
  group('SafeZone', () {
    test('fromJson creates correct SafeZone', () {
      final json = {
        'id': 'sz1',
        'patientId': 'p1',
        'centerLat': 37.7749,
        'centerLng': -122.4194,
        'radiusMeters': 500.0,
        'isActive': true,
        'alarmEnabled': true,
        'vibrationEnabled': false,
        'contactOnExit': '+1234567890',
      };

      final zone = SafeZone.fromJson(json);

      expect(zone.id, 'sz1');
      expect(zone.patientId, 'p1');
      expect(zone.centerLat, 37.7749);
      expect(zone.centerLng, -122.4194);
      expect(zone.radiusMeters, 500.0);
      expect(zone.isActive, true);
      expect(zone.alarmEnabled, true);
      expect(zone.vibrationEnabled, false);
      expect(zone.contactOnExit, '+1234567890');
    });

    test('fromJson uses defaults for missing booleans', () {
      final json = {
        'id': 'sz2',
        'patientId': 'p1',
        'centerLat': 0.0,
        'centerLng': 0.0,
        'radiusMeters': 100,
      };

      final zone = SafeZone.fromJson(json);

      expect(zone.isActive, true);
      expect(zone.alarmEnabled, true);
      expect(zone.vibrationEnabled, true);
      expect(zone.contactOnExit, isNull);
    });

    test('toJson produces correct output', () {
      const zone = SafeZone(
        id: 'sz1',
        patientId: 'p1',
        centerLat: 37.7749,
        centerLng: -122.4194,
        radiusMeters: 500.0,
      );

      final json = zone.toJson();

      expect(json['id'], 'sz1');
      expect(json['centerLat'], 37.7749);
      expect(json['radiusMeters'], 500.0);
      expect(json['isActive'], true);
    });

    test('round-trip toJson/fromJson preserves data', () {
      const original = SafeZone(
        id: 'sz3',
        patientId: 'p2',
        centerLat: 1.3521,
        centerLng: 103.8198,
        radiusMeters: 250.0,
        isActive: false,
        alarmEnabled: false,
        vibrationEnabled: true,
        contactOnExit: 'caregiver@email.com',
      );

      final json = original.toJson();
      final restored = SafeZone.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.patientId, original.patientId);
      expect(restored.centerLat, original.centerLat);
      expect(restored.centerLng, original.centerLng);
      expect(restored.radiusMeters, original.radiusMeters);
      expect(restored.isActive, original.isActive);
      expect(restored.alarmEnabled, original.alarmEnabled);
      expect(restored.vibrationEnabled, original.vibrationEnabled);
      expect(restored.contactOnExit, original.contactOnExit);
    });

    test('copyWith overrides specified fields', () {
      const original = SafeZone(
        id: 'sz1',
        patientId: 'p1',
        centerLat: 37.7749,
        centerLng: -122.4194,
        radiusMeters: 500.0,
      );

      final modified = original.copyWith(
        radiusMeters: 1000.0,
        isActive: false,
      );

      expect(modified.id, 'sz1');
      expect(modified.radiusMeters, 1000.0);
      expect(modified.isActive, false);
      expect(modified.centerLat, 37.7749);
    });
  });
}
