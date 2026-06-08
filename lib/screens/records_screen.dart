import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _filter = 'All';

  final List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < sampleMovies.length; i++) {
      final m = sampleMovies[i];
      _records.addAll([
        {'movie': m, 'action': 'Watched', 'date': '2024-06-${7 - i}', 'progress': '100%', 'icon': Icons.visibility},
        {'movie': m, 'action': 'Added to Watchlist', 'date': '2024-06-${5 - i}', 'progress': '', 'icon': Icons.bookmark},
        if (i < 4) {'movie': m, 'action': 'Reviewed', 'date': '2024-06-${3 - i}', 'progress': '★★★★☆', 'icon': Icons.star},
        if (i < 5) {'movie': m, 'action': 'Shared', 'date': '2024-06-${1 - i}', 'progress': '', 'icon': Icons.share},
      ]);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _records;
    return _records.where((r) => r['action'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Records', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', Icons.all_inclusive),
                  _filterChip('Watched', Icons.visibility),
                  _filterChip('Reviewed', Icons.star),
                  _filterChip('Shared', Icons.share),
                  _filterChip('Watchlist', Icons.bookmark),
                ],
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.white.withAlpha(40)),
                        const SizedBox(height: 16),
                        const Text('No records found', style: TextStyle(color: Colors.white38, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(color: Color(0xFF2A2A2A), height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final record = _filtered[i];
                      final movie = record['movie'] as SampleMovie;
                      return InteractiveCard(
                        onTap: () => Navigator.pushNamed(context, '/movie-detail', arguments: movie),
                        child: ListTile(
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [movie.gradientStart, movie.gradientEnd]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(record['icon'] as IconData, color: Colors.white54, size: 22),
                          ),
                          title: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE50914).withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(record['action'], style: const TextStyle(color: Color(0xFFE50914), fontSize: 10)),
                              ),
                              if ((record['progress'] as String).isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(record['progress'], style: const TextStyle(color: Colors.amber, fontSize: 10)),
                              ],
                            ],
                          ),
                          trailing: Text(record['date'], style: const TextStyle(color: Colors.white24, fontSize: 11)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, IconData icon) {
    final active = _filter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InteractiveCard(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _filter = label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? Colors.white : Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}
