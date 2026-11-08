import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie.dart';
import '../models/movie_catalogue.dart';
import 'supabase_service.dart';

/// Live movie catalogue.
///
/// Starts instantly with the bundled [movieCatalogue], then (when
/// Supabase is available) replaces it with rows from the `movies` table
/// and subscribes to Realtime so catalogue changes made in the
/// Supabase dashboard appear in the app without a restart.
/// Falls back silently to the bundled catalogue on any error.
class MovieService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  List<Movie> _movies = movieCatalogue;
  RealtimeChannel? _channel;
  bool _started = false;

  List<Movie> get movies => List.unmodifiable(_movies);

  Movie? byId(String id) {
    for (final m in _movies) {
      if (m.id == id) return m;
    }
    return getMovieById(id);
  }

  Future<void> load() async {
    if (_started || !_supabase.isInitialized) return;
    _started = true;
    await _fetchRemote();
    _channel = _supabase.channel('public:movies')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        table: 'movies',
        callback: (_) => _fetchRemote(),
      )
      ..subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('MovieService: realtime catalogue subscribed');
        }
      });
  }

  Future<void> _fetchRemote() async {
    try {
      final rows = await _supabase
          .table('movies')
          .select()
          .order('rating', ascending: false);
      if (rows.isEmpty) return;
      _movies = rows.map((e) => Movie.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('MovieService: remote catalogue unavailable: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
