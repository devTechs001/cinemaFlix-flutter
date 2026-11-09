import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central configuration for the Node/Express backend API.
///
/// The backend mounts every route under `/api` (see `backend/index.js`),
/// so [apiPath] produces absolute URLs such as
/// `http://localhost:3000/api/auth/login`.
class ApiConfig {
  ApiConfig._();

  static const String _defaultBaseUrl = 'http://localhost:3000';

  /// Backend origin with no trailing slash, from `BACKEND_URL` in `.env`
  /// (falls back to `http://localhost:3000`).
  static String get baseUrl {
    var url = _defaultBaseUrl;
    if (dotenv.isInitialized) {
      final env = dotenv.env['BACKEND_URL']?.trim();
      if (env != null && env.isNotEmpty) url = env;
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Absolute URL for a backend route (adds the `/api` mount prefix).
  static String apiPath(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return '$baseUrl/api$p';
  }

  /// Resolve a stored media path into an absolute URL. Relative paths are
  /// served by the backend origin; absolute URLs pass through untouched.
  static String resolveUrl(String url) {
    if (url.startsWith('/')) return '$baseUrl$url';
    return url;
  }
}
