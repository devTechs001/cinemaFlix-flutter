import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Social graph actions — follow/unfollow and post likes, mirrored to
/// the backend (`/api/users/:id/follow`, `/api/posts/:id/like`).
///
/// All calls are best-effort: they return `null` when the backend is
/// unreachable or the user is not signed in (those endpoints require
/// auth), so screens can keep their optimistic local state and only
/// report a real server decision.
class SocialService extends ChangeNotifier {
  static const Duration _timeout = Duration(seconds: 8);

  /// Follows [targetUserId] when not following, unfollows when already
  /// following. Returns the resulting `following` state, or `null` on
  /// failure (e.g. not signed in / offline).
  Future<bool?> toggleFollow(String targetUserId) async {
    try {
      final res = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/users/$targetUserId/follow')),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic> && body['following'] is bool) {
        return body['following'] as bool;
      }
      return null;
    } catch (e) {
      debugPrint('SocialService: toggleFollow failed: $e');
      return null;
    }
  }

  /// Likes/unlikes [postId]. Returns resulting `liked`, or `null` on failure.
  Future<bool?> toggleLike(String postId) async {
    try {
      final res = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/posts/$postId/like')),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic> && body['liked'] is bool) {
        return body['liked'] as bool;
      }
      return null;
    } catch (e) {
      debugPrint('SocialService: toggleLike failed: $e');
      return null;
    }
  }

  /// Whether the signed-in user follows [targetUserId] (`null` if unknown).
  Future<bool?> isFollowing(String targetUserId) async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.apiPath('/users/$targetUserId/follow-status')))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic> && body['following'] is bool) {
        return body['following'] as bool;
      }
      return null;
    } catch (e) {
      debugPrint('SocialService: isFollowing failed: $e');
      return null;
    }
  }
}
