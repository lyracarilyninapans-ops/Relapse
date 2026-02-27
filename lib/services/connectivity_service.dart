import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity for UI indicators.
/// Data sync is handled automatically by Firestore's offline persistence.
abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get onConnectivityChanged;
  Future<void> initialize();
  void dispose();
}

/// Implementation using connectivity_plus.
class ConnectivityPlusService implements ConnectivityService {
  final Connectivity _connectivity;
  bool _isOnline = true;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  final _controller = StreamController<bool>.broadcast();

  ConnectivityPlusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _hasConnection(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
