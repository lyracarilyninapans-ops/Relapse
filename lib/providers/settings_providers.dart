import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/services/settings_service.dart';

/// Cloud-first SettingsService (Firestore-backed).
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// Real-time stream of all settings from Firestore.
/// This is the primary settings source — cloud is the source of truth.
final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value(AppSettings.defaults());
  return ref.watch(settingsServiceProvider).watchSettings(authUser.uid);
});

/// Reminder cooldown in minutes (derived from cloud settings stream).
final reminderCooldownProvider = Provider<int>((ref) {
  return ref.watch(appSettingsProvider).valueOrNull?.reminderCooldownMinutes ?? 30;
});

/// Whether notification sounds are enabled (derived from cloud settings stream).
final notificationSoundProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).valueOrNull?.notificationSoundEnabled ?? true;
});

/// Daily report time as TimeOfDay (derived from cloud settings stream).
final dailyReportTimeProvider = Provider<TimeOfDay>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return TimeOfDay(
    hour: settings?.dailyReportHour ?? 20,
    minute: settings?.dailyReportMinute ?? 0,
  );
});

/// Theme mode preference (derived from cloud settings stream).
final themeModeProvider = Provider<String>((ref) {
  return ref.watch(appSettingsProvider).valueOrNull?.themeMode ?? 'system';
});
