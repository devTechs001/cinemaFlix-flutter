import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool _isChecking = false;
  Timer? _checkTimer;
  static const _checkInterval = Duration(seconds: 15);

  bool get isOnline => _isOnline;

  ConnectivityService() {
    _startMonitoring();
  }

  void _startMonitoring() {
    _checkConnection();
    _checkTimer = Timer.periodic(_checkInterval, (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    } on SocketException {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    } on TimeoutException {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> checkNow() async {
    await _checkConnection();
    return _isOnline;
  }

  Future<void> waitForConnection() async {
    if (_isOnline) return;
    final completer = Completer<void>();
    void listener() {
      if (_isOnline) {
        completer.complete();
        removeListener(listener);
      }
    }
    addListener(listener);
    await completer.future;
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
