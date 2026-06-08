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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.movie.videoUrl == null) {
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.movie.videoUrl!));
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      showOptions: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFFE50914),
        bufferedColor: Colors.white24,
        handleColor: const Color(0xFFE50914),
        backgroundColor: Colors.white12,
      ),
      placeholder: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.movie.gradientStart,
              widget.movie.gradientEnd,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Icon(Icons.movie_filter_outlined, color: Colors.white.withAlpha(30), size: 80),
        ),
      ),
    );

    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized && _chewieController != null)
            Chewie(controller: _chewieController!)
          else if (_isInitialized)
            _buildPlaceholder()
          else
            _buildPlaceholder(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                onPressed: () {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.movie.gradientStart,
            widget.movie.gradientEnd,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white54,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.movie.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.movie.year} \u2022 ${widget.movie.genre}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'No video URL available',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
