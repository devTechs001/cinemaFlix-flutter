import 'package:flutter_test/flutter_test.dart';
import 'package:cinemaflix/models/movie.dart';

void main() {
  group('Movie (unified model)', () {
    test('fromMap creates correct instance', () {
      final map = {
        'id': 'test-1',
        'title': 'Test Movie',
        'genre': 'Action',
        'year': '2024',
        'rating': '8.5',
        'poster_url': 'https://example.com/poster.jpg',
        'description': 'A test movie',
      };

      final movie = Movie.fromMap(map);

      expect(movie.id, 'test-1');
      expect(movie.title, 'Test Movie');
      expect(movie.genre, 'Action');
      expect(movie.year, '2024');
      expect(movie.rating, '8.5');
      expect(movie.posterUrl, 'https://example.com/poster.jpg');
      expect(movie.description, 'A test movie');
    });

    test('fromMap accepts movie_id and numeric values (SQLite/Supabase rows)',
        () {
      final map = {
        'movie_id': 'movie-9',
        'title': 'Row Movie',
        'rating': 8.5,
        'year': 2023,
      };

      final movie = Movie.fromMap(map);

      expect(movie.id, 'movie-9');
      expect(movie.title, 'Row Movie');
      expect(movie.rating, '8.5');
      expect(movie.year, '2023');
    });

    test('fromMap handles null/missing values', () {
      final map = {
        'id': 'test-2',
        'title': 'Another Movie',
      };

      final movie = Movie.fromMap(map);

      expect(movie.id, 'test-2');
      expect(movie.title, 'Another Movie');
      expect(movie.genre, '');
      expect(movie.year, '');
      expect(movie.rating, '');
      expect(movie.posterUrl, isNull);
      expect(movie.videoUrl, isNull);
      expect(movie.description, '');
    });

    test('toMap returns correct map', () {
      final movie = Movie(
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
      const original = Movie(
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
      const movie = Movie(id: 'test-5', title: 'Defaults');

      expect(movie.year, '');
      expect(movie.rating, '');
      expect(movie.genre, '');
      expect(movie.posterUrl, isNull);
      expect(movie.gradientStart, Movie.defaultGradientStart);
      expect(movie.gradientEnd, Movie.defaultGradientEnd);
    });
  });
}
