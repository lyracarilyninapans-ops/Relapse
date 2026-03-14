import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cloud-first settings service.
///
/// All reads/writes go through Firestore. SharedPreferences is used only as
/// a local cache so the app can show settings instantly on cold start and
/// when the device has no network connectivity.
class SettingsService {
  static const _keyCooldownMinutes = 'reminder_cooldown_minutes';
  static const _keyNotificationSound = 'notification_sound_enabled';
  static const _keyDailyReportHour = 'daily_report_hour';
  static const _keyDailyReportMinute = 'daily_report_minute';
  static const _keyThemeMode = 'theme_mode'; // system, light, dark

  final FirebaseFirestore _firestore;

  SettingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences');
  }

  // ─── Real-time stream (cloud source of truth) ───────────────────────

  /// Stream of all settings for a user. The UI should subscribe to this
  /// so it always reflects the latest cloud state.
  Stream<AppSettings> watchSettings(String uid) {
    return _settingsDoc(uid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return AppSettings.fromMap(data);
    });
  }

  // ─── One-shot read (cloud-first, cache fallback) ────────────────────

  Future<AppSettings> getSettings(String uid) async {
    try {
      final doc = await _settingsDoc(uid)
          .get(const GetOptions(source: Source.server));
      return AppSettings.fromMap(doc.data() ?? {});
    } catch (_) {
      try {
        final doc = await _settingsDoc(uid)
            .get(const GetOptions(source: Source.cache));
        return AppSettings.fromMap(doc.data() ?? {});
      } catch (_) {
        return AppSettings.defaults();
      }
    }
  }

  // ─── Write (always to cloud — Firestore handles offline queuing) ────

  Future<void> setReminderCooldownMinutes(String uid, int minutes) {
    return _settingsDoc(uid)
        .set({_keyCooldownMinutes: minutes}, SetOptions(merge: true));
  }

  Future<void> setNotificationSoundEnabled(String uid, bool enabled) {
    return _settingsDoc(uid)
        .set({_keyNotificationSound: enabled}, SetOptions(merge: true));
  }

  Future<void> setDailyReportTime(String uid, int hour, int minute) {
    return _settingsDoc(uid).set({
      _keyDailyReportHour: hour,
      _keyDailyReportMinute: minute,
    }, SetOptions(merge: true));
  }

  Future<void> setThemeMode(String uid, String mode) {
    return _settingsDoc(uid)
        .set({_keyThemeMode: mode}, SetOptions(merge: true));
  }

  // ─── Local cache helpers (SharedPreferences — offline fallback) ─────

  /// Hydrate SharedPreferences from the cloud snapshot so cold starts
  /// show correct values even when offline.
  static Future<void> cacheLocally(
      SharedPreferences prefs, AppSettings settings) async {
    await prefs.setInt(_keyCooldownMinutes, settings.reminderCooldownMinutes);
    await prefs.setBool(
        _keyNotificationSound, settings.notificationSoundEnabled);
    await prefs.setInt(_keyDailyReportHour, settings.dailyReportHour);
    await prefs.setInt(_keyDailyReportMinute, settings.dailyReportMinute);
    await prefs.setString(_keyThemeMode, settings.themeMode);
  }

  /// Read settings from the local cache (used for cold start before
  /// the Firestore stream emits).
  static AppSettings fromLocalCache(SharedPreferences prefs) {
    return AppSettings(
      reminderCooldownMinutes: prefs.getInt(_keyCooldownMinutes) ?? 30,
      notificationSoundEnabled: prefs.getBool(_keyNotificationSound) ?? true,
      dailyReportHour: prefs.getInt(_keyDailyReportHour) ?? 20,
      dailyReportMinute: prefs.getInt(_keyDailyReportMinute) ?? 0,
      themeMode: prefs.getString(_keyThemeMode) ?? 'system',
    );
  }
}

/// Immutable snapshot of app settings.
class AppSettings {
  final int reminderCooldownMinutes;
  final bool notificationSoundEnabled;
  final int dailyReportHour;
  final int dailyReportMinute;
  final String themeMode;

  const AppSettings({
    required this.reminderCooldownMinutes,
    required this.notificationSoundEnabled,
    required this.dailyReportHour,
    required this.dailyReportMinute,
    required this.themeMode,
  });

  factory AppSettings.defaults() => const AppSettings(
        reminderCooldownMinutes: 30,
        notificationSoundEnabled: true,
        dailyReportHour: 20,
        dailyReportMinute: 0,
        themeMode: 'system',
      );

  factory AppSettings.fromMap(Map<String, dynamic> data) {
    return AppSettings(
      reminderCooldownMinutes:
          (data['reminder_cooldown_minutes'] as num?)?.toInt() ?? 30,
      notificationSoundEnabled:
          data['notification_sound_enabled'] as bool? ?? true,
      dailyReportHour: (data['daily_report_hour'] as num?)?.toInt() ?? 20,
      dailyReportMinute: (data['daily_report_minute'] as num?)?.toInt() ?? 0,
      themeMode: data['theme_mode'] as String? ?? 'system',
    );
  }
}
