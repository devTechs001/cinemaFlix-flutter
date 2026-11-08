import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/download_service.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startDownload(SampleMovie movie) {
    HapticFeedback.mediumImpact();
    downloadService.startDownload(
      movie.id, movie.title, movie.genre, movie.year, movie.rating,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${movie.title}...'),
        backgroundColor: const Color(0xFFE50914),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Downloads', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE50914),
          labelColor: const Color(0xFFE50914),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Downloaded'),
            Tab(text: 'Available'),
            Tab(text: 'Active'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadedTab(),
          _buildAvailableTab(),
          _buildActiveTab(),
        ],
      ),
    );
  }

  Widget _buildDownloadedTab() {
    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final downloaded = downloadService.completedDownloads;
        if (downloaded.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.download_done_rounded, color: Colors.white24, size: 56),
                ),
                const SizedBox(height: 16),
                const Text('No downloads yet', style: TextStyle(color: Colors.white38, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Download movies to watch offline', style: TextStyle(color: Colors.white24, fontSize: 14)),
                const SizedBox(height: 24),
                InteractiveCard(
                  onTap: () => _tabController.animateTo(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text('Browse Movies', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (downloadService.totalDownloadedMB > 0) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Total: ${downloadService.totalDownloadedMB.toStringAsFixed(1)} MB used',
                    style: const TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text('${downloaded.length} movies', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const Spacer(),
                  Text('${downloadService.totalDownloadedMB.toStringAsFixed(1)} MB', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 12),
                  GestureText(
                    text: 'Clear All',
                    color: const Color(0xFFE50914),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      downloadService.clearCompleted();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: downloaded.length,
                itemBuilder: (context, index) {
                  final d = downloaded[index];
                  return _buildDownloadCard(d);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sampleMovies.length,
      itemBuilder: (context, index) {
        final movie = sampleMovies[index];
        final isDownloaded = downloadService.isDownloaded(movie.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [movie.gradientStart, movie.gradientEnd]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.movie_outlined, color: Colors.white38, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                    Text('${movie.year} \u2022 ${movie.genre}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              InteractiveCard(
                onTap: isDownloaded ? null : () => _startDownload(movie),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDownloaded ? Colors.white10 : const Color(0xFFE50914),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDownloaded ? Icons.check : Icons.download,
                        color: Colors.white, size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDownloaded ? 'Downloaded' : 'Download',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveTab() {
    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final active = downloadService.activeDownloads;
        if (active.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.download_outlined, color: Colors.white24, size: 56),
                ),
                const SizedBox(height: 16),
                const Text('No active downloads', style: TextStyle(color: Colors.white38, fontSize: 18)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: active.length,
          itemBuilder: (context, index) {
            final d = active[index];
            return _buildActiveCard(d);
          },
        );
      },
    );
  }

  Widget _buildDownloadCard(DownloadItem d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE50914).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                Text('${d.quality} \u2022 ${d.fileSizeMB.toStringAsFixed(0)} MB', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          InteractiveCard(
            onTap: () {
              HapticFeedback.lightImpact();
              downloadService.removeDownload(d.id);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white38, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(DownloadItem d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  d.status == DownloadStatus.downloading ? Icons.downloading : Icons.pause_circle_outline,
                  color: d.status == DownloadStatus.downloading ? const Color(0xFFE50914) : Colors.white38,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                    Text(
                      d.status == DownloadStatus.downloading
                          ? '${(d.progress * 100).toInt()}% \u2022 ${(d.fileSizeMB * (1 - d.progress)).toStringAsFixed(0)} MB left'
                          : 'Paused',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (d.status == DownloadStatus.downloading)
                InteractiveCard(
                  onTap: () => downloadService.pauseDownload(d.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pause, color: Colors.white54, size: 18),
                  ),
                )
              else
                InteractiveCard(
                  onTap: () => downloadService.resumeDownload(d.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_arrow, color: Color(0xFFE50914), size: 18),
                  ),
                ),
            ],
          ),
          if (d.status == DownloadStatus.downloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: d.progress,
                backgroundColor: Colors.white10,
                color: const Color(0xFFE50914),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GestureText extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const GestureText({super.key, required this.text, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
