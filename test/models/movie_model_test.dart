import 'package:flutter_test/flutter_test.dart';
import 'package:cinemaflix/models/movie_model.dart';

void main() {
  group('MovieModel', () {
    test('fromMap creates correct instance', () {
      final map = {
        'id': 'test-1',
        'title': 'Test Movie',
        'genre': 'Action',
        'year': '2024',
        'rating': '8.5',
        'poster_url': 'https://example.com/poster.jpg',
        'description': 'A test movie',
        'user_rating': 4.5,
        'is_favorited': true,
        'in_watchlist': false,
      };

      final movie = MovieModel.fromMap(map);

      expect(movie.id, 'test-1');
      expect(movie.title, 'Test Movie');
      expect(movie.genre, 'Action');
      expect(movie.year, '2024');
      expect(movie.rating, '8.5');
      expect(movie.posterUrl, 'https://example.com/poster.jpg');
      expect(movie.description, 'A test movie');
      expect(movie.userRating, 4.5);
      expect(movie.isFavorited, true);
      expect(movie.inWatchlist, false);
    });

    test('fromMap handles null values', () {
      final map = {
        'id': 'test-2',
        'title': 'Another Movie',
      };

      final movie = MovieModel.fromMap(map);

      expect(movie.id, 'test-2');
      expect(movie.title, 'Another Movie');
      expect(movie.genre, isNull);
      expect(movie.year, isNull);
      expect(movie.rating, isNull);
      expect(movie.posterUrl, isNull);
      expect(movie.userRating, isNull);
      expect(movie.isFavorited, false);
      expect(movie.inWatchlist, false);
    });

    test('toMap returns correct map', () {
      final movie = MovieModel(
        id: 'test-3',
        title: 'My Movie',
        genre: 'Comedy',
        year: '2023',
        rating: '7.2',
        posterUrl: 'https://example.com/poster2.jpg',
        description: 'A funny movie',
      );

      final map = movie.toMap();

      expect(map['id'], 'test-3');
      expect(map['title'], 'My Movie');
      expect(map['genre'], 'Comedy');
      expect(map['year'], '2023');
      expect(map['rating'], '7.2');
      expect(map['poster_url'], 'https://example.com/poster2.jpg');
      expect(map['description'], 'A funny movie');
    });

    test('copyWith creates modified copy', () {
      final original = MovieModel(
        id: 'test-4',
        title: 'Original Title',
        genre: 'Drama',
      );

      final copy = original.copyWith(title: 'Updated Title', year: '2025');

      expect(copy.id, 'test-4');
      expect(copy.title, 'Updated Title');
      expect(copy.genre, 'Drama');
      expect(copy.year, '2025');
    });

    test('defaults are correct', () {
      final movie = MovieModel(id: 'test-5', title: 'Defaults');

      expect(movie.isFavorited, false);
      expect(movie.inWatchlist, false);
      expect(movie.userRating, isNull);
    });
  });
}
