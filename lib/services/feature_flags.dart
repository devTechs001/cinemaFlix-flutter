import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Platform feature flags published by the backend (`GET /api/app/config`).
///
/// The admin control room flips these (see Admin → Features tab); this
/// service keeps the app-side copy so nav entries, tabs and screens can
/// hide or disable features the admin turned off. Defaults to everything
/// enabled, so an offline backend never locks users out of the app.
class FeatureFlagsService extends ChangeNotifier {
  static const Set<String> knownFlags = {
    'ecommerce',
    'gaming',
    'ads',
    'dating',
    'live',
    'shorts',
    'walletPoints',
    'chat',
  };

  Map<String, bool> _flags = {for (final f in knownFlags) f: true};
  bool _loaded = false;
  bool _loading = false;

  bool get loaded => _loaded;
  bool get loading => _loading;

  /// Whether [key] is enabled. Unknown keys default to enabled.
  bool isEnabled(String key) => _flags[key] ?? true;

  Map<String, bool> get flags => Map.unmodifiable(_flags);

  /// Fetches fresh flags from the backend. Never throws; a failed load
  /// keeps the previous values.
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.apiPath('/app/config')))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = data['featureFlags'];
        if (raw is Map<String, dynamic>) {
          final next = {for (final f in knownFlags) f: true};
          for (final key in knownFlags) {
            final v = raw[key];
            if (v is bool) next[key] = v;
          }
          _flags = next;
          _loaded = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('FeatureFlagsService: load failed: $e');
    } finally {
      _loading = false;
    }
  }
}
