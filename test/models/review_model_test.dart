import 'package:flutter_test/flutter_test.dart';
import 'package:cinemaflix/models/review_model.dart';

void main() {
  group('ReviewModel', () {
    final now = DateTime.now();

    test('fromMap creates correct instance', () {
      final map = {
        'id': 'review-1',
        'user_id': 'user-1',
        'movie_id': 'movie-1',
        'rating': 4.5,
        'content': 'Great movie!',
        'created_at': now.toIso8601String(),
        'username': 'TestUser',
      };

      final review = ReviewModel.fromMap(map);

      expect(review.id, 'review-1');
      expect(review.userId, 'user-1');
      expect(review.movieId, 'movie-1');
      expect(review.rating, 4.5);
      expect(review.content, 'Great movie!');
      expect(review.createdAt, now);
      expect(review.username, 'TestUser');
    });

    test('toMap returns correct map', () {
      final review = ReviewModel(
        id: 'review-2',
        userId: 'user-2',
        movieId: 'movie-2',
        rating: 3.0,
        content: 'It was okay',
        createdAt: now,
      );

      final map = review.toMap();

      expect(map['id'], 'review-2');
      expect(map['user_id'], 'user-2');
      expect(map['movie_id'], 'movie-2');
      expect(map['rating'], 3.0);
      expect(map['content'], 'It was okay');
      expect(map['created_at'], now.toIso8601String());
    });

    test('username is null when not provided', () {
      final review = ReviewModel(
        id: 'review-3',
        userId: 'user-3',
        movieId: 'movie-3',
        rating: 5.0,
        content: 'Amazing!',
        createdAt: now,
      );

      expect(review.username, isNull);
    });
  });
}
