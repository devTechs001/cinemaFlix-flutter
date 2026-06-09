import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cinemaflix/services/creator_service.dart';
import 'package:cinemaflix/widgets/interactive_card.dart';

class CreatorContentScreen extends StatefulWidget {
  const CreatorContentScreen({super.key});

  @override
  State<CreatorContentScreen> createState() => _CreatorContentScreenState();
}

class _CreatorContentScreenState extends State<CreatorContentScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: creatorService,
      builder: (context, _) {
        final videos = _filter == 'All'
            ? creatorService.videos
            : creatorService.videos.where((v) => v.category == _filter).toList();
        return Scaffold(
          backgroundColor: const Color(0xFF141414),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1F1F1F),
            title: const Text('My Content', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => Navigator.pushNamed(context, '/creator-upload'),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: videos.isEmpty
                    ? Center(child: Text('No ${_filter == 'All' ? '' : _filter} videos', style: TextStyle(color: Colors.white.withAlpha(80))))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: videos.length,
                        itemBuilder: (_, i) => _buildVideoCard(videos[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final categories = ['All', ...['Reviews', 'Analysis', 'Lists', 'News', 'Fun', 'Trailers']];
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = _filter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _filter = cat);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(cat, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(CreatorVideo video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
      child: InteractiveCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100, height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFF7B1FA2)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Center(child: Text(video.thumbnail, style: const TextStyle(fontSize: 28))),
                    Positioned(
                      bottom: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withAlpha(180), borderRadius: BorderRadius.circular(4)),
                        child: Text(video.duration, style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${video.views} views • ${video.likes} likes • ${video.comments} comments', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: video.isPublished ? const Color(0xFF10B981).withAlpha(25) : const Color(0xFFFFB300).withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(video.isPublished ? 'Published' : 'Draft', style: TextStyle(color: video.isPublished ? const Color(0xFF10B981) : const Color(0xFFFFB300), fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                        Text(video.category, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
                color: const Color(0xFF1F1F1F),
                onSelected: (v) {
                  if (v == 'delete') {
                    creatorService.deleteVideo(video.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${video.title} deleted'), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, color: Colors.white54), title: Text('Edit', style: TextStyle(color: Colors.white)))),
                  const PopupMenuItem(value: 'stats', child: ListTile(leading: Icon(Icons.bar_chart, color: Colors.white54), title: Text('Stats', style: TextStyle(color: Colors.white)))),
                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
