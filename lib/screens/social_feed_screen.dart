import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _posts = [
    {
      'user': 'Alex Rivs',
      'avatar': 'AR',
      'time': '2h ago',
      'content': 'Just finished watching Dune: Part Two. The visuals are absolutely mind-blowing! \u{1F3DC}\uFE0F Denis Villeneuve is a genius.',
      'movie': sampleMovies[0],
      'likes': 124,
      'comments': 12,
      'liked': false,
      'saved': false,
      'commentsList': [
        {'user': 'Emma W.', 'avatar': 'EW', 'time': '1h ago', 'content': 'Totally agree! The cinematography was unreal.'},
        {'user': 'Tom C.', 'avatar': 'TC', 'time': '45m ago', 'content': 'That scene with the sandworm... wow.'},
      ],
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
      'saved': true,
      'commentsList': [
        {'user': 'Mark L.', 'avatar': 'ML', 'time': '4h ago', 'content': 'Best biopic since The Social Network.'},
      ],
    },
    {
      'user': 'Mike Ross',
      'avatar': 'MR',
      'time': '1d ago',
      'content': 'Who else is excited for Deadpool 3? The trailer looks hilarious! \u{1F923} Wolverine is back!',
      'movie': sampleMovies[3],
      'likes': 256,
      'comments': 45,
      'liked': false,
      'saved': false,
      'commentsList': [
        {'user': 'DeadpoolFan', 'avatar': 'DF', 'time': '23h ago', 'content': 'I\'ve watched the trailer 20 times already!'},
        {'user': 'WolverineX', 'avatar': 'WX', 'time': '20h ago', 'content': 'Hugh Jackman never ages.'},
        {'user': 'MarvelNerd', 'avatar': 'MN', 'time': '18h ago', 'content': 'The cameos are going to be insane.'},
      ],
    },
  ];

  final List<String> _trendingTopics = [
    '#DunePartTwo', '#Oppenheimer', '#Deadpool3', '#Interstellar',
    '#Inception', '#Furiosa', '#TheBatman', '#Joker',
  ];

  int _visiblePostCount = 3;

  final Map<int, AnimationController> _likeControllers = {};
  final Map<int, Animation<double>> _likeAnimations = {};

  @override
  void dispose() {
    for (final controller in _likeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AnimationController _getLikeController(int index) {
    if (!_likeControllers.containsKey(index)) {
      _likeControllers[index] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _likeAnimations[index] = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 60),
      ]).animate(CurvedAnimation(
        parent: _likeControllers[index]!,
        curve: Curves.easeOut,
      ));
    }
    return _likeControllers[index]!;
  }

  void _showCreatePostDialog() {
    HapticFeedback.lightImpact();
    final textController = TextEditingController();
    SampleMovie? selectedMovie;
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create Post', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  if (isPosting)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE50914))),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              if (selectedMovie != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [selectedMovie!.gradientStart, selectedMovie!.gradientEnd]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.movie, color: Colors.white30, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(selectedMovie!.title, style: const TextStyle(color: Colors.white))),
                      InteractiveCard(
                        onTap: () => setDialogState(() => selectedMovie = null),
                        child: const Icon(Icons.close, color: Colors.white38, size: 18),
                      ),
                    ],
                  ),
                )
              else
                InteractiveCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF2A2A2A),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (mc) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 32, height: 4,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Select a Movie', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ...sampleMovies.map((m) => ListTile(
                            leading: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [m.gradientStart, m.gradientEnd]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.movie, color: Colors.white30, size: 18),
                            ),
                            title: Text(m.title, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('\u2605 ${m.rating}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                            onTap: () {
                              setDialogState(() => selectedMovie = m);
                              Navigator.pop(mc);
                            },
                          )),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.movie_outlined, color: Colors.white54, size: 16),
                        SizedBox(width: 6),
                        Text('Tag a movie', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  InteractiveCard(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image attachment coming soon'), backgroundColor: Color(0xFFE50914)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined, color: Colors.white54, size: 16),
                          SizedBox(width: 6),
                          Text('Image/GIF', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InteractiveCard(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF2A2A2A),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (ec) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 32, height: 4,
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Pick an Emoji', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Wrap(
                                spacing: 8, runSpacing: 8,
                                children: [
                                  '\u{1F600}','\u{1F602}','\u{1F970}','\u{1F60E}','\u{1F929}','\u{1F622}','\u{1F621}','\u{1F97A}','\u{1F914}','\u{1F644}',
                                  '\u{1F525}','\u{1F4AF}','\u{1F3AC}','\u{1F97F}','\u{1F31F}','\u{1F3A5}','\u{1F3C6}','\u2764\uFE0F','\u{1F480}','\u{1F44F}',
                                  '\u{1F44D}','\u{1F389}','\u{1F680}','\u{2B50}','\u{1F4AA}','\u{1F62D}','\u{1F923}','\u{1F60D}','\u{1F64C}','\u2728',
                                ].map((e) => InteractiveCard(
                                  onTap: () {
                                    final currentText = textController.text;
                                    final selection = textController.selection;
                                    final newText = currentText.substring(0, selection.start) + e + currentText.substring(selection.end);
                                    setDialogState(() {
                                      textController.text = newText;
                                      textController.selection = TextSelection.collapsed(offset: selection.start + e.length);
                                    });
                                    Navigator.pop(ec);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(e, style: const TextStyle(fontSize: 24)),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_emotions_outlined, color: Colors.white54, size: 16),
                          SizedBox(width: 6),
                          Text('Emoji', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isPosting
                      ? null
                      : () async {
                          final text = textController.text.trim();
                          if (text.isEmpty) return;
                          setDialogState(() => isPosting = true);
                          HapticFeedback.mediumImpact();
                          await Future.delayed(const Duration(milliseconds: 600));
                          if (!mounted) return;
                          setState(() {
                            _posts.insert(0, {
                              'user': authService.currentUser?.username ?? 'Cinema Fan',
                              'avatar': (authService.currentUser?.username ?? 'CF').split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                              'time': 'just now',
                              'content': text,
                              'movie': selectedMovie,
                              'likes': 0,
                              'comments': 0,
                              'liked': false,
                              'saved': false,
                              'commentsList': [],
                            });
                          });
                          Navigator.pop(ctx);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentSheet(Map<String, dynamic> post, int index) {
    HapticFeedback.lightImpact();
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 32, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Text('Comments', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    InteractiveCard(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: (post['commentsList'] as List).length,
                  itemBuilder: (c, i) {
                    final comment = (post['commentsList'] as List)[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFE50914),
                            child: Text(comment['avatar'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(comment['user'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Text(comment['time'], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment['content'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white10),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InteractiveCard(
                      onTap: () {
                        final text = commentController.text.trim();
                        if (text.isEmpty) return;
                        HapticFeedback.lightImpact();
                        setSheetState(() {
                          (post['commentsList'] as List).insert(0, {
                            'user': authService.currentUser?.username ?? 'Cinema Fan',
                            'avatar': (authService.currentUser?.username ?? 'CF').split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                            'time': 'just now',
                            'content': text,
                          });
                          post['comments'] = (post['comments'] as int) + 1;
                        });
                        commentController.clear();
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE50914),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGiftDialog(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Send a Gift', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Show appreciation for this post', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _giftOption('\u{1F3AC}', 'Film Reel', '100'),
                _giftOption('\u{1F31F}', 'Star', '250'),
                _giftOption('\u{1F3C6}', 'Trophy', '500'),
                _giftOption('\u{1F525}', 'Fire', '1000'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gift sent! \u{1F389}'),
                      backgroundColor: Color(0xFFE50914),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Send Gift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _giftOption(String emoji, String label, String cost) {
    return InteractiveCard(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            const SizedBox(height: 4),
            Text('$cost pts', style: const TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Share', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareOption(Icons.repeat, 'Share to Feed', () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shared to Feed'), backgroundColor: Color(0xFFE50914), behavior: SnackBarBehavior.floating),
                  );
                }),
                _shareOption(Icons.link, 'Copy Link', () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard'), backgroundColor: Color(0xFFE50914), behavior: SnackBarBehavior.floating),
                  );
                }),
                _shareOption(Icons.share, 'Share via...', () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share sheet opened'), backgroundColor: Color(0xFFE50914), behavior: SnackBarBehavior.floating),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(IconData icon, String label, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showPostOptionsSheet(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    final userName = post['user'] as String;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Post Options', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _optionTile(Icons.flag_outlined, 'Report', Colors.orangeAccent, () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post reported'), backgroundColor: Color(0xFFE50914), behavior: SnackBarBehavior.floating),
              );
            }),
            const Divider(color: Colors.white10, height: 1),
            _optionTile(Icons.visibility_off_outlined, 'Hide', Colors.white70, () {
              Navigator.pop(ctx);
              setState(() {
                _posts.removeWhere((p) => p == post);
              });
            }),
            const Divider(color: Colors.white10, height: 1),
            _optionTile(Icons.person_add_outlined, 'Follow $userName', Colors.white70, () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Following $userName'), backgroundColor: const Color(0xFFE50914), behavior: SnackBarBehavior.floating),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: color, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _toggleLike(Map<String, dynamic> post, int index) {
    HapticFeedback.lightImpact();
    setState(() {
      post['liked'] = !post['liked'];
      post['likes'] = (post['likes'] as int) + (post['liked'] ? 1 : -1);
    });
    if (post['liked'] as bool) {
      _getLikeController(index).forward(from: 0);
    }
  }

  void _toggleSave(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    setState(() {
      post['saved'] = !post['saved'];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(post['saved'] as bool ? 'Post saved' : 'Post unsaved'),
        backgroundColor: const Color(0xFFE50914),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _showCreatePostDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE50914),
        backgroundColor: const Color(0xFF2A2A2A),
        displacement: 60,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildTrendingTopics(),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildPostCard(_posts[index], index);
                },
                childCount: _visiblePostCount,
              ),
            ),
            if (_visiblePostCount < _posts.length)
              SliverToBoxAdapter(
                child: _buildLoadMore(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingTopics() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _trendingTopics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final topic = _trendingTopics[index];
          return InteractiveCard(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Searching $topic...'), backgroundColor: const Color(0xFFE50914), behavior: SnackBarBehavior.floating),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE50914).withAlpha(80)),
              ),
              alignment: Alignment.center,
              child: Text(topic, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: InteractiveCard(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _visiblePostCount = (_visiblePostCount + 3).clamp(0, _posts.length);
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.expand_more, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                'Load more (${_posts.length - _visiblePostCount} remaining)',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
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
                  onPressed: () => _showPostOptionsSheet(post),
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
                AnimatedBuilder(
                  animation: _getLikeController(index),
                  builder: (context, child) {
                    final likeAnim = _likeAnimations[index];
                    return Transform.scale(
                      scale: likeAnim?.value ?? 1.0,
                      child: child,
                    );
                  },
                  child: _actionButton(
                    post['liked'] ? Icons.favorite : Icons.favorite_border,
                    (post['likes'] as int).toString(),
                    post['liked'] ? const Color(0xFFE50914) : Colors.white54,
                    () => _toggleLike(post, index),
                  ),
                ),
                const SizedBox(width: 24),
                _actionButton(
                  Icons.chat_bubble_outline,
                  (post['comments'] as int).toString(),
                  Colors.white54,
                  () => _showCommentSheet(post, index),
                ),
                const SizedBox(width: 24),
                InteractiveCard(
                  onTap: () => _showGiftDialog(post),
                  child: const Icon(Icons.card_giftcard_outlined, color: Colors.white54, size: 20),
                ),
                const Spacer(),
                InteractiveCard(
                  onTap: () => _toggleSave(post),
                  child: Icon(
                    (post['saved'] as bool) ? Icons.bookmark : Icons.bookmark_border,
                    color: (post['saved'] as bool) ? const Color(0xFFE50914) : Colors.white54,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                _actionButton(
                  Icons.share_outlined,
                  '',
                  Colors.white54,
                  () => _showShareSheet(post),
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
                  Text('${movie.year} \u2022 ${movie.genre}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
