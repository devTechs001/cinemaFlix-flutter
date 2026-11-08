import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DevService extends ChangeNotifier {
  bool _maintenanceMode = false;
  bool _devModeEnabled = false;
  bool _verboseLogging = false;
  bool _bypassAuth = false;
  bool _showFps = false;
  bool _unlockAll = false;
  final List<String> _eventLog = [];

  bool get maintenanceMode => _maintenanceMode;
  bool get devModeEnabled => _devModeEnabled;
  bool get verboseLogging => _verboseLogging;
  bool get bypassAuth => _bypassAuth;
  bool get showFps => _showFps;

  /// True when dev mode is on **and** all locked screens are unlocked.
  bool get hasFullAccess => _devModeEnabled && _unlockAll;

  /// Current state of the "Unlock All Features" toggle.
  bool get unlockAll => _unlockAll;

  List<String> get eventLog => List.unmodifiable(_eventLog);

  /// Developer access code. Configured via `DEV_ACCESS_CODE` in `.env`
  /// (or `--dart-define`); the fallback is a rotated demo value — real
  /// protection for admin endpoints stays server-side (`ADMIN_CODE`).
  String get accessCode {
    const fromDefine = String.fromEnvironment('DEV_ACCESS_CODE');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (dotenv.isInitialized) {
      final env = dotenv.maybe['DEV_ACCESS_CODE']?.trim();
      if (env != null && env.isNotEmpty) return env;
    }
    return 'cinemaflix-dev';
  }

  /// Validates [code] against the configured access code and, on
  /// success, activates dev mode with full access. Returns the result.
  bool authenticate(String code) {
    if (code.isEmpty || code != accessCode) {
      logEvent('Dev access denied');
      notifyListeners();
      return false;
    }
    activateDevMode();
    if (!_unlockAll) {
      _unlockAll = true;
      logEvent('Full access unlocked');
    }
    notifyListeners();
    return true;
  }

  /// Grants dev mode + full access without a code (hidden logo-tap
  /// gesture on the auth screen — a client-side convenience only).
  void grantFullAccess() {
    activateDevMode();
    if (!_unlockAll) {
      _unlockAll = true;
      logEvent('Full access granted via logo gesture');
      notifyListeners();
    }
  }

  void toggleUnlockAll() {
    _unlockAll = !_unlockAll;
    logEvent('Unlock all: ${_unlockAll ? "ON" : "OFF"}');
    notifyListeners();
  }

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
