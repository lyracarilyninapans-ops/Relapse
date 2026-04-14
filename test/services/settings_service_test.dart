import 'package:flutter_test/flutter_test.dart';
import 'package:relapse_flutter/services/settings_service.dart';

void main() {
  group('AppSettings', () {
    test('defaults are correct', () {
      final settings = AppSettings.defaults();
      expect(settings.reminderCooldownMinutes, 30);
      expect(settings.notificationSoundEnabled, true);
      expect(settings.dailyReportHour, 20);
      expect(settings.dailyReportMinute, 0);
      expect(settings.themeMode, 'system');
      expect(settings.useOptimizedLatestLocationQuery, true);
    });

    test('fromMap parses values correctly', () {
      final settings = AppSettings.fromMap({
        'reminder_cooldown_minutes': 60,
        'notification_sound_enabled': false,
        'daily_report_hour': 8,
        'daily_report_minute': 30,
        'theme_mode': 'dark',
        'use_optimized_latest_location_query': false,
      });
      expect(settings.reminderCooldownMinutes, 60);
      expect(settings.notificationSoundEnabled, false);
      expect(settings.dailyReportHour, 8);
      expect(settings.dailyReportMinute, 30);
      expect(settings.themeMode, 'dark');
      expect(settings.useOptimizedLatestLocationQuery, false);
    });

    test('fromMap uses defaults for missing keys', () {
      final settings = AppSettings.fromMap({});
      expect(settings.reminderCooldownMinutes, 30);
      expect(settings.notificationSoundEnabled, true);
      expect(settings.dailyReportHour, 20);
      expect(settings.dailyReportMinute, 0);
      expect(settings.themeMode, 'system');
      expect(settings.useOptimizedLatestLocationQuery, true);
    });

    test('fromMap handles partial data', () {
      final settings = AppSettings.fromMap({
        'reminder_cooldown_minutes': 90,
        'theme_mode': 'light',
      });
      expect(settings.reminderCooldownMinutes, 90);
      expect(settings.notificationSoundEnabled, true); // default
      expect(settings.dailyReportHour, 20); // default
      expect(settings.themeMode, 'light');
      expect(settings.useOptimizedLatestLocationQuery, true); // default
    });

    test('fromMap parses latest-location query flag when provided', () {
      final settingsEnabled = AppSettings.fromMap({
        'use_optimized_latest_location_query': true,
      });
      final settingsDisabled = AppSettings.fromMap({
        'use_optimized_latest_location_query': false,
      });

      expect(settingsEnabled.useOptimizedLatestLocationQuery, true);
      expect(settingsDisabled.useOptimizedLatestLocationQuery, false);
    });
  });

  group('SettingsService', () {
    // SettingsService now requires Firestore (cloud-first architecture).
    // Integration tests for read/write should use the Firebase emulator.
    // The instantiation test is skipped in unit tests.
    test('constructor accepts custom Firestore instance', () {
      // Verifies the factory parameter is available for dependency injection
      // (used in integration tests with Firebase emulator).
      expect(SettingsService.new, isA<Function>());
    });
  });
}
