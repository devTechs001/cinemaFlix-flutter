import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CinemaFlix system sounds — plays event sounds (notification, success,
/// transaction, like, comment, celebrate...) with per-event toggles persisted
/// in local settings, backed by the /api/settings/:userId sounds endpoint.
///
/// Real synthesized WAV assets live under assets/sounds/ and are mapped
/// one-to-one to events. To brand the app further, drop a recorded announcer
/// voice at assets/sounds/open.wav (the splash boot sound) — the API and
/// settings stay identical.
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

  /// Small pool of players so overlapping short sounds don't cut each other.
  final List<AudioPlayer> _players = [];
  int _nextPlayer = 0;

  static const Map<SoundEvent, String> _assets = {
    SoundEvent.notification: 'notification',
    SoundEvent.popups: 'popups',
    SoundEvent.success: 'success',
    SoundEvent.transaction: 'transaction',
    SoundEvent.like: 'like',
    SoundEvent.comment: 'comment',
    SoundEvent.celebrate: 'celebrate',
    SoundEvent.gift: 'gift',
    SoundEvent.navigation: 'navigation',
  };

  /// Splash/boot chime played from main.dart at startup.
  static const String bootAsset = 'open';

  Map<SoundEvent, bool> get enabled => Map.unmodifiable(_enabled);
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) applyFromMap(decoded);
      } catch (_) {}
    }
  }

  void applyFromMap(Map map) {
    if (map.isEmpty) return;
    for (final e in SoundEvent.values) {
      final v = map[e.name];
      if (v is bool) _enabled[e] = v;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({for (final e in _enabled.entries) e.key.name: e.value}),
    );
  }

  Future<void> setEventEnabled(SoundEvent event, bool value) async {
    _enabled[event] = value;
    await _persist();
  }

  Future<void> setAllEnabled(bool value) async {
    for (final e in SoundEvent.values) {
      _enabled[e] = value;
    }
    await _persist();
  }

  void setHapticsEnabled(bool value) => _hapticsEnabled = value;

  void _haptic(SoundEvent event) {
    if (!_hapticsEnabled) return;
    switch (event) {
      case SoundEvent.celebrate:
      case SoundEvent.success:
      case SoundEvent.transaction:
      case SoundEvent.gift:
        HapticFeedback.mediumImpact();
        break;
      case SoundEvent.notification:
      case SoundEvent.popups:
        HapticFeedback.lightImpact();
        break;
      case SoundEvent.like:
      case SoundEvent.comment:
      case SoundEvent.navigation:
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// Play an asset by [assetName] (file assets/sounds/<assetName>.wav).
  Future<void> playAsset(String assetName) async {
    try {
      final player = _players.isNotEmpty
          ? _players[_nextPlayer++ % _players.length]
          : null;
      final p = player ?? await _createPlayer();
      await p.stop();
      await p.play(AssetSource('sounds/$assetName.wav'));
    } catch (e) {
      // Asset playback unavailable (older platform/web restrictions) — fall
      // through to the platform click so feedback is never fully lost.
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  Future<AudioPlayer> _createPlayer() async {
    final p = AudioPlayer();
    _players.add(p);
    return p;
  }

  /// Play the sound for [event]. Safe to call from anywhere; silently no-ops
  /// when the event is disabled by the user's settings.
  Future<void> play(SoundEvent event) async {
    if (!_enabled[event]!) return;
    _haptic(event);
    final asset = _assets[event];
    if (asset != null) {
      await playAsset(asset);
      return;
    }
    await SystemSound.play(SystemSoundType.click);
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
