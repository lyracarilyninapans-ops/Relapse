import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:relapse_flutter/services/settings_service.dart';

void main() {
  group('SettingsService', () {
    late SettingsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
    });

    test('default reminder cooldown is 30 minutes', () {
      expect(service.reminderCooldownMinutes, 30);
    });

    test('setReminderCooldownMinutes persists value', () async {
      await service.setReminderCooldownMinutes(60);
      expect(service.reminderCooldownMinutes, 60);
    });

    test('default notification sound is enabled', () {
      expect(service.notificationSoundEnabled, true);
    });

    test('setNotificationSoundEnabled persists value', () async {
      await service.setNotificationSoundEnabled(false);
      expect(service.notificationSoundEnabled, false);
    });

    test('default daily report time is 20:00', () {
      expect(service.dailyReportHour, 20);
      expect(service.dailyReportMinute, 0);
    });

    test('setDailyReportTime persists hour and minute', () async {
      await service.setDailyReportTime(8, 30);
      expect(service.dailyReportHour, 8);
      expect(service.dailyReportMinute, 30);
    });

    test('default theme mode is system', () {
      expect(service.themeMode, 'system');
    });

    test('setThemeMode persists value', () async {
      await service.setThemeMode('dark');
      expect(service.themeMode, 'dark');
    });

    test('values persist across service instances', () async {
      await service.setReminderCooldownMinutes(90);
      await service.setNotificationSoundEnabled(false);
      await service.setThemeMode('light');

      // Create new service with same SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final service2 = SettingsService(prefs);

      expect(service2.reminderCooldownMinutes, 90);
      expect(service2.notificationSoundEnabled, false);
      expect(service2.themeMode, 'light');
    });
  });
}
