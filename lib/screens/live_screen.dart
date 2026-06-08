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

  final List<Map<String, dynamic>> _liveRooms = [
    {'name': 'Sci-Fi Night', 'host': 'MovieBot', 'viewers': 284, 'movie': 'Interstellar', 'color': const Color(0xFF1E88E5), 'active': true},
    {'name': 'Marvel Marathon', 'host': 'FanClub', 'viewers': 156, 'movie': 'Deadpool 3', 'color': const Color(0xFFE50914), 'active': true},
    {'name': 'Classic Cinema', 'host': 'Cinephiles', 'viewers': 89, 'movie': 'Inception', 'color': const Color(0xFF7B1FA2), 'active': true},
    {'name': 'New Releases', 'host': 'Reviews Hub', 'viewers': 67, 'movie': 'Dune: Part Two', 'color': const Color(0xFF43A047), 'active': false},
    {'name': 'Action Hour', 'host': 'Alex C.', 'viewers': 42, 'movie': 'The Batman', 'color': const Color(0xFFFF6F00), 'active': false},
  ];

  final List<Map<String, dynamic>> _sampleChat = [
    {'user': 'Sarah J.', 'msg': 'The soundtrack is incredible!', 'time': 'now'},
    {'user': 'Mike Chen', 'msg': 'Best scene is when they enter the wormhole', 'time': '12s'},
    {'user': 'Emma W.', 'msg': 'I\'ve watched this 5 times already', 'time': '30s'},
    {'user': 'Alex T.', 'msg': 'The science behind this movie is fascinating', 'time': '45s'},
    {'user': 'Rachel K.', 'msg': 'Can we watch the sequel next?', 'time': '1m'},
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
      _messages.add({'user': 'You', 'msg': text, 'time': 'now'});
      _viewerCount++;
    });
    _chatController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
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
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
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
            onTap: () => HapticFeedback.lightImpact(),
            scaleAmount: 0.88,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.video_call_outlined, color: Colors.white54),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLiveRooms(),
          Expanded(child: _buildChatSection()),
          _buildReactionBar(),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildLiveRooms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Rooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              InteractiveCard(
                onTap: () => HapticFeedback.lightImpact(),
                child: const Text('See All', style: TextStyle(color: Color(0xFFE50914), fontSize: 13)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _liveRooms.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final room = _liveRooms[i];
              return InteractiveCard(
                onTap: () => HapticFeedback.mediumImpact(),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [(room['color'] as Color).withAlpha(80), (room['color'] as Color).withAlpha(20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: room['active'] ? (room['color'] as Color).withAlpha(100) : Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          Text(room['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(room['movie'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.white38, size: 12),
                          const SizedBox(width: 3),
                          Text('${room['viewers']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(width: 8),
                          Text('Host: ${room['host']}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatSection() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[_messages.length - 1 - i];
                final isMe = msg['user'] == 'You';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            (msg['user'] as String)[0],
                            style: TextStyle(color: isMe ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(msg['user'], style: const TextStyle(color: Color(0xFFE50914), fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 6),
                                Text(msg['time'], style: const TextStyle(color: Colors.white24, fontSize: 10)),
                              ],
                            ),
                            Text(msg['msg'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBar() {
    const reactions = ['🔥', '😂', '😍', '🎬', '🍿', '👏'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((emoji) {
          final isActive = _reactions.contains(emoji);
          return InteractiveCard(
            onTap: () => _addReaction(emoji),
            scaleAmount: 0.85,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE50914).withAlpha(30) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? const Color(0xFFE50914).withAlpha(60) : Colors.white10),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: 'Join the discussion...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            InteractiveCard(
              onTap: _sendMessage,
              scaleAmount: 0.85,
              child: Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
