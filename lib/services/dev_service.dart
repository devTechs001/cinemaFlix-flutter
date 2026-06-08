import 'package:flutter/foundation.dart';

class DevService extends ChangeNotifier {
  bool _maintenanceMode = false;
  bool _devModeEnabled = false;
  bool _verboseLogging = false;
  bool _bypassAuth = false;
  bool _showFps = false;
  final String _devAccessCode = 'admin123';
  final List<String> _eventLog = [];

  bool get maintenanceMode => _maintenanceMode;
  bool get devModeEnabled => _devModeEnabled;
  bool get verboseLogging => _verboseLogging;
  bool get bypassAuth => _bypassAuth;
  bool get showFps => _showFps;
  List<String> get eventLog => List.unmodifiable(_eventLog);

  bool authenticate(String code) {
    if (code == _devAccessCode) {
      _devModeEnabled = true;
      _logEvent('Dev mode activated');
      notifyListeners();
      return true;
    }
    _logEvent('Failed dev auth attempt');
    return false;
  }

  void toggleMaintenanceMode() {
    _maintenanceMode = !_maintenanceMode;
    _logEvent('Maintenance mode: ${_maintenanceMode ? "ON" : "OFF"}');
    notifyListeners();
  }

  void toggleVerboseLogging() {
    _verboseLogging = !_verboseLogging;
    notifyListeners();
  }

  void toggleBypassAuth() {
    _bypassAuth = !_bypassAuth;
    _logEvent('Bypass auth: ${_bypassAuth ? "ON" : "OFF"}');
    notifyListeners();
  }

  void toggleShowFps() {
    _showFps = !_showFps;
    notifyListeners();
  }

  void clearLogs() {
    _eventLog.clear();
    notifyListeners();
  }

  void deactivateDevMode() {
    _devModeEnabled = false;
    _logEvent('Dev mode deactivated');
    notifyListeners();
  }

  void logEvent(String event) {
    final timestamp = DateTime.now().toIso8601String().split('T').last.split('.').first;
    _eventLog.insert(0, '[$timestamp] $event');
  }

  void _logEvent(String event) {
    final timestamp = DateTime.now().toIso8601String().split('T').last.split('.').first;
    _eventLog.insert(0, '[$timestamp] $event');
  }
}
