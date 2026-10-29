import 'package:flutter_test/flutter_test.dart';
import 'package:cinemaflix/models/chat_message_model.dart';
import 'package:cinemaflix/models/movie.dart';
import 'package:cinemaflix/models/movie_catalogue.dart';
import 'package:cinemaflix/models/review_model.dart';
import 'package:cinemaflix/models/user_model.dart';

void main() {
  group('Movie', () {
    test('fromMap parses a watchlist-shaped row', () {
      final movie = Movie.fromMap({
        'id': 'dune2',
        'title': 'Dune: Part Two',
        'genre': 'Sci-Fi',
        'year': '2024',
        'rating': '8.7',
        'poster_url': null,
      });
      expect(movie.id, 'dune2');
      expect(movie.title, 'Dune: Part Two');
      expect(movie.genre, 'Sci-Fi');
      expect(movie.posterUrl, isNull);
      expect(movie.description, '');
    });

    test('fromMap accepts movie_id and numeric year/rating', () {
      final movie = Movie.fromMap({
        'movie_id': 'matrix',
        'title': 'The Matrix',
        'year': 1999,
        'rating': 8.7,
      });
      expect(movie.id, 'matrix');
      expect(movie.year, '1999');
      expect(movie.rating, '8.7');
    });

    test('copyWith changes only given fields', () {
      final movie = Movie(id: '1', title: 'A');
      final copy = movie.copyWith(title: 'B', genre: 'Drama');
      expect(copy.id, '1');
      expect(copy.title, 'B');
      expect(copy.genre, 'Drama');
    });
  });

  group('ReviewModel', () {
    test('fromMap/toMap round-trip', () {
      final review = ReviewModel.fromMap({
        'id': 'r1',
        'user_id': 'u1',
        'movie_id': 'dune2',
        'rating': 4,
        'content': 'Great',
        'created_at': '2026-10-29T10:00:00.000',
        'username': 'Sarah',
      });
      expect(review.rating, 4.0);
      expect(review.username, 'Sarah');
      final map = review.toMap();
      expect(map['movie_id'], 'dune2');
      expect(map['rating'], 4.0);
    });
  });

  group('ChatMessageModel', () {
    test('fromMap defaults username to Anonymous', () {
      final msg = ChatMessageModel.fromMap({
        'id': 'm1',
        'user_id': 'u1',
        'content': 'hi',
        'created_at': '2026-10-29T10:00:00.000',
      });
      expect(msg.username, 'Anonymous');
      expect(msg.content, 'hi');
    });
  });

  group('UserModel', () {
    test('fromMap defaults username and detects admin', () {
      final user = UserModel.fromMap({
        'id': 'u1',
        'email': 'devTechs842@gmail.com',
        'created_at': '2026-10-29T10:00:00.000',
      });
      expect(user.username, 'Cinema Fan');
      expect(user.isAdmin, isTrue);
    });
  });

  group('movieCatalogue', () {
    test('ids are unique and every movie has poster + metadata', () {
      final ids = movieCatalogue.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final m in movieCatalogue) {
        expect(m.title, isNotEmpty, reason: m.id);
        expect(m.posterUrl, isNotNull, reason: m.id);
        expect(m.posterUrl, startsWith('https://'), reason: m.id);
        expect(double.tryParse(m.rating), isNotNull, reason: m.id);
      }
    });

    test('getMovieById and getTrendingMovies work', () {
      expect(getMovieById('inception')?.title, 'Inception');
      expect(getMovieById('does-not-exist'), isNull);
      final trending = getTrendingMovies(limit: 3);
      expect(trending.length, 3);
      expect(double.parse(trending.first.rating),
          greaterThanOrEqualTo(double.parse(trending.last.rating)));
    });
  });
}
