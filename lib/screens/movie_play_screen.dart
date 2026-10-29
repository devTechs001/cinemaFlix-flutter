import 'dart:async';
import '../theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/movie_catalogue.dart';
import '../services/globals.dart';

class MoviePlayScreen extends StatefulWidget {
  final Movie movie;

  const MoviePlayScreen({super.key, required this.movie});

  @override
  State<MoviePlayScreen> createState() => _MoviePlayScreenState();
}

class _MoviePlayScreenState extends State<MoviePlayScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _progressTimer;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // Clean up any previous attempt (e.g. when retrying after an error).
    _progressTimer?.cancel();
    _chewieController?.dispose();
    _chewieController = null;
    await _videoController?.dispose();
    _videoController = null;

    if (widget.movie.videoUrl == null) {
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.movie.videoUrl!));
      await _videoController!.initialize();

      // Resume where the user left off (SQLite watch_history).
      final resumeAt = await localDbService.getResumePosition(widget.movie.id);
      if (resumeAt != null && resumeAt > 5) {
        await _videoController!.seekTo(Duration(seconds: resumeAt));
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: const AppColors.brand,
          bufferedColor: Colors.white24,
          handleColor: const AppColors.brand,
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

      _progressTimer =
          Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());

      if (mounted) setState(() => _isInitialized = true);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _saveProgress() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration.inSeconds;
    if (duration <= 0) return;
    final position = controller.value.position.inSeconds;
    final progress = position / duration;
    localDbService.saveWatchProgress(
      widget.movie.id,
      title: widget.movie.title,
      progress: progress,
      positionSeconds: position,
      durationSeconds: duration,
    );
    final userId = authService.currentUser?.id;
    if (userId != null) {
      databaseService.updateWatchProgress(userId, widget.movie.id, progress);
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });
    _initPlayer();
  }

  @override
  void dispose() {
    _saveProgress();
    _progressTimer?.cancel();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_hasError)
            _buildError()
          else if (_isInitialized && _chewieController != null)
            Chewie(controller: _chewieController!)
          else if (_isInitialized)
            _buildPlaceholder()
          else
            _buildLoading(),
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

  Widget _gradientBackground(Widget child) {
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
      child: Center(child: child),
    );
  }

  Widget _buildLoading() {
    return _gradientBackground(
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.brand),
          SizedBox(height: 16),
          Text('Loading video…', style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return _gradientBackground(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.brand, size: 56),
          const SizedBox(height: 16),
          Text(
            widget.movie.title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Couldn't load this video. Check your connection and try again.",
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return _gradientBackground(
      Column(
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
            '${widget.movie.year} • ${widget.movie.genre}',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'No video URL available',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
