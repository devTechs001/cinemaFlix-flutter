import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;
  SupabaseService._();

  bool _initialized = false;
  String? _initError;

  bool get isInitialized => _initialized;
  String? get initError => _initError;

  SupabaseClient get client => Supabase.instance.client;

  /// Loads config from `.env`, falling back to `--dart-define` values.
  /// Never throws: on failure [isInitialized] stays false and [initError]
  /// describes the problem so the app can show a config error screen
  /// instead of crashing before the first frame.
  Future<void> initialize() async {
    try {
      String? envUrl;
      String? envKey;
      try {
        await dotenv.load();
        envUrl = dotenv.env['SUPABASE_URL'];
        envKey = dotenv.env['SUPABASE_ANON_KEY'];
      } catch (_) {
        // .env missing/unreadable — fall through to --dart-define values.
      }
      final url = _firstNonEmpty(
        envUrl,
        const String.fromEnvironment('SUPABASE_URL'),
      );
      final key = _firstNonEmpty(
        envKey,
        const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
      if (url == null || key == null) {
        throw StateError(
          'Missing SUPABASE_URL / SUPABASE_ANON_KEY. '
          'Add them to .env (see .env.example) or pass --dart-define.',
        );
      }
      await Supabase.initialize(url: url, publishableKey: key);
      _initialized = true;
    } catch (e) {
      _initError = e.toString();
      _initialized = false;
      debugPrint('Supabase init failed: $e');
    }
  }

  String? _firstNonEmpty(String? a, String b) {
    if (a != null && a.isNotEmpty) return a;
    if (b.isNotEmpty) return b;
    return null;
  }

  GoTrueClient get auth => client.auth;
  SupabaseQueryBuilder table(String name) => client.from(name);
  RealtimeChannel channel(String name) => client.channel(name);
}
