import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/movie.dart';

/// On-device SQLite storage (cinemaflix.db).
///
/// Tables:
///  - favorites     (movie_id PK, title, genre, year, rating, poster_url, added_at)
///  - watchlist     (same shape as favorites)
///  - watch_history (movie_id PK, title, progress 0..1, position_seconds,
///                   duration_seconds, updated_at)
///  - settings      (key PK, value)
///
/// This is the local-first source of truth for a single device/user:
/// favorites, watchlist and Continue Watching work offline and for
/// guests. [DatabaseService] mirrors signed-in data to Supabase.
///
/// sqflite has no web support, so on web (and if opening the database
/// ever fails) this transparently falls back to in-memory storage —
/// same API, just not persisted across restarts.
class LocalDbService extends ChangeNotifier {
  static final LocalDbService _instance = LocalDbService._();
  factory LocalDbService() => _instance;
  LocalDbService._();

  Database? _db;
  bool _initialized = false;

  // In-memory fallback (web / failure path).
  final Map<String, Map<String, Object?>> _memFavorites = {};
  final Map<String, Map<String, Object?>> _memWatchlist = {};
  final Map<String, Map<String, Object?>> _memHistory = {};
  final Map<String, String> _memSettings = {};

  bool get _useMemory => _db == null;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) {
      debugPrint('LocalDb: web build — using in-memory fallback');
      return;
    }
    try {
      final dbPath = await getDatabasesPath();
      _db = await openDatabase(
        p.join(dbPath, 'cinemaflix.db'),
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE favorites(
              movie_id TEXT PRIMARY KEY,
              title TEXT,
              genre TEXT,
              year TEXT,
              rating TEXT,
              poster_url TEXT,
              added_at TEXT
            )''');
          await db.execute('''
            CREATE TABLE watchlist(
              movie_id TEXT PRIMARY KEY,
              title TEXT,
              genre TEXT,
              year TEXT,
              rating TEXT,
              poster_url TEXT,
              added_at TEXT
            )''');
          await db.execute('''
            CREATE TABLE watch_history(
              movie_id TEXT PRIMARY KEY,
              title TEXT,
              progress REAL NOT NULL DEFAULT 0,
              position_seconds INTEGER NOT NULL DEFAULT 0,
              duration_seconds INTEGER NOT NULL DEFAULT 0,
              updated_at TEXT
            )''');
          await db.execute('''
            CREATE TABLE settings(
              key TEXT PRIMARY KEY,
              value TEXT
            )''');
        },
      );
      debugPrint('LocalDb: SQLite ready');
    } catch (e) {
      _db = null;
      debugPrint('LocalDb: SQLite unavailable, using in-memory fallback: $e');
    }
  }

  // ------------------------------------------------------------------
  // Favorites / Watchlist
  // ------------------------------------------------------------------

  Map<String, Object?> _movieRow(
    String movieId, {
    required String title,
    String? genre,
    String? year,
    String? rating,
    String? posterUrl,
  }) {
    return {
      'movie_id': movieId,
      'title': title,
      'genre': genre,
      'year': year,
      'rating': rating,
      'poster_url': posterUrl,
      'added_at': DateTime.now().toIso8601String(),
    };
  }

  /// Toggles a movie in [table] ('favorites' or 'watchlist').
  /// Returns true if the movie is now in the list.
  Future<bool> _toggle(
    String table,
    Map<String, Map<String, Object?>> memory,
    String movieId, {
    required String title,
    String? genre,
    String? year,
    String? rating,
    String? posterUrl,
  }) async {
    final exists = await _contains(table, memory, movieId);
    if (_useMemory) {
      if (exists) {
        memory.remove(movieId);
      } else {
        memory[movieId] = _movieRow(movieId,
            title: title, genre: genre, year: year, rating: rating, posterUrl: posterUrl);
      }
    } else if (exists) {
      await _db!.delete(table, where: 'movie_id = ?', whereArgs: [movieId]);
    } else {
      await _db!.insert(
        table,
        _movieRow(movieId,
            title: title, genre: genre, year: year, rating: rating, posterUrl: posterUrl),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    notifyListeners();
    return !exists;
  }

  Future<bool> _contains(
      String table, Map<String, Map<String, Object?>> memory, String movieId) async {
    if (_useMemory) return memory.containsKey(movieId);
    final rows = await _db!.query(table,
        columns: ['movie_id'], where: 'movie_id = ?', whereArgs: [movieId]);
    return rows.isNotEmpty;
  }

  Future<List<Movie>> _getMovies(
      String table, Map<String, Map<String, Object?>> memory) async {
    final List<Map<String, Object?>> rows;
    if (_useMemory) {
      rows = memory.values.toList();
    } else {
      rows = await _db!.query(table, orderBy: 'added_at DESC');
    }
    return rows
        .map((r) => Movie.fromMap({
              ...r,
              'id': (r['movie_id'] ?? '').toString(),
              'title': (r['title'] ?? '').toString(),
            }))
        .toList();
  }

  Future<bool> toggleFavorite(String movieId,
          {required String title, String? genre, String? year, String? rating, String? posterUrl}) =>
      _toggle('favorites', _memFavorites, movieId,
          title: title, genre: genre, year: year, rating: rating, posterUrl: posterUrl);

  Future<List<Movie>> getFavorites() => _getMovies('favorites', _memFavorites);
  Future<bool> isFavorite(String movieId) => _contains('favorites', _memFavorites, movieId);

  Future<bool> toggleWatchlist(String movieId,
          {required String title, String? genre, String? year, String? rating, String? posterUrl}) =>
      _toggle('watchlist', _memWatchlist, movieId,
          title: title, genre: genre, year: year, rating: rating, posterUrl: posterUrl);

  Future<List<Movie>> getWatchlist() => _getMovies('watchlist', _memWatchlist);
  Future<bool> isInWatchlist(String movieId) => _contains('watchlist', _memWatchlist, movieId);

  /// Replaces the local favorites with a fresh copy from the backend.
  Future<void> replaceFavorites(List<Movie> movies) =>
      _replace('favorites', _memFavorites, movies);

  /// Replaces the local watchlist with a fresh copy from the backend.
  Future<void> replaceWatchlist(List<Movie> movies) =>
      _replace('watchlist', _memWatchlist, movies);

  Future<void> _replace(
      String table, Map<String, Map<String, Object?>> memory, List<Movie> movies) async {
    if (_useMemory) {
      memory.clear();
      for (final m in movies) {
        memory[m.id] = _movieRow(m.id,
            title: m.title, genre: m.genre, year: m.year, rating: m.rating, posterUrl: m.posterUrl);
      }
    } else {
      final batch = _db!.batch();
      batch.delete(table);
      for (final m in movies) {
        batch.insert(table,
            _movieRow(m.id, title: m.title, genre: m.genre, year: m.year, rating: m.rating, posterUrl: m.posterUrl),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Watch history / Continue Watching
  // ------------------------------------------------------------------

  Future<void> saveWatchProgress(
    String movieId, {
    required String title,
    required double progress,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final row = <String, Object?>{
      'movie_id': movieId,
      'title': title,
      'progress': progress.clamp(0.0, 1.0),
      'position_seconds': positionSeconds,
      'duration_seconds': durationSeconds,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (_useMemory) {
      _memHistory[movieId] = row;
    } else {
      await _db!.insert('watch_history', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    notifyListeners();
  }

  /// Saved resume position in seconds, or null if never watched.
  Future<int?> getResumePosition(String movieId) async {
    if (_useMemory) return _memHistory[movieId]?['position_seconds'] as int?;
    final rows = await _db!.query('watch_history',
        columns: ['position_seconds'], where: 'movie_id = ?', whereArgs: [movieId]);
    if (rows.isEmpty) return null;
    return rows.first['position_seconds'] as int?;
  }

  /// All watch-history rows, most recently watched first.
  Future<List<Map<String, Object?>>> getWatchHistory() async {
    if (_useMemory) {
      return _memHistory.values.toList()
        ..sort((a, b) => (b['updated_at'] as String).compareTo(a['updated_at'] as String));
    }
    return _db!.query('watch_history', orderBy: 'updated_at DESC');
  }

  /// Partially-watched movies, most recently watched first.
  Future<List<Map<String, Object?>>> getContinueWatching() async {
    final List<Map<String, Object?>> rows;
    if (_useMemory) {
      rows = _memHistory.values.toList()
        ..sort((a, b) => (b['updated_at'] as String).compareTo(a['updated_at'] as String));
    } else {
      rows = await _db!.query('watch_history',
          where: 'progress > ? AND progress < ?',
          whereArgs: [0.02, 0.95],
          orderBy: 'updated_at DESC');
      return rows;
    }
    return rows.where((r) {
      final progress = (r['progress'] as num).toDouble();
      return progress > 0.02 && progress < 0.95;
    }).toList();
  }

  // ------------------------------------------------------------------
  // Settings (key-value)
  // ------------------------------------------------------------------

  Future<void> setSetting(String key, String value) async {
    if (_useMemory) {
      _memSettings[key] = value;
    } else {
      await _db!.insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<String?> getSetting(String key) async {
    if (_useMemory) return _memSettings[key];
    final rows =
        await _db!.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setIntSetting(String key, int value) => setSetting(key, value.toString());

  Future<int?> getIntSetting(String key) async {
    final v = await getSetting(key);
    return v == null ? null : int.tryParse(v);
  }

  Future<void> setBoolSetting(String key, bool value) =>
      setSetting(key, value ? '1' : '0');

  Future<bool?> getBoolSetting(String key) async {
    final v = await getSetting(key);
    return v == null ? null : v == '1';
  }

  /// Wipes all local user data (e.g. on sign-out).
  Future<void> clearUserData() async {
    _memFavorites.clear();
    _memWatchlist.clear();
    _memHistory.clear();
    if (!_useMemory) {
      final batch = _db!.batch();
      batch.delete('favorites');
      batch.delete('watchlist');
      batch.delete('watch_history');
      await batch.commit(noResult: true);
    }
    notifyListeners();
  }
}
