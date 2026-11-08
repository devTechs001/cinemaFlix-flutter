import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/sample_movies.dart';
import 'api_config.dart';

/// Social feed loader.
///
/// Pulls posts from the backend (`GET /api/posts`) and adapts them into
/// the feed-card shape used by `SocialFeedScreen` (same keys as the
/// bundled demo posts, so the screen renders remote posts with no other
/// changes). Returns an empty list on any failure — the screen keeps its
/// demo posts in that case, so the feed is never blank.
class FeedService extends ChangeNotifier {
  static const Duration _timeout = Duration(seconds: 8);

  List<Map<String, dynamic>> _posts = [];
  bool _loading = false;

  List<Map<String, dynamic>> get posts => List.unmodifiable(_posts);
  bool get loading => _loading;

  /// Loads the backend feed; `[]` when unavailable (offline / backend down).
  Future<List<Map<String, dynamic>>> load({int limit = 30}) async {
    _loading = true;
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.apiPath('/posts?limit=$limit')))
          .timeout(_timeout);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      final items = body is Map<String, dynamic>
          ? (body['posts'] as List<dynamic>? ?? const [])
          : const [];
      _posts = [
        for (var i = 0; i < items.length; i++)
          _adapt(items[i] as Map<String, dynamic>, i),
      ];
      return posts;
    } catch (e) {
      debugPrint('FeedService: backend feed unavailable: $e');
      return const [];
    } finally {
      _loading = false;
    }
  }

  /// Adapts one backend post into the feed card map.
  Map<String, dynamic> _adapt(Map<String, dynamic> post, int index) {
    final username = (post['username'] ?? 'Cinema Fan').toString();
    final movieTitle = (post['movieTitle'] ?? '').toString();
    final movie = sampleMovies.isEmpty
        ? null
        : movieTitle.isEmpty
            ? sampleMovies[index % sampleMovies.length]
            : sampleMovies.firstWhere(
                (m) => m.title == movieTitle,
                orElse: () => sampleMovies[index % sampleMovies.length],
              );
    return {
      'id': (post['id'] ?? '').toString(),
      'user': username,
      'avatar': _initials(username),
      'time': _relativeTime(post['createdAt']?.toString()),
      'content': (post['content'] ?? '').toString(),
      'movie': movie,
      'likes': (post['likesCount'] as num?)?.toInt() ?? 0,
      'comments': (post['commentsCount'] as num?)?.toInt() ?? 0,
      'liked': post['liked'] == true,
      'saved': post['saved'] == true,
      'commentsList': <Map<String, dynamic>>[],
    };
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final chars = parts.take(2).map((p) => p[0].toUpperCase());
    return chars.isEmpty ? 'CF' : chars.join();
  }

  static String _relativeTime(String? iso) {
    if (iso == null) return 'now';
    final created = DateTime.tryParse(iso)?.toLocal();
    if (created == null) return 'now';
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${created.day}/${created.month}/${created.year}';
  }
}
