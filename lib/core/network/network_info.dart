import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connectivity manager: monitors Wi-Fi, Cellular, and offline status.
class NetworkInfo extends ChangeNotifier {
  NetworkInfo({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  Future<void> _init() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (_) {
      _isOnline = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final bool online = results.any(
      (ConnectivityResult r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );

    if (_isOnline != online) {
      _isOnline = online;
      debugPrint(online
          ? '🟢 [Network] Back Online'
          : '🔴 [Network] Connection Lost — Offline Mode');
      notifyListeners();
    }
  }

  /// One-off connectivity check
  Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final bool online = results.any(
        (ConnectivityResult r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.vpn,
      );
      _isOnline = online;
      return online;
    } catch (_) {
      return true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
