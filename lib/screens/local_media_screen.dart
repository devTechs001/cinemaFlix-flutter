import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
  final List<File> _library = [];
  List<FileSystemEntity> _folders = [];
  String _currentPath = '';
  bool _loading = true;
  String _searchQuery = '';
  String _filter = 'all';
  String? _permHint;

  final Set<String> _supportedVideo = {'.mp4', '.mkv', '.avi', '.mov', '.webm', '.m4v', '.3gp'};
  final Set<String> _supportedAudio = {'.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a', '.wma'};
  final Set<String> _supportedImage = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'};

  static const _candidateRoots = [
    '/storage/emulated/0/Movies',
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/storage/emulated/0/DCIM',
    '/storage/emulated/0/Pictures',
    '/storage/emulated/0/Documents',
    '/sdcard/Movies',
    '/sdcard/Music',
    '/sdcard/Download',
    '/sdcard/DCIM',
    '/home/user/Videos',
    '/home/user/Music',
    '/home/user/Downloads',
    '/home/user',
    '/storage/emulated/0',
    '/sdcard',
    '/home',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      await Permission.storage.request();
      await Permission.videos.request();
      await Permission.audio.request();
      await Permission.photos.request();
      await Permission.manageExternalStorage.request();
    } catch (_) {}

    final found = <String, File>{};
    String? firstRoot;
    for (final root in _candidateRoots) {
      final dir = Directory(root);
      try {
        if (!dir.existsSync()) continue;
        firstRoot ??= root;
        for (final f in await _scanMedia(root)) {
          found[f.path] = f;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _library
          ..clear()
          ..addAll(found.values);
        _loading = false;
        _permHint = found.isEmpty
            ? 'Could not list device folders. Tap Browse files — that uses the system picker and works without full storage access.'
            : null;
      });
    }
    if (firstRoot != null) await _loadDirectory(firstRoot);
  }

  Future<List<File>> _scanMedia(String root, {int depth = 0}) async {
    if (depth > 3) return const [];
    final out = <File>[];
    try {
      await for (final e in Directory(root).list(followLinks: false)) {
        if (e is Directory) {
          final name = e.path.split('/').last;
          if (name.startsWith('.')) continue;
          out.addAll(await _scanMedia(e.path, depth: depth + 1));
        } else if (e is File && _isMediaFile(e.path)) {
          out.add(e);
        }
      }
    } catch (_) {}
    return out;
  }

  Future<void> _loadDirectory(String path) async {
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
          _folders = entities.whereType<Directory>().toList();
          _currentPath = path;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _currentPath = path);
    }
  }

  Future<void> _pickFromDevice() async {
    HapticFeedback.mediumImpact();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: [
          'mp4', 'mkv', 'avi', 'mov', 'webm', 'm4v', '3gp',
          'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a',
          'jpg', 'jpeg', 'png', 'gif', 'webp',
        ],
      );
      if (result == null) return;
      final added = <File>[];
      for (final f in result.files) {
        final path = f.path;
        if (path == null || path.isEmpty) continue;
        added.add(File(path));
      }
      if (added.isEmpty) return;
      setState(() {
        final seen = {for (final f in _library) f.path};
        for (final f in added) {
          if (seen.add(f.path)) _library.add(f);
        }
        _permHint = null;
      });
      if (added.length == 1) {
        _openFile(added.first);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open files: $e')),
      );
    }
  }

  String get _currentDirName {
    if (_currentPath.isEmpty || _currentPath == '/') return 'On this device';
    final parts = _currentPath.split('/').where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'On this device' : parts.last;
  }

  List<File> get _visibleLibrary {
    return _library.where((f) {
      final name = f.path.split('/').last.toLowerCase();
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }
      final type = _mediaType(f.path);
      if (_filter == 'video') return type == 'video';
      if (_filter == 'audio') return type == 'audio';
      if (_filter == 'image') return type == 'image';
      return type != 'other';
    }).toList();
  }

  List<Map<String, String>> get _playable {
    return [
      for (final f in _visibleLibrary)
        if (_mediaType(f.path) == 'video' || _mediaType(f.path) == 'audio' || _mediaType(f.path) == 'image')
          {
            'path': f.path,
            'type': _mediaType(f.path),
            'name': f.path.split('/').last,
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

  IconData _iconForPath(String path) {
    switch (_mediaType(path)) {
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

  String _sizeFor(File file) {
    try {
      final size = file.lengthSync();
      if (size < 1024) return '$size B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
      if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (_) {
      return '';
    }
  }

  void _openFile(File file) {
    final path = file.path;
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
      _pickFromDevice();
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
    final files = _visibleLibrary;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: CinemaAppBar(
        title: _currentDirName,
        showMenu: true,
        actions: [
          IconButton(
            tooltip: 'Browse files',
            onPressed: _pickFromDevice,
            icon: const Icon(Icons.create_new_folder, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Play all',
            onPressed: _playAll,
            icon: const Icon(Icons.playlist_play, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE50914),
        onPressed: _pickFromDevice,
        icon: const Icon(Icons.folder_open, color: Colors.white),
        label: const Text('Browse files', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search MP4, MP3, photos…',
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
                _filterChip('video', 'Video'),
                _filterChip('audio', 'Audio'),
                _filterChip('image', 'Photos'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                : RefreshIndicator(
                    color: const Color(0xFFE50914),
                    onRefresh: _bootstrap,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                      children: [
                        if (_permHint != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(_permHint!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          ),
                        if (_folders.isNotEmpty) ...[
                          const Text('FOLDERS', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ..._folders.take(12).map(_folderTile),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'LIBRARY · ${files.length}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (files.isEmpty)
                          _emptyState()
                        else
                          ...files.map(_fileTile),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.video_library, size: 56, color: Colors.white24),
          const SizedBox(height: 12),
          const Text('No media yet', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Browse the phone or computer and pick MP4, MP3, or photos. They play in a full-screen vertical player.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _pickFromDevice,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            icon: const Icon(Icons.folder_open),
            label: const Text('Browse device storage'),
          ),
        ],
      ),
    );
  }

  Widget _folderTile(FileSystemEntity entity) {
    final name = entity.path.split('/').last;
    return InteractiveCard(
      onTap: () => _loadDirectory(entity.path),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.folder, color: Color(0xFFFFB300), size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _fileTile(File file) {
    final name = file.path.split('/').last;
    final type = _mediaType(file.path);
    return InteractiveCard(
      onTap: () => _openFile(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withAlpha(22),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: type == 'image'
                  ? Image.file(file, fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(_iconForPath(file.path), color: const Color(0xFFE50914)))
                  : Icon(_iconForPath(file.path), color: const Color(0xFFE50914)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_sizeFor(file), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(25), borderRadius: BorderRadius.circular(6)),
              child: Text(type.toUpperCase(), style: const TextStyle(color: Color(0xFFE50914), fontSize: 9, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
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
