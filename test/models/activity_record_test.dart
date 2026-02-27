import 'package:flutter_test/flutter_test.dart';
import 'package:relapse_flutter/models/activity_record.dart';

void main() {
  group('ActivityEventType', () {
    test('enum has all expected values', () {
      expect(ActivityEventType.values.length, 6);
      expect(ActivityEventType.values, contains(ActivityEventType.locationUpdate));
      expect(ActivityEventType.values, contains(ActivityEventType.safeZoneEnter));
      expect(ActivityEventType.values, contains(ActivityEventType.safeZoneExit));
      expect(ActivityEventType.values, contains(ActivityEventType.reminderTriggered));
      expect(ActivityEventType.values, contains(ActivityEventType.watchDisconnected));
      expect(ActivityEventType.values, contains(ActivityEventType.watchReconnected));
    });

    test('enum name serialization', () {
      expect(ActivityEventType.locationUpdate.name, 'locationUpdate');
      expect(ActivityEventType.safeZoneExit.name, 'safeZoneExit');
    });

    test('enum firstWhere lookup works for valid values', () {
      final result = ActivityEventType.values.firstWhere(
        (e) => e.name == 'safeZoneExit',
        orElse: () => ActivityEventType.locationUpdate,
      );
      expect(result, ActivityEventType.safeZoneExit);
    });

    test('enum firstWhere fallback for unknown values', () {
      final result = ActivityEventType.values.firstWhere(
        (e) => e.name == 'unknown',
        orElse: () => ActivityEventType.locationUpdate,
      );
      expect(result, ActivityEventType.locationUpdate);
    });
  });
}
