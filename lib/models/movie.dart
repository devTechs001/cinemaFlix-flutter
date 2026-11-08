import 'package:flutter/material.dart';

/// The one unified movie model for the whole app.
///
/// Replaces the former SampleMovie (UI-only) / MovieModel (DB-only) split.
/// The same class represents catalogue entries, Supabase rows
/// (`movies`, `watchlist`, `favorites`) and SQLite rows — [fromMap]
/// tolerates partial rows (e.g. watchlist entries have no cast/director)
/// and both `id` / `movie_id` keys.
class Movie {
  final String id;
  final String title;
  final String year;
  final String rating;
  final String genre;
  final String description;
  final String cast;
  final String director;
  final String duration;
  final String? posterUrl;
  final String? backdropUrl;
  final String? videoUrl;

  /// Fallback artwork colours used while a poster loads, when offline,
  /// or when no poster exists.
  final Color gradientStart;
  final Color gradientEnd;

  static const defaultGradientStart = Color(0xFF1A1A2E);
  static const defaultGradientEnd = Color(0xFF16213E);

  const Movie({
    required this.id,
    required this.title,
    this.year = '',
    this.rating = '',
    this.genre = '',
    this.description = '',
    this.cast = '',
    this.director = '',
    this.duration = '',
    this.posterUrl,
    this.backdropUrl,
    this.videoUrl,
    this.gradientStart = defaultGradientStart,
    this.gradientEnd = defaultGradientEnd,
  });

  static String _str(Object? v) => v?.toString() ?? '';
  static String? _strOrNull(Object? v) {
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: _str(map['movie_id'] ?? map['id']),
      title: _str(map['title']),
      year: _str(map['year']),
      rating: _str(map['rating']),
      genre: _str(map['genre']),
      description: _str(map['description']),
      cast: _str(map['cast']),
      director: _str(map['director']),
      duration: _str(map['duration']),
      posterUrl: _strOrNull(map['poster_url']),
      backdropUrl: _strOrNull(map['backdrop_url']),
      videoUrl: _strOrNull(map['video_url']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'rating': rating,
      'genre': genre,
      'description': description,
      'cast': cast,
      'director': director,
      'duration': duration,
      'poster_url': posterUrl,
      'backdrop_url': backdropUrl,
      'video_url': videoUrl,
    };
  }

  Movie copyWith({
    String? id,
    String? title,
    String? year,
    String? rating,
    String? genre,
    String? description,
    String? cast,
    String? director,
    String? duration,
    String? posterUrl,
    String? backdropUrl,
    String? videoUrl,
    Color? gradientStart,
    Color? gradientEnd,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      duration: duration ?? this.duration,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }
}
