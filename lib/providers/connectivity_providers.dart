import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/services/connectivity_service.dart';

/// Singleton ConnectivityService instance.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityPlusService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of connectivity state changes.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Current connectivity state (synchronous read).
final isOnlineProvider = Provider<bool>((ref) {
  // Use the latest stream value if available, otherwise fall back to sync check.
  final streamValue = ref.watch(connectivityStreamProvider).valueOrNull;
  if (streamValue != null) return streamValue;
  return ref.watch(connectivityServiceProvider).isOnline;
});
