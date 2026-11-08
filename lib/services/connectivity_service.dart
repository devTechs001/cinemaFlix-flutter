import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum ConnectionStrength { none, weak, moderate, strong, excellent }
enum ConnectionType { unknown, wifi, mobile, ethernet }

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool _isChecking = false;
  Timer? _checkTimer;
  static const _checkInterval = Duration(seconds: 15);
  ConnectionStrength _strength = ConnectionStrength.excellent;
  ConnectionType _type = ConnectionType.unknown;
  int _latencyMs = 0;
  List<double> _recentLatencies = [];

  bool get isOnline => _isOnline;
  ConnectionStrength get strength => _strength;
  ConnectionType get type => _type;
  int get latencyMs => _latencyMs;

  String get strengthLabel {
    switch (_strength) {
      case ConnectionStrength.excellent: return 'Excellent';
      case ConnectionStrength.strong: return 'Strong';
      case ConnectionStrength.moderate: return 'Moderate';
      case ConnectionStrength.weak: return 'Weak';
      case ConnectionStrength.none: return 'Disconnected';
    }
  }

  String get typeLabel {
    switch (_type) {
      case ConnectionType.wifi: return 'WiFi';
      case ConnectionType.mobile: return 'Mobile Data';
      case ConnectionType.ethernet: return 'Ethernet';
      case ConnectionType.unknown: return 'Unknown';
    }
  }

  double get strengthPercent {
    switch (_strength) {
      case ConnectionStrength.excellent: return 1.0;
      case ConnectionStrength.strong: return 0.75;
      case ConnectionStrength.moderate: return 0.5;
      case ConnectionStrength.weak: return 0.25;
      case ConnectionStrength.none: return 0.0;
    }
  }

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
    final start = DateTime.now();
    bool becameOnline = false;
    bool becameOffline = false;
    bool strengthChanged = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      _latencyMs = DateTime.now().difference(start).inMilliseconds;
      _recentLatencies.add(_latencyMs.toDouble());
      if (_recentLatencies.length > 5) _recentLatencies.removeAt(0);
      final avgLatency = _recentLatencies.isEmpty
          ? _latencyMs.toDouble()
          : _recentLatencies.reduce((a, b) => a + b) / _recentLatencies.length;
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (online) {
        final newStrength = avgLatency < 50
            ? ConnectionStrength.excellent
            : avgLatency < 120
                ? ConnectionStrength.strong
                : avgLatency < 300
                    ? ConnectionStrength.moderate
                    : ConnectionStrength.weak;
        strengthChanged = newStrength != _strength;
        _strength = newStrength;
        if (!_isOnline) becameOnline = true;
        try {
          final interfaces = await NetworkInterface.list();
          _type = interfaces.any((i) => i.name.contains('wlan') || i.name.contains('wifi'))
              ? ConnectionType.wifi
              : interfaces.any((i) => i.name.contains('eth'))
                  ? ConnectionType.ethernet
                  : ConnectionType.mobile;
        } catch (_) {
          _type = ConnectionType.unknown;
        }
      } else {
        _strength = ConnectionStrength.none;
        if (_isOnline) becameOffline = true;
      }
    } on SocketException {
      _strength = ConnectionStrength.none;
      if (_isOnline) becameOffline = true;
    } on TimeoutException {
      _strength = ConnectionStrength.none;
      if (_isOnline) becameOffline = true;
    } finally {
      if (becameOnline) _isOnline = true;
      if (becameOffline) _isOnline = false;
      if (becameOnline || becameOffline || strengthChanged) {
        notifyListeners();
      }
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
