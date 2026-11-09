import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/cinema_app_bar.dart';
import '../widgets/interactive_card.dart';

class LocalMediaScreen extends StatefulWidget {
  const LocalMediaScreen({super.key});

  @override
  State<LocalMediaScreen> createState() => _LocalMediaScreenState();
}

class _LocalMediaScreenState extends State<LocalMediaScreen> {
  List<FileSystemEntity> _items = [];
  String _currentPath = '';
  bool _loading = true;
  String _searchQuery = '';
  String _filter = 'all'; // all | video | audio
  String? _permHint;

  final Set<String> _supportedVideo = {'.mp4', '.mkv', '.avi', '.mov', '.webm'};
  final Set<String> _supportedAudio = {'.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a'};
  final Set<String> _supportedImage = {'.jpg', '.jpeg', '.png', '.gif', '.webp'};

  static const _candidateRoots = [
    '/storage/emulated/0/Movies',
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/DCIM',
    '/storage/emulated/0',
    '/sdcard/Movies',
    '/sdcard/Music',
    '/sdcard/Download',
    '/sdcard',
    '/home',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Permission.storage.request();
      await Permission.videos.request();
      await Permission.audio.request();
      await Permission.photos.request();
    } catch (_) {}

    for (final root in _candidateRoots) {
      final dir = Directory(root);
      try {
        if (dir.existsSync()) {
          await _loadDirectory(root);
          return;
        }
      } catch (_) {}
    }
    await _loadDirectory('/');
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _loading = true;
      _permHint = null;
    });
    try {
      final dir = Directory(path);
      final entities = await dir.list().toList();
      entities.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      if (mounted) {
        setState(() {
          _items = entities;
          _currentPath = path;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _permHint = 'Allow storage access to read MP4 and MP3 files from this device.';
        });
      }
    }
  }

  String get _currentDirName {
    if (_currentPath.isEmpty || _currentPath == '/') return 'Device media';
    final parts = _currentPath.split('/').where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Device media' : parts.last;
  }

  List<FileSystemEntity> get _filtered {
    return _items.where((e) {
      final name = e.path.split('/').last.toLowerCase();
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (e is Directory) return _filter == 'all';
      final type = _mediaType(e.path);
      if (_filter == 'video') return type == 'video';
      if (_filter == 'audio') return type == 'audio';
      return true;
    }).toList();
  }

  List<Map<String, String>> get _playable {
    return [
      for (final e in _filtered)
        if (e is File)
          if (_mediaType(e.path) == 'video' || _mediaType(e.path) == 'audio')
            {
              'path': e.path,
              'type': _mediaType(e.path),
              'name': e.path.split('/').last,
            },
    ];
  }

  bool _isMediaFile(String path) {
    final ext = '.${path.split('.').last.toLowerCase()}';
    return _supportedVideo.contains(ext) ||
        _supportedAudio.contains(ext) ||
        _supportedImage.contains(ext);
  }

  String _mediaType(String path) {
    final ext = '.${path.split('.').last.toLowerCase()}';
    if (_supportedVideo.contains(ext)) return 'video';
    if (_supportedAudio.contains(ext)) return 'audio';
    if (_supportedImage.contains(ext)) return 'image';
    return 'other';
  }

  IconData _iconFor(FileSystemEntity entity) {
    if (entity is Directory) return Icons.folder;
    switch (_mediaType(entity.path)) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _sizeFor(FileSystemEntity entity) {
    if (entity is! File) return '';
    try {
      final size = entity.lengthSync();
      if (size < 1024) return '$size B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
      if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (_) {
      return '';
    }
  }

  void _playFile(FileSystemEntity entity) {
    if (entity is! File) return;
    final path = entity.path;
    final type = _mediaType(path);
    HapticFeedback.mediumImpact();
    final playlist = _playable;
    final start = playlist.indexWhere((e) => e['path'] == path);
    Navigator.pushNamed(context, '/local-player', arguments: {
      'path': path,
      'type': type,
      'name': path.split('/').last,
      'playlist': start >= 0
          ? [...playlist.sublist(start), ...playlist.sublist(0, start)]
          : [
              {'path': path, 'type': type, 'name': path.split('/').last},
              ...playlist,
            ],
    });
  }

  void _playAll() {
    final list = _playable;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No MP4 or MP3 files in this folder')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/local-player', arguments: {
      'path': list.first['path'],
      'type': list.first['type'],
      'name': list.first['name'],
      'playlist': list,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: CinemaAppBar(
        title: _currentDirName,
        showMenu: _currentPath.isEmpty || _currentPath == '/',
        leading: (_currentPath.isNotEmpty && _currentPath != '/')
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final parent = Directory(_currentPath).parent.path;
                  _loadDirectory(parent);
                },
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Play all',
            onPressed: _playAll,
            icon: const Icon(Icons.playlist_play, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE50914),
        onPressed: _playAll,
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('Play MP4 / MP3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search MP4, MP3, folders…',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withAlpha(80), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('all', 'All'),
                _filterChip('video', 'MP4 video'),
                _filterChip('audio', 'MP3 audio'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                : _permHint != null && _filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_off, size: 56, color: Colors.white38),
                              const SizedBox(height: 12),
                              Text(_permHint!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _bootstrap,
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                                child: const Text('Grant access'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Text('No files here', style: TextStyle(color: Colors.white.withAlpha(80))),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 2),
                            itemBuilder: (context, index) {
                              final entity = _filtered[index];
                              final name = entity.path.split('/').last;
                              final isDir = entity is Directory;
                              final isMedia = _isMediaFile(entity.path);
                              return InteractiveCard(
                                onTap: isDir
                                    ? () => _loadDirectory(entity.path)
                                    : isMedia
                                        ? () => _playFile(entity)
                                        : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F1F1F),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isDir
                                              ? const Color(0xFFFF8F00).withAlpha(20)
                                              : isMedia
                                                  ? const Color(0xFFE50914).withAlpha(20)
                                                  : Colors.white.withAlpha(10),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _iconFor(entity),
                                          color: isDir
                                              ? const Color(0xFFFF8F00)
                                              : isMedia
                                                  ? const Color(0xFFE50914)
                                                  : Colors.white38,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            if (!isDir)
                                              Text(_sizeFor(entity), style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      if (isMedia)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE50914).withAlpha(25),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _mediaType(entity.path).toUpperCase(),
                                            style: const TextStyle(color: Color(0xFFE50914), fontSize: 9, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      if (isDir)
                                        Icon(Icons.chevron_right, color: Colors.white.withAlpha(50), size: 20),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final on = _filter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filter = id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFE50914) : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(label, style: TextStyle(color: on ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
