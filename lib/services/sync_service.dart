import 'package:flutter/foundation.dart';

import '../models/movie.dart';
import 'local_db_service.dart';
import 'movie_service.dart';
import 'supabase_service.dart';

/// Sign-in data sync — reconciles local-first SQLite data with the
/// signed-in user's Supabase rows.
///
/// Strategy: **push** local favorites / watchlist / watch history that
/// the cloud does not have yet, then **pull** cloud rows the device is
/// missing. Every step is best-effort — failures are logged and never
/// thrown, and on-device data is never deleted by a failed sync.
class SyncService {
  bool _syncedOnce = false;

  bool get syncedOnce => _syncedOnce;

  Future<void> initialize() async {}

  /// Called after any successful sign-in (email, OAuth, phone OTP).
  Future<void> signInSync() async {
    final supa = SupabaseService();
    if (!supa.isInitialized) return;
    final user = supa.auth.currentUser;
    if (user == null || _syncedOnce) return;
    _syncedOnce = true;

    final local = LocalDbService();
    await _pushList(user.id, 'favorites', await local.getFavorites());
    await _pushList(user.id, 'watchlist', await local.getWatchlist());
    await _pushHistory(user.id);

    await _pullList(user.id, 'favorites', local);
    await _pullList(user.id, 'watchlist', local);
    await _pullHistory(user.id);
  }

  // ---------------------------------------------------------------- push

  Future<void> _pushList(
    String userId,
    String table,
    List<Movie> movies,
  ) async {
    if (movies.isEmpty) return;
    final supa = SupabaseService();
    try {
      final remote =
          await supa.table(table).select('movie_id').eq('user_id', userId)
              as List;
      final have = remote.map((r) => r['movie_id']?.toString()).toSet();
      for (final m in movies) {
        if (have.contains(m.id)) continue;
        await supa.table(table).insert({
          'user_id': userId,
          'movie_id': m.id,
          'title': m.title,
          'genre': m.genre,
          'year': m.year,
          'rating': m.rating,
          'poster_url': m.posterUrl,
        });
      }
    } catch (e) {
      debugPrint('SyncService: push $table failed: $e');
    }
  }

  Future<void> _pushHistory(String userId) async {
    final supa = SupabaseService();
    try {
      final rows = await LocalDbService().getWatchHistory();
      if (rows.isEmpty) return;
      final remote =
          await supa
                  .table('watch_history')
                  .select('movie_id')
                  .eq('user_id', userId)
              as List;
      final have = remote.map((r) => r['movie_id']?.toString()).toSet();
      for (final row in rows) {
        final movieId = row['movie_id']?.toString() ?? '';
        if (movieId.isEmpty || have.contains(movieId)) continue;
        await supa.table('watch_history').insert({
          'user_id': userId,
          'movie_id': movieId,
          'progress': (row['progress'] as num?)?.toDouble() ?? 0.0,
        });
      }
    } catch (e) {
      debugPrint('SyncService: push watch_history failed: $e');
    }
  }

  // ---------------------------------------------------------------- pull

  Future<void> _pullList(
    String userId,
    String table,
    LocalDbService local,
  ) async {
    try {
      final supa = SupabaseService();
      final remote =
          await supa.table(table).select().eq('user_id', userId) as List;
      if (remote.isEmpty) return;
      final movies = remote
          .map((row) => Movie.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
      final localMovies = table == 'favorites'
          ? await local.getFavorites()
          : await local.getWatchlist();
      final have = localMovies.map((m) => m.id).toSet();
      for (final m in movies) {
        if (m.id.isEmpty || have.contains(m.id)) continue;
        if (table == 'favorites') {
          await local.toggleFavorite(
            m.id,
            title: m.title,
            genre: m.genre,
            year: m.year,
            rating: m.rating,
            posterUrl: m.posterUrl,
          );
        } else {
          await local.toggleWatchlist(
            m.id,
            title: m.title,
            genre: m.genre,
            year: m.year,
            rating: m.rating,
            posterUrl: m.posterUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('SyncService: pull $table failed: $e');
    }
  }

  Future<void> _pullHistory(String userId) async {
    try {
      final supa = SupabaseService();
      final remote =
          await supa
                  .table('watch_history')
                  .select('movie_id, progress')
                  .eq('user_id', userId)
              as List;
      if (remote.isEmpty) return;
      final local = LocalDbService();
      final existing = await local.getWatchHistory();
      final have = existing.map((r) => r['movie_id']?.toString()).toSet();
      for (final row in remote) {
        final movieId = row['movie_id']?.toString() ?? '';
        if (movieId.isEmpty || have.contains(movieId)) continue;
        final progress = (row['progress'] as num?)?.toDouble() ?? 0.0;
        final title = movieService.byId(movieId)?.title ?? movieId;
        final duration = _parseDurationSeconds(title);
        await local.saveWatchProgress(
          movieId,
          title: title,
          progress: progress,
          positionSeconds: (duration * progress).round(),
          durationSeconds: duration,
        );
      }
    } catch (e) {
      debugPrint('SyncService: pull watch_history failed: $e');
    }
  }

  /// Parses durations like `2h 46m` / `90m` into seconds (best effort).
  int _parseDurationSeconds(String text) {
    var seconds = 0;
    final h = RegExp(r'(\d+)\s*h').firstMatch(text);
    final m = RegExp(r'(\d+)\s*m').firstMatch(text);
    if (h != null) seconds += int.parse(h.group(1)!) * 3600;
    if (m != null) seconds += int.parse(m.group(1)!) * 60;
    return seconds;
  }
}
