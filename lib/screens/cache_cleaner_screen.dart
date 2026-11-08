import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../widgets/interactive_card.dart';

class CacheCleanerScreen extends StatefulWidget {
  const CacheCleanerScreen({super.key});

  @override
  State<CacheCleanerScreen> createState() => _CacheCleanerScreenState();
}

class _CacheCleanerScreenState extends State<CacheCleanerScreen> {
  bool _videoCache = true;
  bool _imageCache = true;
  bool _thumbnailCache = true;
  bool _searchHistory = true;

  double get _selectedCount => [_videoCache, _imageCache, _thumbnailCache, _searchHistory].where((v) => v).length.toDouble();

  Future<void> _clearSelected() async {
    if (_selectedCount == 0) return;
    HapticFeedback.mediumImpact();

    await cacheService.clearAll(
      video: _videoCache,
      images: _imageCache,
      thumbnails: _thumbnailCache,
      history: _searchHistory,
    );

    if (!mounted) return;

    final freed = (_videoCache ? 0.8 : 0.0) + (_imageCache ? 0.4 : 0.0) +
        (_thumbnailCache ? 0.2 : 0.0) + (_searchHistory ? 0.05 : 0.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared ${freed.toStringAsFixed(2)} GB'),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCacheTile(String title, String subtitle, String size, bool selected, VoidCallback onToggle) {
    return InteractiveCard(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFE50914).withAlpha(100) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFFE50914) : Colors.transparent,
                border: Border.all(
                  color: selected ? const Color(0xFFE50914) : Colors.white24,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              size,
              style: TextStyle(
                color: selected ? const Color(0xFFE50914) : Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Cache Cleaner', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListenableBuilder(
        listenable: cacheService,
        builder: (context, _) {
          final info = cacheService.cacheInfo;
          final total = info.total;

          return Column(
            children: [
              if (cacheService.isClearing) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFE50914).withAlpha(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE50914),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Cleaning cache...',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          const Spacer(),
                          Text(
                            '${(cacheService.progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFFE50914),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cacheService.progress,
                          backgroundColor: Colors.white10,
                          color: const Color(0xFFE50914),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE50914).withAlpha(30),
                            const Color(0xFF1F1F1F),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE50914).withAlpha(30),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.cleaning_services,
                              color: Color(0xFFE50914),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Total Cache',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${total.toStringAsFixed(2)} GB',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${info.videoCache.toStringAsFixed(2)} GB video \u2022 ${info.imageCache.toStringAsFixed(2)} GB images \u2022 ${info.thumbnails.toStringAsFixed(2)} GB thumbnails',
                            style: const TextStyle(color: Colors.white24, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select items to clear',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedCount.toInt()} selected',
                          style: const TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCacheTile(
                      'Video Cache',
                      'Buffered video data from streaming',
                      '${info.videoCache.toStringAsFixed(2)} GB',
                      _videoCache,
                      () => setState(() => _videoCache = !_videoCache),
                    ),
                    const SizedBox(height: 8),
                    _buildCacheTile(
                      'Image Cache',
                      'Poster art, thumbnails, profile photos',
                      '${info.imageCache.toStringAsFixed(2)} GB',
                      _imageCache,
                      () => setState(() => _imageCache = !_imageCache),
                    ),
                    const SizedBox(height: 8),
                    _buildCacheTile(
                      'Thumbnail Previews',
                      'Preview thumbnails for quick browsing',
                      '${info.thumbnails.toStringAsFixed(2)} GB',
                      _thumbnailCache,
                      () => setState(() => _thumbnailCache = !_thumbnailCache),
                    ),
                    const SizedBox(height: 8),
                    _buildCacheTile(
                      'Search History',
                      'Recent searches and suggestions',
                      '${info.searchHistory.toStringAsFixed(2)} GB',
                      _searchHistory,
                      () => setState(() => _searchHistory = !_searchHistory),
                    ),
                    const SizedBox(height: 24),
                    InteractiveCard(
                      onTap: _selectedCount > 0 && !cacheService.isClearing ? _clearSelected : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedCount > 0 && !cacheService.isClearing
                              ? const Color(0xFFE50914)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cacheService.isClearing
                              ? 'Cleaning...'
                              : 'Clear Selected (${_selectedCount.toInt()})',
                          style: TextStyle(
                            color: _selectedCount > 0 && !cacheService.isClearing
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
