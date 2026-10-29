import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';
import '../services/globals.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _filter = 'All';
  bool _loading = true;

  final List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  SampleMovie? _byId(String id) {
    for (final m in sampleMovies) {
      if (m.id == id) return m;
    }
    return null;
  }

  String _fmtDate(Object? iso) {
    final s = iso?.toString() ?? '';
    return s.length >= 10 ? s.substring(0, 10) : '';
  }

  /// Builds the activity feed from the on-device SQLite database
  /// (watch history, watchlist, favorites) — real user data, no demo rows.
  /// Movies that aren't in the current catalogue are skipped because the
  /// list renders [SampleMovie] objects.
  Future<void> _loadRecords() async {
    final records = <Map<String, dynamic>>[];
    try {
      final history = await localDbService.getWatchHistory();
      for (final row in history) {
        final movie = _byId((row['movie_id'] ?? '').toString());
        if (movie == null) continue;
        final progress = ((row['progress'] as num?)?.toDouble() ?? 0) * 100;
        records.add({
          'movie': movie,
          'action': 'Watched',
          'date': _fmtDate(row['updated_at']),
          'progress': '${progress.round()}%',
          'icon': Icons.visibility,
        });
      }
      final watchlist = await localDbService.getWatchlist();
      for (final m in watchlist) {
        final movie = _byId(m.id);
        if (movie == null) continue;
        records.add({
          'movie': movie,
          'action': 'Added to Watchlist',
          'date': '',
          'progress': '',
          'icon': Icons.bookmark,
        });
      }
      final favorites = await localDbService.getFavorites();
      for (final m in favorites) {
        final movie = _byId(m.id);
        if (movie == null) continue;
        records.add({
          'movie': movie,
          'action': 'Added to Favorites',
          'date': '',
          'progress': '',
          'icon': Icons.favorite,
        });
      }
      records.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    } catch (_) {
      // Leave the list empty; the empty state explains what to do.
    }
    if (!mounted) return;
    setState(() {
      _records
        ..clear()
        ..addAll(records);
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _records;
    return _records
        .where((r) =>
            (r['action'] as String).toLowerCase().contains(_filter.toLowerCase()))
        .toList();
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
                  _filterChip('Watchlist', Icons.bookmark),
                  _filterChip('Favorites', Icons.favorite),
                ],
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
                            Icon(Icons.history, size: 64, color: Colors.white.withAlpha(40)),
                            const SizedBox(height: 16),
                            const Text('No records yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text('Watch or save a movie and it will show up here.',
                                style: TextStyle(color: Colors.white24, fontSize: 12)),
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
                                      color: Color(0xFFE50914).withAlpha(30),
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
            color: active ? Color(0xFFE50914) : Color(0xFF2A2A2A),
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
