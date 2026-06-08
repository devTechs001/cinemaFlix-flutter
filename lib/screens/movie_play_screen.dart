import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/sample_movies.dart';

class MoviePlayScreen extends StatefulWidget {
  final SampleMovie movie;

  const MoviePlayScreen({super.key, required this.movie});

  @override
  State<MoviePlayScreen> createState() => _MoviePlayScreenState();
}

class _MoviePlayScreenState extends State<MoviePlayScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initialized = false;
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.movie.videoUrl ?? 'https://www.w3schools.com/html/mov_bbb.mp4'),
      );
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFE50914),
          bufferedColor: Colors.white24,
          handleColor: const Color(0xFFE50914),
          backgroundColor: Colors.white12,
        ),
        placeholder: Container(
          color: const Color(0xFF141414),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          ),
        ),
        errorBuilder: (context, error) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white38, size: 48),
                SizedBox(height: 12),
                Text('Playback unavailable', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        },
      );
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _useFallback = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: _buildVideo(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movie.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBadge(widget.movie.rating, const Color(0xFFE50914)),
                        const SizedBox(width: 10),
                        Text(widget.movie.year, style: const TextStyle(color: Colors.white54)),
                        const SizedBox(width: 10),
                        Text(widget.movie.duration, style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.movie.genre,
                      style: const TextStyle(color: Color(0xFFE50914), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Synopsis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.movie.description,
                      style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Director', widget.movie.director),
                    const SizedBox(height: 8),
                    _buildInfoRow('Cast', widget.movie.cast),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (_useFallback) {
      return Container(
        color: widget.movie.gradientStart,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.movie_creation_outlined, color: Colors.white38, size: 64),
              const SizedBox(height: 12),
              const Text('Sample Player', style: TextStyle(color: Colors.white54, fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => HapticFeedback.mediumImpact(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play Demo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }
    return ClipRRect(
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      ],
    );
  }
}
