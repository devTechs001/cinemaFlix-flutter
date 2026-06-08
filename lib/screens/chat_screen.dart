import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../models/chat_message_model.dart';
import '../services/contacts_service.dart';
import '../widgets/interactive_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _contactsService = ContactsService();
  final Set<String> _onlineUsers = {'1', '2', '3', '4'};

  List<ChatMessageModel> get _messages => realtimeService.messages;

  @override
  void initState() {
    super.initState();
    realtimeService.connect();
    realtimeService.addListener(_onRealtimeUpdate);
  }

  void _onRealtimeUpdate() {
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  @override
  void dispose() {
    realtimeService.removeListener(_onRealtimeUpdate);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _chatUsers = [
    {'id': '1', 'name': 'MovieBot AI', 'avatar': '🤖', 'color': const Color(0xFF1E88E5), 'lastMsg': 'Recommended 3 movies for you', 'time': '2m', 'unread': 2},
    {'id': '2', 'name': 'Fan Club', 'avatar': '🎬', 'color': const Color(0xFF7B1FA2), 'lastMsg': 'New Dune discussion thread', 'time': '15m', 'unread': 0},
    {'id': '3', 'name': 'Sarah J.', 'avatar': 'S', 'color': const Color(0xFFE91E63), 'lastMsg': 'Have you seen Oppenheimer?', 'time': '1h', 'unread': 1},
    {'id': '4', 'name': 'Cinephiles', 'avatar': '🎞️', 'color': const Color(0xFF43A047), 'lastMsg': 'Top 10 sci-fi movies 2024', 'time': '3h', 'unread': 0},
    {'id': '5', 'name': 'Mike R.', 'avatar': 'M', 'color': const Color(0xFFFF6F00), 'lastMsg': "Let's watch something tonight", 'time': '5h', 'unread': 0},
    {'id': '6', 'name': 'Reviews Hub', 'avatar': '⭐', 'color': const Color(0xFF00ACC1), 'lastMsg': 'New review: Furiosa', 'time': '1d', 'unread': 3},
    {'id': '7', 'name': 'Alex Chen', 'avatar': 'A', 'color': const Color(0xFF5E35B1), 'lastMsg': 'Great recommendation!', 'time': '2d', 'unread': 0},
    {'id': '8', 'name': 'Movie Night', 'avatar': '🍿', 'color': const Color(0xFFD32F2F), 'lastMsg': 'This Friday at 8?', 'time': '3d', 'unread': 0},
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    final message = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authService.currentUser?.id ?? guestService.guestId,
      username: authService.currentUser?.username ?? 'You',
      content: text,
      createdAt: DateTime.now(),
    );

    realtimeService.sendMessage(message);
    _messageController.clear();
    _scrollToBottom();

    if (text.toLowerCase().contains('movie') || text.toLowerCase().contains('film')) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          realtimeService.sendMessage(ChatMessageModel(
            id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
            userId: '1',
            username: 'MovieBot AI',
            content: 'I found some great movies for you! Check out "Dune: Part Two" and "Inception" — both have amazing reviews! 🎬',
            createdAt: DateTime.now(),
          ));
          _scrollToBottom();
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _requestContacts() async {
    HapticFeedback.mediumImpact();
    final granted = await _contactsService.requestPermission();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? 'Contacts access granted' : 'Contacts access denied'),
          backgroundColor: granted ? const Color(0xFF43A047) : const Color(0xFFE50914),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text('Online', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          InteractiveCard(
            onTap: _requestContacts,
            scaleAmount: 0.88,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.contacts_outlined, color: Colors.white54),
            ),
          ),
          InteractiveCard(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New message'), duration: Duration(seconds: 1)),
              );
            },
            scaleAmount: 0.88,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.edit_outlined, color: Colors.white54),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _messages.isEmpty ? _buildChatList() : _buildChatView()),
          if (_messages.isNotEmpty) _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return Column(
      children: [
        _buildStatusRow(),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _chatUsers.length,
            separatorBuilder: (_, _) => const Divider(color: Color(0xFF2A2A2A), height: 1, indent: 76),
            itemBuilder: (context, index) {
              final user = _chatUsers[index];
              final isOnline = _onlineUsers.contains(user['id']);
              return InteractiveCard(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _messages.isNotEmpty ? null : null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening chat with ${user['name']}...'), duration: const Duration(seconds: 1)),
                  );
                },
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: (user['color'] as Color).withAlpha(40),
                        child: Text(
                          user['avatar'],
                          style: TextStyle(fontSize: (user['avatar'] as String).length > 1 ? 18 : 20),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF141414), width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(user['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      if (user['unread'] > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${user['unread']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Text(user['lastMsg'], style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(user['time'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _chatUsers.take(6).length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (_, i) {
            final user = _chatUsers[i];
            final isOnline = _onlineUsers.contains(user['id']);
            return InteractiveCard(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chat with ${user['name']}'), duration: const Duration(seconds: 1)),
                );
              },
              scaleAmount: 0.9,
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: (user['color'] as Color).withAlpha(40),
                        child: Text(user['avatar'], style: TextStyle(fontSize: (user['avatar'] as String).length > 1 ? 14 : 16)),
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF141414), width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(user['name'].split(' ').first, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.userId == 'me';
        final user = _chatUsers.firstWhere((u) => u['id'] == msg.userId, orElse: () => {'name': 'User', 'avatar': 'U', 'color': Colors.grey});

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: (user['color'] as Color).withAlpha(40),
                  child: Text(user['avatar'] as String, style: TextStyle(fontSize: (user['avatar'] as String).length > 1 ? 12 : 14)),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(user['name'] as String, style: const TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      Text(msg.content, style: const TextStyle(color: Colors.white, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(msg.createdAt),
                        style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 10),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            InteractiveCard(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attach media coming soon'), duration: Duration(seconds: 1)),
                );
              },
              scaleAmount: 0.85,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.add, color: Colors.white54, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask about movies...',
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
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE50914),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
