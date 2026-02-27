import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/models/notification_payload.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/services/notification_service.dart';

/// Singleton NotificationService instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return FirebaseNotificationService();
});

/// Stream of notification taps for navigation.
final notificationTapProvider = StreamProvider<NotificationPayload>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.onNotificationTapped;
});

/// Registers FCM token when user is authenticated.
/// Watch this provider from a top-level widget to ensure token registration.
final fcmTokenRegistrationProvider = FutureProvider<void>((ref) async {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return;
  final service = ref.watch(notificationServiceProvider);
  await service.registerFcmToken(authUser.uid);
});
