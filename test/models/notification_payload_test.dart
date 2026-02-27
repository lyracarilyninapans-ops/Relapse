import 'package:flutter_test/flutter_test.dart';
import 'package:relapse_flutter/models/notification_payload.dart';

void main() {
  group('NotificationPayload', () {
    test('fromMap creates correct payload', () {
      final map = {
        'type': 'safe_zone_exit',
        'patientId': 'p123',
        'eventId': 'e456',
        'screen': 'activity',
      };

      final payload = NotificationPayload.fromMap(map);

      expect(payload.type, 'safe_zone_exit');
      expect(payload.patientId, 'p123');
      expect(payload.eventId, 'e456');
      expect(payload.screen, 'activity');
      expect(payload.reminderId, isNull);
    });

    test('fromMap handles missing fields gracefully', () {
      final payload = NotificationPayload.fromMap({});

      expect(payload.type, 'unknown');
      expect(payload.patientId, isNull);
      expect(payload.eventId, isNull);
      expect(payload.screen, isNull);
    });

    test('toMap produces correct output', () {
      const payload = NotificationPayload(
        type: 'reminder_triggered',
        reminderId: 'r789',
        screen: 'memory_details',
      );

      final map = payload.toMap();

      expect(map['type'], 'reminder_triggered');
      expect(map['reminderId'], 'r789');
      expect(map['screen'], 'memory_details');
      expect(map.containsKey('patientId'), isFalse);
      expect(map.containsKey('eventId'), isFalse);
    });

    test('toMap includes extra fields', () {
      const payload = NotificationPayload(
        type: 'watch_low_battery',
        extra: {'batteryLevel': '15'},
      );

      final map = payload.toMap();

      expect(map['type'], 'watch_low_battery');
      expect(map['batteryLevel'], '15');
    });

    test('round-trip fromMap/toMap preserves data', () {
      const original = NotificationPayload(
        type: 'safe_zone_enter',
        patientId: 'patient1',
        eventId: 'event1',
        screen: 'activity',
      );

      final map = original.toMap();
      final restored = NotificationPayload.fromMap(map);

      expect(restored.type, original.type);
      expect(restored.patientId, original.patientId);
      expect(restored.eventId, original.eventId);
      expect(restored.screen, original.screen);
    });
  });
}
