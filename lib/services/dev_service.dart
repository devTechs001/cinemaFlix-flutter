import 'package:flutter/foundation.dart';

class DevService extends ChangeNotifier {
  bool _maintenanceMode = false;
  bool _devModeEnabled = false;
  bool _verboseLogging = false;
  bool _bypassAuth = false;
  bool _showFps = false;
  final List<String> _eventLog = [];

  bool get maintenanceMode => _maintenanceMode;
  bool get devModeEnabled => _devModeEnabled;
  bool get verboseLogging => _verboseLogging;
  bool get bypassAuth => _bypassAuth;
  bool get showFps => _showFps;
  List<String> get eventLog => List.unmodifiable(_eventLog);

  /// Enables dev mode. Callers must verify the signed-in user is an
  /// admin first (see DevPanelScreen) — there is deliberately no
  /// hardcoded access code in the client. Real authorization must
  /// still be enforced server-side (Supabase RLS / roles).
  void activateDevMode() {
    _devModeEnabled = true;
    logEvent('Dev mode activated');
    notifyListeners();
  }

  void toggleMaintenanceMode() {
    _maintenanceMode = !_maintenanceMode;
    logEvent('Maintenance mode: ${_maintenanceMode ? "ON" : "OFF"}');
    notifyListeners();
  }

  void toggleVerboseLogging() {
    _verboseLogging = !_verboseLogging;
    notifyListeners();
  }

  void toggleBypassAuth() {
    _bypassAuth = !_bypassAuth;
    logEvent('Bypass auth: ${_bypassAuth ? "ON" : "OFF"}');
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
    logEvent('Dev mode deactivated');
    notifyListeners();
  }

  void logEvent(String event) {
    final timestamp = DateTime.now().toIso8601String().split('T').last.split('.').first;
    _eventLog.insert(0, '[$timestamp] $event');
  }
}
