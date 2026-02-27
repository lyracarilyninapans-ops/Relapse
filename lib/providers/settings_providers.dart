import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:relapse_flutter/services/settings_service.dart';

/// SharedPreferences instance — must be initialized before use.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a valid instance',
  );
});

/// SettingsService backed by SharedPreferences.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(sharedPreferencesProvider));
});

/// Reminder cooldown in minutes.
final reminderCooldownProvider = StateProvider<int>((ref) {
  return ref.watch(settingsServiceProvider).reminderCooldownMinutes;
});

/// Whether notification sounds are enabled.
final notificationSoundProvider = StateProvider<bool>((ref) {
  return ref.watch(settingsServiceProvider).notificationSoundEnabled;
});

/// Daily report time as TimeOfDay.
final dailyReportTimeProvider = StateProvider<TimeOfDay>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return TimeOfDay(hour: service.dailyReportHour, minute: service.dailyReportMinute);
});

/// Theme mode preference (system, light, dark).
final themeModeProvider = StateProvider<String>((ref) {
  return ref.watch(settingsServiceProvider).themeMode;
});
