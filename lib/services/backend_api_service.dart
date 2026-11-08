import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'video_url_resolver.dart';

class BackendApiService {
  static const _timeout = Duration(seconds: 8);

  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.apiPath('/health')))
          .timeout(_timeout);
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['status'] == 'OK';
    } catch (e) {
      debugPrint('Backend health check failed: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMovies({
    int page = 1,
    int limit = 50,
    String? genre,
    String? search,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (genre != null && genre.isNotEmpty) 'genre': genre,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse(ApiConfig.apiPath('/movies')).replace(
      queryParameters: query,
    );
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Movies request failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body);
    final List<dynamic> items;
    if (body is List) {
      items = body;
    } else if (body is Map<String, dynamic>) {
      items = body['items'] as List<dynamic>? ?? [];
    } else {
      items = const [];
    }

    return items
        .map((item) => _normalizeMovieMap(item as Map<String, dynamic>))
        .toList();
  }

  static Map<String, dynamic> _normalizeMovieMap(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    final videoUrl = normalized['videoUrl'] ?? normalized['video_url'];
    if (videoUrl is String && videoUrl.isNotEmpty) {
      normalized['videoUrl'] =
          VideoUrlResolver.resolve(videoUrl) ?? ApiConfig.resolveUrl(videoUrl);
    }
    return normalized;
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.apiPath('/auth/token')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
            'app': 'cinemaflix',
          }),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Login failed (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getLiveRooms() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.apiPath('/live/list')))
          .timeout(_timeout);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['rooms'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Live rooms fetch failed: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createLiveRoom({
    required String title,
    String? userId,
    String? userName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/live/create')),
            headers: {
              'Content-Type': 'application/json',
              if (userId != null) 'x-user-id': userId,
              if (userName != null) 'x-user-name': userName,
            },
            body: jsonEncode({'title': title}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Create live room failed: $e');
      return null;
    }
  }

  static Future<bool> joinLiveRoom(String callId) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/live/join')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'call_id': callId}),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Join live room failed: $e');
      return false;
    }
  }

  static Future<bool> endLiveRoom(String callId) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/live/end')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'call_id': callId}),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('End live room failed: $e');
      return false;
    }
  }

  // ---- Live rooms approval flow + creator insights ----

  /// Returns {approved: true,...} when the room is open, otherwise the
  /// pending request {requestId, status: 'pending'} created on the backend.
  static Future<Map<String, dynamic>?> requestLiveJoin(
    String callId, {
    String? userId,
    String? userName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/live/rooms/$callId/join-request')),
            headers: {
              'Content-Type': 'application/json',
              if (userId != null) 'x-user-id': userId,
              if (userName != null) 'x-user-name': userName,
            },
            body: jsonEncode({if (userName != null) 'userName': userName}),
          )
          .timeout(_timeout);
      if (response.statusCode >= 400) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Request to join live failed: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getLiveJoinRequests(
    String callId, {
    String? userId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.apiPath('/live/rooms/$callId/requests?status=pending')),
            headers: {if (userId != null) 'x-user-id': userId},
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['requests'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('List live join requests failed: $e');
      return [];
    }
  }

  static Future<bool> decideLiveJoinRequest(
    String requestId, {
    required bool approve,
    String? userId,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(ApiConfig.apiPath(
              '/live/requests/$requestId/${approve ? 'approve' : 'reject'}',
            )),
            headers: {if (userId != null) 'x-user-id': userId},
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Decide live join request failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCreatorInsights({
    required String userId,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.apiPath('/creator/insights?userId=${_enc(userId)}')))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Creator insights failed: $e');
      return null;
    }
  }

  static String _enc(String raw) => Uri.encodeComponent(raw);
}
