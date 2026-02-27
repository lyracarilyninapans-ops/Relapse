import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:relapse_flutter/models/memory_reminder.dart';
import 'package:relapse_flutter/models/notification_payload.dart';
import 'package:relapse_flutter/models/safe_zone_event.dart';

/// Top-level handler for background FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the system tray automatically.
  // Additional processing can be added here if needed.
  debugPrint('Background FCM message: ${message.messageId}');
}

/// Abstract notification service interface.
abstract class NotificationService {
  Future<void> initialize();
  Future<void> showSafeZoneAlert(SafeZoneEvent event, String zoneName);
  Future<void> showReminderTriggered(MemoryReminder reminder);
  Future<void> showWatchDisconnected();
  Future<void> showWatchLowBattery(int level);
  Future<void> scheduleDailyReport(Duration timeOfDay);
  Future<void> cancelAll();
  Stream<NotificationPayload> get onNotificationTapped;
  Future<String?> getFcmToken();
  Future<void> registerFcmToken(String uid);
}

/// Firebase Cloud Messaging + flutter_local_notifications implementation.
class FirebaseNotificationService implements NotificationService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseFirestore _firestore;

  final _tapController = StreamController<NotificationPayload>.broadcast();

  // Notification channel IDs
  static const _safeZoneChannelId = 'safe_zone_alerts';
  static const _safeZoneChannelName = 'Safe Zone Alerts';
  static const _safeZoneChannelDesc =
      'High-priority alerts when patient exits a safe zone';

  static const _reminderChannelId = 'memory_reminders';
  static const _reminderChannelName = 'Memory Reminders';
  static const _reminderChannelDesc =
      'Notifications when a memory reminder is triggered';

  static const _watchChannelId = 'watch_status';
  static const _watchChannelName = 'Watch Status';
  static const _watchChannelDesc =
      'Alerts about watch connectivity and battery';

  static const _dailyChannelId = 'daily_report';
  static const _dailyChannelName = 'Daily Report';
  static const _dailyChannelDesc = 'Daily activity summary notifications';

  FirebaseNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _safeZoneChannelId,
            _safeZoneChannelName,
            description: _safeZoneChannelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _reminderChannelId,
            _reminderChannelName,
            description: _reminderChannelDesc,
            importance: Importance.high,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _watchChannelId,
            _watchChannelName,
            description: _watchChannelDesc,
            importance: Importance.defaultImportance,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _dailyChannelId,
            _dailyChannelName,
            description: _dailyChannelDesc,
            importance: Importance.low,
          ),
        );
      }
    }

    // Handle FCM foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps that open the app from terminated/background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Set foreground notification presentation (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == null || response.payload!.isEmpty) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _tapController.add(NotificationPayload.fromMap(data));
    } catch (_) {
      // Ignore malformed payloads
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Show as local notification since FCM doesn't auto-display in foreground
    _localNotifications.show(
      message.hashCode,
      notification.title ?? 'Relapse',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _inferChannel(message.data),
          _inferChannelName(message.data),
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _tapController.add(NotificationPayload.fromMap(message.data));
  }

  String _inferChannel(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    if (type.contains('safe_zone')) return _safeZoneChannelId;
    if (type.contains('reminder')) return _reminderChannelId;
    if (type.contains('watch')) return _watchChannelId;
    if (type.contains('daily')) return _dailyChannelId;
    return _safeZoneChannelId;
  }

  String _inferChannelName(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    if (type.contains('safe_zone')) return _safeZoneChannelName;
    if (type.contains('reminder')) return _reminderChannelName;
    if (type.contains('watch')) return _watchChannelName;
    if (type.contains('daily')) return _dailyChannelName;
    return _safeZoneChannelName;
  }

  // ── Local notification triggers ──────────────────────────────────────

  @override
  Future<void> showSafeZoneAlert(
      SafeZoneEvent event, String zoneName) async {
    final isExit = event.eventType == SafeZoneEventType.exit;
    final title = isExit ? 'Safe Zone Alert' : 'Safe Zone Update';
    final body = isExit
        ? 'Patient has left the safe zone "$zoneName"'
        : 'Patient has entered the safe zone "$zoneName"';

    final payload = NotificationPayload(
      type: 'safe_zone_${event.eventType.name}',
      eventId: event.id,
      screen: 'activity',
    );

    await _localNotifications.show(
      event.id.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _safeZoneChannelId,
          _safeZoneChannelName,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode(payload.toMap()),
    );
  }

  @override
  Future<void> showReminderTriggered(MemoryReminder reminder) async {
    final payload = NotificationPayload(
      type: 'reminder_triggered',
      reminderId: reminder.id,
      screen: 'memory_details',
    );

    await _localNotifications.show(
      reminder.id.hashCode,
      'Memory Reminder',
      reminder.title,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(payload.toMap()),
    );
  }

  @override
  Future<void> showWatchDisconnected() async {
    const payload = NotificationPayload(
      type: 'watch_disconnected',
      screen: 'activity',
    );

    await _localNotifications.show(
      'watch_disconnected'.hashCode,
      'Watch Disconnected',
      'The paired watch has been disconnected for over 10 minutes.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _watchChannelId,
          _watchChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: jsonEncode(payload.toMap()),
    );
  }

  @override
  Future<void> showWatchLowBattery(int level) async {
    final payload = NotificationPayload(
      type: 'watch_low_battery',
      extra: {'batteryLevel': level.toString()},
    );

    await _localNotifications.show(
      'watch_battery_$level'.hashCode,
      'Watch Battery Low',
      'Watch battery is at $level%. Please charge soon.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _watchChannelId,
          _watchChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: jsonEncode(payload.toMap()),
    );
  }

  @override
  Future<void> scheduleDailyReport(Duration timeOfDay) async {
    // Cancel any existing scheduled daily report
    await _localNotifications.cancel('daily_report'.hashCode);

    // Schedule a daily notification
    // Note: For precise daily scheduling, use a background isolate or
    // Cloud Functions. This provides a simple local fallback.
    final payload = NotificationPayload(
      type: 'daily_report',
      screen: 'activity',
    );

    await _localNotifications.show(
      'daily_report'.hashCode,
      'Daily Activity Report',
      'Your daily activity summary is ready to review.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
      payload: jsonEncode(payload.toMap()),
    );
  }

  @override
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  @override
  Stream<NotificationPayload> get onNotificationTapped => _tapController.stream;

  // ── FCM Token Management ─────────────────────────────────────────────

  @override
  Future<String?> getFcmToken() async {
    return _messaging.getToken();
  }

  @override
  Future<void> registerFcmToken(String uid) async {
    final token = await getFcmToken();
    if (token == null) return;

    final deviceId = '${Platform.operatingSystem}_${token.hashCode}';
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .set({
      'fcmToken': token,
      'platform': Platform.operatingSystem,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      final newDeviceId =
          '${Platform.operatingSystem}_${newToken.hashCode}';
      _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(newDeviceId)
          .set({
        'fcmToken': newToken,
        'platform': Platform.operatingSystem,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  void dispose() {
    _tapController.close();
  }
}
