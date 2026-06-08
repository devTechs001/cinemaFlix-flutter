import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  int _viewerCount = 1284;
  final Set<String> _reactions = {};
  String _currentRoom = 'Sci-Fi Night';
  bool _showRoomDetail = false;
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _liveRooms = [
    {'name': 'Sci-Fi Night', 'host': 'MovieBot', 'viewers': 284, 'movie': 'Interstellar', 'color': const Color(0xFF1E88E5), 'active': true, 'tags': ['Trending', 'Popular']},
    {'name': 'Marvel Marathon', 'host': 'FanClub', 'viewers': 156, 'movie': 'Deadpool 3', 'color': const Color(0xFFE50914), 'active': true, 'tags': ['New']},
    {'name': 'Classic Cinema', 'host': 'Cinephiles', 'viewers': 89, 'movie': 'Inception', 'color': const Color(0xFF7B1FA2), 'active': true, 'tags': ['Classic']},
    {'name': 'New Releases', 'host': 'Reviews Hub', 'viewers': 67, 'movie': 'Dune: Part Two', 'color': const Color(0xFF43A047), 'active': false, 'tags': []},
    {'name': 'Action Hour', 'host': 'Alex C.', 'viewers': 42, 'movie': 'The Batman', 'color': const Color(0xFFFF6F00), 'active': false, 'tags': []},
    {'name': 'Horror Night', 'host': 'Spooky Club', 'viewers': 78, 'movie': 'The Others', 'color': const Color(0xFF5E35B1), 'active': true, 'tags': ['Scary']},
    {'name': 'Anime Corner', 'host': 'OtakuHub', 'viewers': 53, 'movie': 'Spirited Away', 'color': const Color(0xFFE91E63), 'active': true, 'tags': ['Anime']},
  ];

  final List<Map<String, dynamic>> _sampleChat = [
    {'user': 'Sarah J.', 'msg': 'The soundtrack is incredible!', 'time': 'now'},
    {'user': 'Mike Chen', 'msg': 'Best scene is when they enter the wormhole', 'time': '12s'},
    {'user': 'Emma W.', 'msg': 'I\'ve watched this 5 times already', 'time': '30s'},
    {'user': 'Alex T.', 'msg': 'The science behind this movie is fascinating', 'time': '45s'},
    {'user': 'Rachel K.', 'msg': 'Can we watch the sequel next?', 'time': '1m'},
    {'user': 'James B.', 'msg': 'The visuals are stunning in 4K!', 'time': '1m'},
  ];

  @override
  void initState() {
    super.initState();
    _messages.addAll(_sampleChat);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.insert(0, {'user': 'You', 'msg': text, 'time': 'now'});
      _viewerCount++;
    });
    _chatController.clear();
  }

  void _addReaction(String emoji) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_reactions.contains(emoji)) {
        _reactions.remove(emoji);
      } else {
        _reactions.add(emoji);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showRoomDetail) return _buildRoomDetail();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
              child: const Center(
                child: SizedBox(width: 4, height: 4, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Live', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text('$_viewerCount', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          InteractiveCard(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Go Live coming soon'), duration: Duration(seconds: 1)),
              );
            },
            scaleAmount: 0.88,
            child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.video_call_outlined, color: Colors.white54)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(child: _buildRoomsGrid()),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredRooms {
    if (_selectedCategory == 'All') return _liveRooms;
    if (_selectedCategory == 'Trending') return _liveRooms.where((r) => (r['tags'] as List).contains('Trending')).toList();
    if (_selectedCategory == 'Anime') return _liveRooms.where((r) => (r['tags'] as List).contains('Anime')).toList();
    return _liveRooms.where((r) => !(r['tags'] as List).contains('Trending') && !(r['tags'] as List).contains('Anime')).toList();
  }

  Widget _buildCategoryTabs() {
    const categories = ['All', 'Trending', 'Movies', 'Anime', 'Gaming', 'Music'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: categories.map((cat) {
            final active = cat == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InteractiveCard(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategory = cat);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(cat, style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoomsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredRooms.length,
      itemBuilder: (_, i) {
        final room = _filteredRooms[i];
        return InteractiveCard(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _currentRoom = room['name'];
              _showRoomDetail = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [(room['color'] as Color).withAlpha(80), (room['color'] as Color).withAlpha(20)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: room['active'] ? (room['color'] as Color).withAlpha(100) : Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: room['active'] ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(room['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    if ((room['tags'] as List).isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (room['color'] as Color).withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text((room['tags'] as List).first, style: TextStyle(color: room['color'], fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const Spacer(),
                Text(room['movie'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text('${room['viewers']} watching', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(width: 8),
                    const Icon(Icons.mic, color: Colors.white24, size: 12),
                    const SizedBox(width: 3),
                    Text(room['host'], style: const TextStyle(color: Colors.white24, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomDetail() {
    final room = _liveRooms.firstWhere((r) => r['name'] == _currentRoom);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: InteractiveCard(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _showRoomDetail = false);
          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${room['viewers']} watching • ${room['movie']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          InteractiveCard(
            onTap: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined ${room['name']}!'), duration: const Duration(seconds: 1)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Join', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [(room['color'] as Color).withAlpha(60), Colors.black],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: (room['color'] as Color).withAlpha(40),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(Icons.movie_outlined, color: room['color'], size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(room['movie'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                        child: const Center(child: SizedBox(width: 3, height: 3, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))),
                      ),
                      const SizedBox(width: 8),
                      const Text('LIVE', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 16),
                      Text('Hosted by ${room['host']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionChip(Icons.thumb_up, 'Like'),
                      const SizedBox(width: 12),
                      _actionChip(Icons.card_giftcard, 'Gift', color: const Color(0xFFE50914)),
                      const SizedBox(width: 12),
                      _actionChip(Icons.share, 'Share'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildRoomChat(),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, {Color? color}) {
    return InteractiveCard(
      onTap: () {
        HapticFeedback.lightImpact();
        if (label == 'Gift') {
          Navigator.pushNamed(context, '/gifting');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label action'), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color?.withAlpha(40) ?? Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: color != null ? Border.all(color: color.withAlpha(100)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color ?? Colors.white54, fontSize: 12, fontWeight: color != null ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomChat() {
    return Container(
      height: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.chat, color: Color(0xFFE50914), size: 16),
                const SizedBox(width: 6),
                const Text('Live Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Text('${_messages.length} messages', style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[_messages.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: msg['user'] == 'You' ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text((msg['user'] as String)[0],
                            style: TextStyle(color: msg['user'] == 'You' ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(msg['user'], style: const TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Text(msg['time'], style: const TextStyle(color: Colors.white24, fontSize: 9)),
                              ],
                            ),
                            Text(msg['msg'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                InteractiveCard(
                  onTap: _sendMessage,
                  scaleAmount: 0.85,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
