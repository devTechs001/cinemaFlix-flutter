import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'user': 'Alex Rivs',
      'avatar': 'AR',
      'time': '2h ago',
      'content': 'Just finished watching Dune: Part Two. The visuals are absolutely mind-blowing! 🏜️ Denis Villeneuve is a genius.',
      'movie': sampleMovies[0],
      'likes': 124,
      'comments': 12,
      'liked': false,
    },
    {
      'user': 'Sarah Jenkins',
      'avatar': 'SJ',
      'time': '5h ago',
      'content': 'Oppenheimer is definitely the movie of the year. Cillian Murphy\'s performance was hauntingly beautiful.',
      'movie': sampleMovies[1],
      'likes': 89,
      'comments': 5,
      'liked': true,
    },
    {
      'user': 'Mike Ross',
      'avatar': 'MR',
      'time': '1d ago',
      'content': 'Who else is excited for Deadpool 3? The trailer looks hilarious! 🤣 Wolverine is back!',
      'movie': sampleMovies[3],
      'likes': 256,
      'comments': 45,
      'liked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostCard(post, index);
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE50914),
                  child: Text(post['avatar'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['user'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(post['time'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white54),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              post['content'],
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
          if (post['movie'] != null)
            _buildMovieReference(post['movie']),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: Colors.white10),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                _actionButton(
                  post['liked'] ? Icons.favorite : Icons.favorite_border,
                  post['likes'].toString(),
                  post['liked'] ? const Color(0xFFE50914) : Colors.white54,
                  () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      post['liked'] = !post['liked'];
                      post['likes'] += post['liked'] ? 1 : -1;
                    });
                  },
                ),
                const SizedBox(width: 24),
                _actionButton(
                  Icons.chat_bubble_outline,
                  post['comments'].toString(),
                  Colors.white54,
                  () {},
                ),
                const Spacer(),
                _actionButton(
                  Icons.share_outlined,
                  '',
                  Colors.white54,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieReference(SampleMovie movie) {
    return InteractiveCard(
      onTap: () {
        Navigator.pushNamed(context, '/movie-detail', arguments: movie);
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [movie.gradientStart, movie.gradientEnd],
                ),
              ),
              child: const Icon(Icons.movie, color: Colors.white30, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${movie.year} • ${movie.genre}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(movie.rating, style: const TextStyle(color: Colors.amber, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
