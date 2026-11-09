import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'sound_service.dart';

/// User preferences mirrored to `GET/PUT /api/settings/:userId`.
///
/// Local SharedPreferences is the source of truth while offline; each
/// change is patched to the backend when a signed-in user id is bound.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();
  factory SettingsService() => instance;

  static const _prefsKey = 'user_settings_v1';
  static const _timeout = Duration(seconds: 8);

  String? _userId;
  String? _token;

  bool hdStreaming = true;
  bool autoPlay = true;
  bool autoplayNext = true;
  bool subtitles = true;
  bool dolbyAtmos = false;
  bool backgroundPlay = false;
  bool gestureControls = true;
  String streamingQuality = 'Auto';
  String downloadQuality = 'HD';
  bool downloadOnWifi = true;
  bool smartDownloads = false;
  bool dataSaver = false;

  bool privateAccount = false;
  bool socialShare = true;
  bool parentalControls = false;

  bool pushNotifications = true;
  bool movieAlerts = true;
  bool chatAlerts = true;
  bool socialAlerts = true;
  bool liveAlerts = true;

  String language = 'English';
  String region = 'United States';

  String bio = 'Movie enthusiast 🎬 | 100+ films watched';
  String website = '';
  String location = '';
  String avatarEmoji = '';

  bool _loaded = false;
  bool get loaded => _loaded;

  void bind({String? userId, String? token}) {
    final changed = userId != _userId;
    _userId = userId;
    _token = token;
    if (changed && userId != null && userId.isNotEmpty) {
      _fromRemote();
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Future<void> load() async {
    await _fromPrefs();
    _loaded = true;
    notifyListeners();
    await _fromRemote();
  }

  Future<void> _fromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) _apply(map);
    } catch (e) {
      debugPrint('SettingsService prefs: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(toJson()));
    } catch (e) {
      debugPrint('SettingsService persist: $e');
    }
  }

  Future<void> _fromRemote() async {
    final id = _userId;
    if (id == null || id.isEmpty) return;
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.apiPath('/settings/$id')), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      if (body is! Map) return;
      _apply(Map<String, dynamic>.from(body));
      final sounds = body['sounds'];
      if (sounds is Map) soundService.applyFromMap(sounds);
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsService GET: $e');
    }
  }

  Future<void> patch(void Function() mutate) async {
    mutate();
    notifyListeners();
    await _persist();
    await _putRemote(toJson());
  }

  Future<void> syncSounds() async {
    await _putRemote({
      'sounds': {
        for (final e in soundService.enabled.entries) e.key.name: e.value,
      },
    });
  }

  Future<void> _putRemote(Map<String, dynamic> body) async {
    final id = _userId;
    if (id == null || id.isEmpty) return;
    try {
      final res = await http
          .put(
            Uri.parse(ApiConfig.apiPath('/settings/$id')),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('SettingsService PUT ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('SettingsService PUT: $e');
    }
  }

  void _apply(Map<String, dynamic> raw) {
    final playback = _nested(raw, 'playback');
    final privacy = _nested(raw, 'privacy');
    final notifications = _nested(raw, 'notifications');
    final content = _nested(raw, 'content');
    final profile = _nested(raw, 'profile');

    hdStreaming = _bool(playback, 'hdStreaming', hdStreaming);
    autoPlay = _bool(playback, 'autoPlay', autoPlay);
    autoplayNext = _bool(playback, 'autoplayNext', autoplayNext);
    subtitles = _bool(playback, 'subtitles', subtitles);
    dolbyAtmos = _bool(playback, 'dolbyAtmos', dolbyAtmos);
    backgroundPlay = _bool(playback, 'backgroundPlay', backgroundPlay);
    gestureControls = _bool(playback, 'gestureControls', gestureControls);
    streamingQuality = _str(playback, 'streamingQuality', streamingQuality);
    downloadQuality = _str(playback, 'downloadQuality', downloadQuality);
    downloadOnWifi = _bool(playback, 'downloadOnWifi', downloadOnWifi);
    smartDownloads = _bool(playback, 'smartDownloads', smartDownloads);
    dataSaver = _bool(playback, 'dataSaver', dataSaver);

    privateAccount = _bool(privacy, 'privateAccount', privateAccount);
    socialShare = _bool(privacy, 'socialShare', socialShare);
    parentalControls = _bool(privacy, 'parentalControls', parentalControls);

    pushNotifications = _bool(notifications, 'push', pushNotifications);
    movieAlerts = _bool(notifications, 'movies', movieAlerts);
    chatAlerts = _bool(notifications, 'chat', chatAlerts);
    socialAlerts = _bool(notifications, 'social', socialAlerts);
    liveAlerts = _bool(notifications, 'live', liveAlerts);

    language = _str(content, 'language', language);
    region = _str(content, 'region', region);

    bio = _str(profile, 'bio', bio);
    website = _str(profile, 'website', website);
    location = _str(profile, 'location', location);
    avatarEmoji = _str(profile, 'avatarEmoji', avatarEmoji);
  }

  Map<String, dynamic> _nested(Map<String, dynamic> raw, String key) {
    final v = raw[key];
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return raw;
  }

  bool _bool(Map<String, dynamic> m, String k, bool fallback) {
    final v = m[k];
    if (v is bool) return v;
    return fallback;
  }

  String _str(Map<String, dynamic> m, String k, String fallback) {
    if (!m.containsKey(k)) return fallback;
    final v = m[k];
    if (v == null) return fallback;
    return v.toString();
  }

  Map<String, dynamic> toJson() => {
        'playback': {
          'hdStreaming': hdStreaming,
          'autoPlay': autoPlay,
          'autoplayNext': autoplayNext,
          'subtitles': subtitles,
          'dolbyAtmos': dolbyAtmos,
          'backgroundPlay': backgroundPlay,
          'gestureControls': gestureControls,
          'streamingQuality': streamingQuality,
          'downloadQuality': downloadQuality,
          'downloadOnWifi': downloadOnWifi,
          'smartDownloads': smartDownloads,
          'dataSaver': dataSaver,
        },
        'privacy': {
          'privateAccount': privateAccount,
          'socialShare': socialShare,
          'parentalControls': parentalControls,
        },
        'notifications': {
          'push': pushNotifications,
          'movies': movieAlerts,
          'chat': chatAlerts,
          'social': socialAlerts,
          'live': liveAlerts,
        },
        'content': {
          'language': language,
          'region': region,
        },
        'profile': {
          'bio': bio,
          'website': website,
          'location': location,
          'avatarEmoji': avatarEmoji,
        },
        'sounds': {
          for (final e in soundService.enabled.entries) e.key.name: e.value,
        },
      };
}
