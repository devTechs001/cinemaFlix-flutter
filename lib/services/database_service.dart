import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/review_model.dart';
import 'local_db_service.dart';
import 'supabase_service.dart';

/// Favorites/watchlist are **local-first**: every write goes to the
/// on-device SQLite database ([LocalDbService]) so they work offline
/// and for guests, and is then mirrored to Supabase when a user is
/// signed in. Reads prefer Supabase (refreshing the local cache) and
/// fall back to SQLite on any error.
class DatabaseService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final LocalDbService _local = LocalDbService();

  bool get _isAuthed =>
      _supabase.isInitialized && _supabase.auth.currentUser != null;

  Movie _fromRow(Map<String, dynamic> map) {
    // The movie's identity is `movie_id`, not the row's own `id` —
    // map it in so callers can compare against catalogue ids.
    return Movie.fromMap({
      ...map,
      'id': (map['movie_id'] ?? map['id']).toString(),
    });
  }

  Future<void> _remoteToggle(
    String table,
    String userId,
    String movieId, {
    required String title,
    String? genre,
    String? year,
    String? rating,
    String? posterUrl,
  }) async {
    final items = await _supabase.table(table).select().eq('user_id', userId).eq('movie_id', movieId) as List;
    if (items.isNotEmpty) {
      await _supabase.table(table).delete().eq('user_id', userId).eq('movie_id', movieId);
    } else {
      await _supabase.table(table).insert({
        'user_id': userId,
        'movie_id': movieId,
        'title': title,
        'genre': genre,
        'year': year,
        'rating': rating,
        'poster_url': posterUrl,
      });
    }
  }

  Future<void> toggleWatchlist(String userId, String movieId, {required String title, String? genre, String? year, String? rating, String? posterUrl}) async {
    await _local.toggleWatchlist(movieId, title: title, genre: genre, year: year, rating: rating, posterUrl: posterUrl);
    if (_isAuthed) {
      try {
        await _remoteToggle('watchlist', userId, movieId, title: title, genre: genre, year: year, rating: rating, posterUrl: posterUrl);
      } catch (e) {
        debugPrint('Watchlist sync failed (kept locally): $e');
      }
    }
    notifyListeners();
  }

  Future<List<Movie>> getWatchlist(String userId) async {
    if (_isAuthed) {
      try {
        final response = await _supabase.table('watchlist').select().eq('user_id', userId);
        final movies = (response as List)
            .map((e) => _fromRow(e as Map<String, dynamic>))
            .toList();
        await _local.replaceWatchlist(movies);
        return movies;
      } catch (e) {
        debugPrint('Watchlist fetch failed, using local copy: $e');
      }
    }
    return _local.getWatchlist();
  }

  Future<bool> isInWatchlist(String userId, String movieId) async {
    if (await _local.isInWatchlist(movieId)) return true;
    if (_isAuthed) {
      try {
        final response = await _supabase.table('watchlist').select().eq('user_id', userId).eq('movie_id', movieId);
        return (response as List).isNotEmpty;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<void> toggleFavorite(String userId, String movieId, {required String title, String? genre, String? year, String? rating, String? posterUrl}) async {
    await _local.toggleFavorite(movieId, title: title, genre: genre, year: year, rating: rating, posterUrl: posterUrl);
    if (_isAuthed) {
      try {
        await _remoteToggle('favorites', userId, movieId, title: title, genre: genre, year: year, rating: rating, posterUrl: posterUrl);
      } catch (e) {
        debugPrint('Favorites sync failed (kept locally): $e');
      }
    }
    notifyListeners();
  }

  Future<List<Movie>> getFavorites(String userId) async {
    if (_isAuthed) {
      try {
        final response = await _supabase.table('favorites').select().eq('user_id', userId);
        final movies = (response as List)
            .map((e) => _fromRow(e as Map<String, dynamic>))
            .toList();
        await _local.replaceFavorites(movies);
        return movies;
      } catch (e) {
        debugPrint('Favorites fetch failed, using local copy: $e');
      }
    }
    return _local.getFavorites();
  }

  Future<void> addReview(ReviewModel review) async {
    await _supabase.table('reviews').insert(review.toMap());
    notifyListeners();
  }

  Future<List<ReviewModel>> getMovieReviews(String movieId) async {
    final response = await _supabase
        .table('reviews')
        .select('*, profiles!inner(username)')
        .eq('movie_id', movieId)
        .order('created_at', ascending: false);
    final data = response as List;
    return data.map((e) {
      final map = e as Map<String, dynamic>;
      final profiles = map['profiles'] as Map<String, dynamic>?;
      return ReviewModel.fromMap({...map, 'username': profiles?['username']});
    }).toList();
  }

  Future<void> updateWatchProgress(String userId, String movieId, double progress) async {
    if (_isAuthed) {
      try {
        await _supabase.table('watch_history').upsert({
          'user_id': userId,
          'movie_id': movieId,
          'progress': progress,
          'watched_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Watch progress sync failed (kept locally): $e');
      }
    }
    notifyListeners();
  }
}
