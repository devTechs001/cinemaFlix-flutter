import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Action', 'icon': Icons.flash_on, 'color': Color(0xFFE50914)},
    {'name': 'Comedy', 'icon': Icons.emoji_emotions, 'color': Color(0xFFFFB300)},
    {'name': 'Drama', 'icon': Icons.theater_comedy, 'color': Color(0xFF7B1FA2)},
    {'name': 'Horror', 'icon': Icons.dangerous, 'color': Color(0xFF1A1A1A)},
    {'name': 'Sci-Fi', 'icon': Icons.rocket_launch, 'color': Color(0xFF1E88E5)},
    {'name': 'Romance', 'icon': Icons.favorite, 'color': Color(0xFFE91E63)},
    {'name': 'Thriller', 'icon': Icons.sensors, 'color': Color(0xFFFF6F00)},
    {'name': 'Animation', 'icon': Icons.brush, 'color': Color(0xFF43A047)},
    {'name': 'Documentary', 'icon': Icons.menu_book, 'color': Color(0xFF00ACC1)},
    {'name': 'Mystery', 'icon': Icons.search, 'color': Color(0xFF5E35B1)},
    {'name': 'Fantasy', 'icon': Icons.auto_awesome, 'color': Color(0xFFD32F2F)},
    {'name': 'Music', 'icon': Icons.music_note, 'color': Color(0xFFF06292)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          InteractiveCard(
            onTap: () => HapticFeedback.lightImpact(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.filter_list, color: Colors.white54),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Browse by Category',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Find your next favorite movie',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return InteractiveCard(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      final matches = sampleMovies
                          .where((m) => m.genre.contains(cat['name'] as String))
                          .toList();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${cat['name']}: ${matches.length} movies'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (cat['color'] as Color).withAlpha(30),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: cat['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
