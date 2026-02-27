import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting app settings in SharedPreferences.
class SettingsService {
  static const _keyCooldownMinutes = 'reminder_cooldown_minutes';
  static const _keyNotificationSound = 'notification_sound_enabled';
  static const _keyDailyReportHour = 'daily_report_hour';
  static const _keyDailyReportMinute = 'daily_report_minute';
  static const _keyThemeMode = 'theme_mode'; // system, light, dark

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // ── Reminder cooldown ────────────────────────────────────────────────

  int get reminderCooldownMinutes => _prefs.getInt(_keyCooldownMinutes) ?? 30;

  Future<void> setReminderCooldownMinutes(int minutes) async {
    await _prefs.setInt(_keyCooldownMinutes, minutes);
  }

  // ── Notification sound ───────────────────────────────────────────────

  bool get notificationSoundEnabled =>
      _prefs.getBool(_keyNotificationSound) ?? true;

  Future<void> setNotificationSoundEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationSound, enabled);
  }

  // ── Daily report time ────────────────────────────────────────────────

  int get dailyReportHour => _prefs.getInt(_keyDailyReportHour) ?? 20;
  int get dailyReportMinute => _prefs.getInt(_keyDailyReportMinute) ?? 0;

  Future<void> setDailyReportTime(int hour, int minute) async {
    await _prefs.setInt(_keyDailyReportHour, hour);
    await _prefs.setInt(_keyDailyReportMinute, minute);
  }

  // ── Theme mode ───────────────────────────────────────────────────────

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }
}
