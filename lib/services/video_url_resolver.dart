import 'api_config.dart';

/// Turns stored `videoUrl` values into playable stream candidates.
///
/// A stored URL can be dead (expired CDN link, relative path with the
/// backend down, etc.), so players are given an ordered candidate list:
/// the stored stream first, then known-good public sample streams as a
/// resilience fallback instead of a black player.
class VideoUrlResolver {
  VideoUrlResolver._();

  /// Public sample streams (Google's open GTV bucket) used as last-resort
  /// fallbacks so playback never hard-fails on a dead link.
  static const List<String> _fallbacks = [
    'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  ];

  /// Best single candidate for a stored URL.
  ///
  /// Returns absolute `http(s)` URLs unchanged, and `null` for relative
  /// paths — callers then apply [ApiConfig.resolveUrl].
  static String? resolve(String? url) {
    final t = url?.trim() ?? '';
    if (t.isEmpty) return null;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('/')) return null;
    return t;
  }

  /// Ordered candidate list a player should try, starting with the stored
  /// URL (origin-prefixed when relative) and ending with sample fallbacks.
  static List<String> candidates(String? url) {
    final out = <String>[];
    final trimmed = url?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      final resolved = resolve(trimmed) ??
          (trimmed.startsWith('/') ? ApiConfig.resolveUrl(trimmed) : null);
      if (resolved != null && resolved.isNotEmpty) out.add(resolved);
    }
    for (final f in _fallbacks) {
      if (!out.contains(f)) out.add(f);
    }
    return out;
  }
}
