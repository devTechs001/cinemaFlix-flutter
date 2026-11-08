import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';

class LocalMediaScreen extends StatefulWidget {
  const LocalMediaScreen({super.key});

  @override
  State<LocalMediaScreen> createState() => _LocalMediaScreenState();
}

class _LocalMediaScreenState extends State<LocalMediaScreen> {
  List<FileSystemEntity> _items = [];
  String _currentPath = '/';
  bool _loading = true;
  String _searchQuery = '';
  final Set<String> _supportedVideo = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm'};
  final Set<String> _supportedAudio = {'.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a', '.wma'};
  final Set<String> _supportedImage = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'};

  @override
  void initState() {
    super.initState();
    _loadDirectory('/');
  }

  Future<void> _loadDirectory(String path) async {
    setState(() => _loading = true);
    try {
      final dir = Directory(path);
      final entities = await dir.list().toList();
      entities.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.compareTo(b.path);
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
        setState(() => _loading = false);
      }
    }
  }

  String get _currentDirName {
    final parts = _currentPath.split('/').where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Root' : parts.last;
  }

  List<FileSystemEntity> get _filtered {
    if (_searchQuery.isEmpty) return _items;
    return _items.where((e) => e.path.split('/').last.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  bool _isMediaFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return _supportedVideo.contains('.$ext') || _supportedAudio.contains('.$ext') || _supportedImage.contains('.$ext');
  }

  String _mediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (_supportedVideo.contains('.$ext')) return 'video';
    if (_supportedAudio.contains('.$ext')) return 'audio';
    if (_supportedImage.contains('.$ext')) return 'image';
    return 'other';
  }

  IconData _iconFor(FileSystemEntity entity) {
    if (entity is Directory) return Icons.folder_rounded;
    final path = entity.path;
    final type = _mediaType(path);
    switch (type) {
      case 'video': return Icons.videocam_rounded;
      case 'audio': return Icons.audiotrack_rounded;
      case 'image': return Icons.image_rounded;
      default: return Icons.insert_drive_file_rounded;
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
    Navigator.pushNamed(context, '/local-player', arguments: {'path': path, 'type': type, 'name': path.split('/').last});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: Text(_currentDirName, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: _currentPath != '/'
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final parent = Directory(_currentPath).parent.path;
                  _loadDirectory(parent);
                },
              )
            : null,
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
                  hintText: 'Search files...',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withAlpha(80), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_off, size: 56, color: Colors.white.withAlpha(40)),
                            const SizedBox(height: 12),
                            Text('Empty directory', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                    width: 40, height: 40,
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
                                      color: isDir ? const Color(0xFFFF8F00) : isMedia ? const Color(0xFFE50914) : Colors.white38,
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
                                      child: Text(_mediaType(entity.path).toUpperCase(), style: const TextStyle(color: Color(0xFFE50914), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
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
}
