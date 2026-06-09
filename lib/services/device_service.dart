import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DeviceInfo {
  final String id;
  final String name;
  final String platform;
  final String version;
  final bool isOnline;
  final DateTime lastSeen;
  final bool isCurrent;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    required this.version,
    required this.isOnline,
    required this.lastSeen,
    this.isCurrent = false,
  });
}

class DeviceService extends ChangeNotifier {
  final List<DeviceInfo> _devices = [];
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  List<DeviceInfo> get devices => List.unmodifiable(_devices);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _devices.add(DeviceInfo(
      id: 'current-${DateTime.now().millisecondsSinceEpoch}',
      name: 'My ${defaultTargetPlatform.name}',
      platform: defaultTargetPlatform.name,
      version: '1.0.0',
      isOnline: true,
      lastSeen: DateTime.now(),
      isCurrent: true,
    ));
    _isInitialized = true;
    _startHeartbeat();
    notifyListeners();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final current = _devices.indexWhere((d) => d.isCurrent);
      if (current >= 0) {
        _devices[current] = DeviceInfo(
          id: _devices[current].id,
          name: _devices[current].name,
          platform: _devices[current].platform,
          version: _devices[current].version,
          isOnline: true,
          lastSeen: DateTime.now(),
          isCurrent: true,
        );
        notifyListeners();
      }
    });
  }

  void simulateDeviceConnected(String name, String platform) {
    _devices.add(DeviceInfo(
      id: 'device-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      platform: platform,
      version: '1.0.0',
      isOnline: true,
      lastSeen: DateTime.now(),
    ));
    notifyListeners();
  }

  void toggleDeviceOnline(String id) {
    final idx = _devices.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final d = _devices[idx];
    _devices[idx] = DeviceInfo(
      id: d.id,
      name: d.name,
      platform: d.platform,
      version: d.version,
      isOnline: !d.isOnline,
      lastSeen: d.isOnline ? d.lastSeen : DateTime.now(),
      isCurrent: d.isCurrent,
    );
    notifyListeners();
  }

  void removeDevice(String id) {
    _devices.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

final deviceService = DeviceService();
