import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/globals.dart';
import '../services/social_service.dart';
import '../theme/app_tokens.dart';

/// Another user's public profile (opened from chat / feed).
///
/// Loads the user, follow state and posts from the backend; falls back
/// to a locally derived profile when the backend is unreachable so the
/// route never crashes. Follow/unfollow goes through [SocialService].
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const _timeout = Duration(seconds: 8);

  String _username = '';
  String? _avatarUrl;
  String _createdAt = '';
  String _bio = '';
  String _website = '';
  String _location = '';
  int _followers = 0;
  int _following = 0;
  int _postCount = 0;
  bool? _isFollowing;
  bool _busy = false;
  bool _loading = true;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _loadUser();
    await _loadPosts();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadUser() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.apiPath('/users/${widget.userId}')))
          .timeout(_timeout);
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return;
      setState(() {
        _username = (body['username'] ?? '').toString();
        _avatarUrl = body['avatarUrl']?.toString();
        _createdAt = (body['createdAt'] ?? '').toString();
        _followers = (body['followersCount'] as num?)?.toInt() ?? 0;
        _following = (body['followingCount'] as num?)?.toInt() ?? 0;
        _postCount = (body['postsCount'] as num?)?.toInt() ?? 0;
        _isFollowing = body['isFollowing'] is bool ? body['isFollowing'] as bool : null;
        _bio = (body['bio'] ?? '').toString();
        _website = (body['website'] ?? '').toString();
        _location = (body['location'] ?? '').toString();
      });
    } catch (_) {
      // Backend offline — keep the derived fallback below.
    }
    if (_username.isEmpty) {
      setState(() => _username = 'CinemaFan_${_shortId}');
    }
  }

  Future<void> _loadPosts() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.apiPath(
              '/posts?userId=${Uri.encodeComponent(widget.userId)}&limit=20')))
          .timeout(_timeout);
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return;
      final items = (body['posts'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _posts = items;
          if (_postCount == 0) _postCount = items.length;
        });
      }
    } catch (_) {
      // Offline — profile still renders without posts.
    }
  }

  String get _shortId {
    final id = widget.userId;
    return id.length <= 6 ? id : id.substring(0, 6);
  }

  String get _initials {
    final name = _username.trim();
    if (name.isEmpty) return 'CF';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final chars = parts.take(2).map((p) => p[0].toUpperCase());
    return chars.isEmpty ? 'CF' : chars.join();
  }

  Future<void> _toggleFollow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await socialService.toggleFollow(widget.userId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result != null) {
        final wasFollowing = _isFollowing == true;
        _isFollowing = result;
        if (result && !wasFollowing) _followers++;
        if (!result && wasFollowing && _followers > 0) _followers--;
      }
    });
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in (and start the backend) to follow users'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
            : RefreshIndicator(
                color: AppColors.brand,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    _buildStats(),
                    const SizedBox(height: 12),
                    _buildActions(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Posts',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_posts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No posts yet — start the backend to see this user’s activity.',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._posts.map(_buildPostCard),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F1F1F), AppColors.background],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white70, size: 20),
              ),
              const Expanded(
                child: Text(
                  'Profile',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), AppColors.brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            alignment: Alignment.center,
            child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _avatarUrl!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarText(),
                    ),
                  )
                : _avatarText(),
          ),
          const SizedBox(height: 10),
          Text(
            _username,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '@$_shortId${_createdAt.isEmpty ? '' : ' · joined ${_createdAt.substring(0, _createdAt.length > 10 ? 10 : _createdAt.length)}'}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (_bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _bio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
            ),
          ],
          if (_location.isNotEmpty || _website.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                [_location, _website].where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatarText() {
    return Text(
      _initials,
      style: const TextStyle(
          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildStats() {
    Widget stat(String value, String label) => Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        stat('$_followers', 'Followers'),
        _divider(),
        stat('$_following', 'Following'),
        _divider(),
        stat('$_postCount', 'Posts'),
      ],
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: 1,
        height: 28,
        color: AppColors.surfaceVariant,
      );

  Widget _buildActions() {
    final following = _isFollowing == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _busy ? null : _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: following ? AppColors.surfaceVariant : AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
              child: Text(
                following ? 'Following' : 'Follow',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/chat'),
              icon: const Icon(Icons.chat_outlined, size: 16),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: AppColors.surfaceVariant),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final content = (post['content'] ?? '').toString();
    final time = (post['createdAt'] ?? '').toString();
    final likes = (post['likesCount'] as num?)?.toInt() ?? 0;
    final comments = (post['commentsCount'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(_initials,
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _username,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                time.isEmpty ? 'recently' : _shortTime(time),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.favorite_border,
                  size: 16, color: likes > 0 ? AppColors.brand : Colors.white38),
              const SizedBox(width: 4),
              Text('$likes', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.mode_comment,
                  size: 16, color: Colors.white38),
              const SizedBox(width: 4),
              Text('$comments',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _shortTime(String iso) {
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return 'recently';
    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
