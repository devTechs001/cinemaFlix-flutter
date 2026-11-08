import 'package:flutter/material.dart';

enum PluginStatus { disconnected, connecting, connected, error }

class Plugin {
  final String id;
  final String name;
  final String description;
  final String icon;
  final Color color;
  final List<String> permissions;
  PluginStatus status;

  Plugin({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.permissions = const [],
    this.status = PluginStatus.disconnected,
  });
}

class PluginService extends ChangeNotifier {
  final List<Plugin> _plugins = [
    Plugin(id: 'youtube', name: 'YouTube', description: 'Sync your watch history and upload videos', icon: '▶️', color: const Color(0xFFFF0000), permissions: ['Read watch history', 'Upload videos', 'Read playlists']),
    Plugin(id: 'spotify', name: 'Spotify', description: 'Access movie soundtracks and create playlists', icon: '🎵', color: const Color(0xFF1DB954), permissions: ['Read playlists', 'Create playlists', 'Play music']),
    Plugin(id: 'discord', name: 'Discord', description: 'Share what you\'re watching and join movie nights', icon: '💬', color: const Color(0xFF5865F2), permissions: ['Send messages', 'Read presence', 'Join voice']),
    Plugin(id: 'twitter', name: 'X (Twitter)', description: 'Post reviews and share movie moments', icon: '🐦', color: const Color(0xFF1DA1F2), permissions: ['Post tweets', 'Read timeline', 'Read mentions']),
    Plugin(id: 'instagram', name: 'Instagram', description: 'Share stories and posts about movies', icon: '📸', color: const Color(0xFFE4405F), permissions: ['Share stories', 'Post photos', 'Read profile']),
    Plugin(id: 'tiktok', name: 'TikTok', description: 'Cross-post your short videos to TikTok', icon: '🎵', color: const Color(0xFF000000), permissions: ['Upload videos', 'Read profile', 'Read feed']),
    Plugin(id: 'gdrive', name: 'Google Drive', description: 'Backup your downloads and access files', icon: '☁️', color: const Color(0xFF4285F4), permissions: ['Read files', 'Upload files', 'Manage storage']),
    Plugin(id: 'dropbox', name: 'Dropbox', description: 'Sync your watchlist and downloads', icon: '📦', color: const Color(0xFF0061FF), permissions: ['Read files', 'Read metadata', 'Upload files']),
    Plugin(id: 'twitch', name: 'Twitch', description: 'Go live simultaneously on Twitch', icon: '🔴', color: const Color(0xFF9146FF), permissions: ['Stream live', 'Read chat', 'Manage channel']),
    Plugin(id: 'imdb', name: 'IMDb', description: 'Sync ratings and import your watchlist', icon: '⭐', color: const Color(0xFFF5C518), permissions: ['Read ratings', 'Read watchlist', 'Sync reviews']),
    Plugin(id: 'trakt', name: 'Trakt', description: 'Auto-scrobble what you watch', icon: '📺', color: const Color(0xFFED1C24), permissions: ['Read history', 'Write history', 'Sync collection']),
    Plugin(id: 'letterboxd', name: 'Letterboxd', description: 'Cross-post reviews and diary entries', icon: '🎬', color: const Color(0xFF10B981), permissions: ['Write diary', 'Post reviews', 'Read watchlist']),
  ];

  List<Plugin> get plugins => List.unmodifiable(_plugins);
  List<Plugin> get connected => _plugins.where((p) => p.status == PluginStatus.connected).toList();
  List<Plugin> get available => _plugins.where((p) => p.status == PluginStatus.disconnected || p.status == PluginStatus.error).toList();

  Future<void> connect(String pluginId) async {
    final plugin = _plugins.where((p) => p.id == pluginId).toList();
    if (plugin.isEmpty) return;
    plugin.first.status = PluginStatus.connecting;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    plugin.first.status = PluginStatus.connected;
    notifyListeners();
  }

  void disconnect(String pluginId) {
    final plugin = _plugins.where((p) => p.id == pluginId).toList();
    if (plugin.isEmpty) return;
    plugin.first.status = PluginStatus.disconnected;
    notifyListeners();
  }

  int get connectedCount => _plugins.where((p) => p.status == PluginStatus.connected).length;
}

final pluginService = PluginService();
