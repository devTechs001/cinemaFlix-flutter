import 'package:flutter_test/flutter_test.dart';
import 'package:cinemaflix/models/chat_message_model.dart';
import 'package:cinemaflix/models/movie_model.dart';
import 'package:cinemaflix/models/review_model.dart';
import 'package:cinemaflix/models/user_model.dart';

void main() {
  group('MovieModel', () {
    test('fromMap parses a watchlist-shaped row', () {
      final movie = MovieModel.fromMap({
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
      expect(movie.isFavorited, isFalse);
      expect(movie.inWatchlist, isFalse);
    });

    test('copyWith changes only given fields', () {
      final movie = MovieModel(id: '1', title: 'A');
      final copy = movie.copyWith(title: 'B', isFavorited: true);
      expect(copy.id, '1');
      expect(copy.title, 'B');
      expect(copy.isFavorited, isTrue);
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
}
