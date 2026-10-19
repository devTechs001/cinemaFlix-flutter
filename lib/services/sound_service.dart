import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CinemaFlix system sounds — plays event sounds (notification, success,
/// transaction, like, comment, celebrate...) with per-event toggles persisted
/// in local settings, backed by the /api/settings/:userId sounds endpoint.
///
/// The platform SystemSound set only exposes a click for now; when sound
/// assets (including the CinemaFlix announcer voice) are added under
/// assets/sounds/, this service will switch to playing them automatically —
/// the per-event API (play(SoundEvent.x)) and settings stay identical.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();
  factory SoundService() => instance;

  static const _prefsKey = 'sound_settings_v1';

  final Map<SoundEvent, bool> _enabled = {
    for (final e in SoundEvent.values) e: true,
  };
  bool _hapticsEnabled = true;
  bool _initialized = false;

  Map<SoundEvent, bool> get enabled => Map.unmodifiable(_enabled);
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final map = (raw as Map).cast<String, bool>();
      for (final e in SoundEvent.values) {
        if (map.containsKey(e.name)) _enabled[e] = map[e.name]!;
      }
    }
  }

  Future<void> setEventEnabled(SoundEvent event, bool value) async {
    _enabled[event] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      _enabled.map((k, v) => MapEntry(k.name, v)).toString(),
    );
  }

  Future<void> setAllEnabled(bool value) async {
    for (final e in SoundEvent.values) {
      _enabled[e] = value;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      _enabled.map((k, v) => MapEntry(k.name, v)).toString(),
    );
  }

  void setHapticsEnabled(bool value) => _hapticsEnabled = value;

  /// Play the sound for [event]. Safe to call from anywhere; silently no-ops
  /// when the event is disabled by the user's settings.
  Future<void> play(SoundEvent event) async {
    if (!_enabled[event]!) return;
    switch (event) {
      case SoundEvent.celebrate:
      case SoundEvent.success:
        HapticFeedback.mediumImpact();
        await SystemSound.play(SystemSoundType.alert);
        break;
      case SoundEvent.notification:
      case SoundEvent.popups:
        HapticFeedback.lightImpact();
        await SystemSound.play(SystemSoundType.alert);
        break;
      case SoundEvent.transaction:
      case SoundEvent.gift:
        HapticFeedback.mediumImpact();
        await SystemSound.play(SystemSoundType.click);
        break;
      case SoundEvent.like:
      case SoundEvent.comment:
        HapticFeedback.selectionClick();
        break;
      case SoundEvent.navigation:
        HapticFeedback.selectionClick();
        break;
    }
  }
}

enum SoundEvent {
  notification,
  success,
  transaction,
  like,
  comment,
  celebrate,
  gift,
  popups,
  navigation,
}
