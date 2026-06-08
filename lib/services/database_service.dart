import 'package:flutter/foundation.dart';
import '../models/movie_model.dart';
import '../models/review_model.dart';
import 'supabase_service.dart';

class DatabaseService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  Future<void> toggleWatchlist(String userId, String movieId, {required String title, String? genre, String? year, String? rating, String? posterUrl}) async {
    final items = await _supabase.table('watchlist').select().eq('user_id', userId).eq('movie_id', movieId) as List;
    if (items.isNotEmpty) {
      await _supabase.table('watchlist').delete().eq('user_id', userId).eq('movie_id', movieId);
    } else {
      await _supabase.table('watchlist').insert({
        'user_id': userId,
        'movie_id': movieId,
        'title': title,
        'genre': genre,
        'year': year,
        'rating': rating,
        'poster_url': posterUrl,
      });
    }
    notifyListeners();
  }

  Future<List<MovieModel>> getWatchlist(String userId) async {
    final response = await _supabase.table('watchlist').select().eq('user_id', userId);
    final data = response as List;
    return data.map((e) => MovieModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<bool> isInWatchlist(String userId, String movieId) async {
    final response = await _supabase.table('watchlist').select().eq('user_id', userId).eq('movie_id', movieId);
    return (response as List).isNotEmpty;
  }

  Future<void> toggleFavorite(String userId, String movieId, {required String title, String? genre, String? year, String? rating, String? posterUrl}) async {
    final items = await _supabase.table('favorites').select().eq('user_id', userId).eq('movie_id', movieId) as List;
    if (items.isNotEmpty) {
      await _supabase.table('favorites').delete().eq('user_id', userId).eq('movie_id', movieId);
    } else {
      await _supabase.table('favorites').insert({
        'user_id': userId,
        'movie_id': movieId,
        'title': title,
        'genre': genre,
        'year': year,
        'rating': rating,
        'poster_url': posterUrl,
      });
    }
    notifyListeners();
  }

  Future<List<MovieModel>> getFavorites(String userId) async {
    final response = await _supabase.table('favorites').select().eq('user_id', userId);
    final data = response as List;
    return data.map((e) => MovieModel.fromMap(e as Map<String, dynamic>)).toList();
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
    await _supabase.table('watch_history').upsert({
      'user_id': userId,
      'movie_id': movieId,
      'progress': progress,
      'watched_at': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }
}
