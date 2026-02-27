import 'package:flutter_test/flutter_test.dart';
import 'package:relapse_flutter/models/safe_zone_event.dart';

void main() {
  group('SafeZoneEventType', () {
    test('enum has enter and exit values', () {
      expect(SafeZoneEventType.values.length, 2);
      expect(SafeZoneEventType.values, contains(SafeZoneEventType.enter));
      expect(SafeZoneEventType.values, contains(SafeZoneEventType.exit));
    });

    test('enum name serialization works', () {
      expect(SafeZoneEventType.enter.name, 'enter');
      expect(SafeZoneEventType.exit.name, 'exit');
    });

    test('enum firstWhere lookup works for valid values', () {
      final result = SafeZoneEventType.values.firstWhere(
        (e) => e.name == 'exit',
        orElse: () => SafeZoneEventType.exit,
      );
      expect(result, SafeZoneEventType.exit);
    });

    test('enum firstWhere fallback for invalid values', () {
      final result = SafeZoneEventType.values.firstWhere(
        (e) => e.name == 'invalid',
        orElse: () => SafeZoneEventType.exit,
      );
      expect(result, SafeZoneEventType.exit);
    });
  });
}
