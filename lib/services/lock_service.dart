import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vault PIN lock.
///
/// Persists the user's vault PIN (default `1234` until changed) and
/// tracks the unlock state for the current session. The Vault screen
/// verifies every attempt through [verifyPin] so a changed PIN is
/// honoured everywhere instead of a hard-coded comparison.
class LockService extends ChangeNotifier {
  static const String pinStorageKey = 'vault_pin';
  static const String defaultPin = '1234';

  String _pin = defaultPin;
  bool _hasCustomPin = false;
  bool _sessionUnlocked = false;

  /// True once the user has set their own PIN (vs the factory default).
  bool get hasCustomPin => _hasCustomPin;

  /// True after a successful [verifyPin] this session.
  bool get sessionUnlocked => _sessionUnlocked;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pin = prefs.getString(pinStorageKey) ?? defaultPin;
      _hasCustomPin = prefs.containsKey(pinStorageKey);
    } catch (e) {
      debugPrint('LockService: preferences unavailable, default PIN active: $e');
    }
  }

  /// Verifies [pin]; on success marks the session unlocked.
  bool verifyPin(String pin) {
    final ok = pin == _pin;
    if (ok && !_sessionUnlocked) {
      _sessionUnlocked = true;
      notifyListeners();
    }
    return ok;
  }

  /// Persists a new vault PIN.
  Future<void> setPin(String pin) async {
    if (pin.isEmpty) return;
    _pin = pin;
    _hasCustomPin = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pinStorageKey, pin);
    } catch (e) {
      debugPrint('LockService: could not persist PIN: $e');
    }
  }

  /// Re-locks the vault for the rest of the session.
  void lock() {
    if (_sessionUnlocked) {
      _sessionUnlocked = false;
      notifyListeners();
    }
  }
}

final LockService lockService = LockService();
