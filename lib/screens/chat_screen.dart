import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cinemaflix/services/globals.dart';
import 'package:cinemaflix/models/chat_message_model.dart';
import 'package:cinemaflix/services/contacts_service.dart';
import 'package:cinemaflix/widgets/interactive_card.dart';

class _ChatRoom {
  final String id;
  final String name;
  final String icon;
  final int memberCount;
  final List<Color> gradient;

  const _ChatRoom({
    required this.id,
    required this.name,
    required this.icon,
    required this.memberCount,
    required this.gradient,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _contactsService = ContactsService();
  final Set<String> _onlineUsers = {'1', '2', '3', '4'};
  final Set<String> _typingUsers = {'3', '5'};
  final Set<String> _readMessageIds = {};
  final Map<String, List<String>> _messageReactions = {};
  final Map<String, String> _messageStatuses = {};
  Map<String, dynamic>? _selectedChatUser;
  _ChatRoom? _currentRoom;
  bool _showRoomList = false;
  final Map<String, List<ChatMessageModel>> _roomMessages = {};
  String _searchQuery = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _typingDotController;

  final Map<String, List<String>> _userFavorites = {
    '1': ['Inception', 'The Dark Knight', 'Interstellar'],
    '2': ['Dune', 'Blade Runner 2049', 'Arrival'],
    '3': ['Oppenheimer', 'Barbie', 'La La Land'],
    '4': ['2001: A Space Odyssey', 'Stalker', 'Solaris'],
    '5': ['Pulp Fiction', 'Fight Club', 'The Matrix'],
    '6': ['Mad Max: Fury Road', 'Furiosa', 'The Road Warrior'],
    '7': ['Parasite', 'Everything Everywhere All At Once',
        'The Grand Budapest Hotel'],
    '8': ['The Shawshank Redemption', 'The Godfather', 'Pulp Fiction'],
  };

  final List<String> _reactionEmojis = [
    '❤️', '😂', '👍', '😮', '😢', '😡', '🙌', '🔥',
  ];

  final List<String> _emojiPickerEmojis = [
    '😀', '😂', '😍', '🥰', '😎', '🤔', '😢', '😡',
    '👍', '👎', '👏', '🙌', '🔥', '❤️', '💯', '🎉',
    '🍿', '🎬', '🎭', '🎥', '📽️', '🎞️', '🍕', '☕',
  ];

  List<ChatMessageModel> get _messages => realtimeService.messages;

  @override
  void initState() {
    super.initState();
    realtimeService.connect();
    realtimeService.addListener(_onRealtimeUpdate);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _typingDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    realtimeService.removeListener(_onRealtimeUpdate);
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _pulseController.dispose();
    _typingDotController.dispose();
    super.dispose();
  }

  void _onRealtimeUpdate() {
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  final List<Map<String, dynamic>> _chatUsers = [
    {
      'id': '1',
      'name': 'MovieBot AI',
      'avatar': '🤖',
      'color': const Color(0xFF1E88E5),
      'lastMsg': 'Recommended 3 movies for you',
      'time': '2m',
      'unread': 2,
    },
    {
      'id': '2',
      'name': 'Fan Club',
      'avatar': '🎬',
      'color': const Color(0xFF7B1FA2),
      'lastMsg': 'New Dune discussion thread',
      'time': '15m',
      'unread': 0,
      'isGroup': true,
      'members': ['3', '5', '7'],
    },
    {
      'id': '3',
      'name': 'Sarah J.',
      'avatar': 'S',
      'color': const Color(0xFFE91E63),
      'lastMsg': 'Have you seen Oppenheimer?',
      'time': '1h',
      'unread': 1,
    },
    {
      'id': '4',
      'name': 'Cinephiles',
      'avatar': '🎞️',
      'color': const Color(0xFF43A047),
      'lastMsg': 'Top 10 sci-fi movies 2024',
      'time': '3h',
      'unread': 0,
      'isGroup': true,
      'members': ['5', '7', '3'],
    },
    {
      'id': '5',
      'name': 'Mike R.',
      'avatar': 'M',
      'color': const Color(0xFFFF6F00),
      'lastMsg': "Let's watch something tonight",
      'time': '5h',
      'unread': 0,
    },
    {
      'id': '6',
      'name': 'Reviews Hub',
      'avatar': '⭐',
      'color': const Color(0xFF00ACC1),
      'lastMsg': 'New review: Furiosa',
      'time': '1d',
      'unread': 3,
      'isGroup': true,
      'members': ['7', '3', '5'],
    },
    {
      'id': '7',
      'name': 'Alex Chen',
      'avatar': 'A',
      'color': const Color(0xFF5E35B1),
      'lastMsg': 'Great recommendation!',
      'time': '2d',
      'unread': 0,
    },
    {
      'id': '8',
      'name': 'Movie Night',
      'avatar': '🍿',
      'color': const Color(0xFFD32F2F),
      'lastMsg': 'This Friday at 8?',
      'time': '3d',
      'unread': 0,
    },
  ];

  final List<_ChatRoom> _chatRooms = const [
    _ChatRoom(id: 'rm_movies', name: 'Movie Discussions', icon: '🎬', memberCount: 1200, gradient: [Color(0xFFE50914), Color(0xFFFF6F00)]),
    _ChatRoom(id: 'rm_series', name: 'Series Talk', icon: '📺', memberCount: 856, gradient: [Color(0xFF7B1FA2), Color(0xFF1E88E5)]),
    _ChatRoom(id: 'rm_classic', name: 'Classic Cinema', icon: '🎞️', memberCount: 432, gradient: [Color(0xFF43A047), Color(0xFF00ACC1)]),
    _ChatRoom(id: 'rm_newreleases', name: 'New Releases', icon: '🍿', memberCount: 678, gradient: [Color(0xFFD32F2F), Color(0xFFE91E63)]),
    _ChatRoom(id: 'rm_indie', name: 'Indie Films', icon: '🎭', memberCount: 234, gradient: [Color(0xFF5E35B1), Color(0xFF7B1FA2)]),
    _ChatRoom(id: 'rm_world', name: 'World Cinema', icon: '🌍', memberCount: 345, gradient: [Color(0xFF1E88E5), Color(0xFF43A047)]),
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _chatUsers;
    return _chatUsers.where((u) =>
      (u['name'] as String).toLowerCase().contains(_searchQuery)
    ).toList();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = ChatMessageModel(
      id: msgId,
      userId: authService.currentUser?.id ?? guestService.guestId,
      username: authService.currentUser?.username ?? 'You',
      content: text,
      createdAt: DateTime.now(),
    );

    if (_currentRoom != null) {
      _roomMessages.putIfAbsent(_currentRoom!.id, () => []);
      _roomMessages[_currentRoom!.id]!.add(message);
      _messageStatuses[msgId] = 'sent';
      _messageController.clear();
      _scrollToBottom();
      return;
    }

    realtimeService.sendMessage(message);
    _messageStatuses[msgId] = 'sent';
    _messageController.clear();
    _scrollToBottom();

    if (text.toLowerCase().contains('movie') ||
        text.toLowerCase().contains('film')) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          final respId = 'resp_${DateTime.now().millisecondsSinceEpoch}';
          realtimeService.sendMessage(
            ChatMessageModel(
              id: respId,
              userId: '1',
              username: 'MovieBot AI',
              content:
                  'I found some great movies for you! Check out "Dune: Part Two" and "Inception" — both have amazing reviews! 🎬',
              createdAt: DateTime.now(),
            ),
          );
          _messageStatuses[respId] = 'delivered';
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
          content: Text(
            granted ? 'Contacts access granted' : 'Contacts access denied',
          ),
          backgroundColor: granted
              ? const Color(0xFF43A047)
              : const Color(0xFFE50914),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAttachmentSheet() {
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
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Attach Media',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentOption(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(ctx);
                  _sendFakeAttachment('📷 Photo');
                }),
                _attachmentOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(ctx);
                  _sendFakeAttachment('📸 Camera shot');
                }),
                _attachmentOption(Icons.movie, 'Video', () {
                  Navigator.pop(ctx);
                  _sendFakeAttachment('🎬 Video');
                }),
                _attachmentOption(Icons.headphones, 'Audio', () {
                  Navigator.pop(ctx);
                  _sendFakeAttachment('🎵 Audio file');
                }),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentOption(Icons.description, 'File', () {
                  Navigator.pop(ctx);
                  _sendFakeAttachment('📄 Document');
                }),
                _attachmentOption(Icons.location_on, 'Location', () {
                  Navigator.pop(ctx);
                  _sendFakeAttachment('📍 Location');
                }),
                _attachmentOption(Icons.person, 'Contact', () {
                  Navigator.pop(ctx);
                  _sendFakeAttachment('👤 Contact');
                }),
                const SizedBox(width: 64),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _sendFakeAttachment(String type) {
    HapticFeedback.mediumImpact();
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = ChatMessageModel(
      id: msgId,
      userId: authService.currentUser?.id ?? guestService.guestId,
      username: authService.currentUser?.username ?? 'You',
      content: type,
      createdAt: DateTime.now(),
    );

    if (_currentRoom != null) {
      _roomMessages.putIfAbsent(_currentRoom!.id, () => []);
      _roomMessages[_currentRoom!.id]!.add(message);
      _messageStatuses[msgId] = 'sent';
      _scrollToBottom();
      return;
    }

    realtimeService.sendMessage(message);
    _messageStatuses[msgId] = 'sent';
    _scrollToBottom();
  }

  Widget _attachmentOption(IconData icon, String label, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  void _showReactionPicker(String messageId) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('React to message',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _reactionEmojis.map((emoji) {
                final isActive = _messageReactions[messageId]
                        ?.contains(emoji) ==
                    true;
                return GestureDetector(
                  onTap: () {
                    _toggleReaction(messageId, emoji);
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE50914).withAlpha(30)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                      border: isActive
                          ? Border.all(
                              color: const Color(0xFFE50914).withAlpha(80),
                              width: 1.5)
                          : null,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleReaction(String messageId, String emoji) {
    setState(() {
      _messageReactions.putIfAbsent(messageId, () => []);
      if (_messageReactions[messageId]!.contains(emoji)) {
        _messageReactions[messageId]!.remove(emoji);
        if (_messageReactions[messageId]!.isEmpty) {
          _messageReactions.remove(messageId);
        }
      } else {
        _messageReactions[messageId]!.add(emoji);
      }
    });
  }

  void _showUserProfile(Map<String, dynamic> user) {
    HapticFeedback.mediumImpact();
    final isOnline = _onlineUsers.contains(user['id']);
    final isGroup = user['isGroup'] == true;
    final favorites = _userFavorites[user['id']] ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            if (isGroup)
              _buildGroupAvatarStack(user['members'] as List<String>? ?? [],
                  radius: 28)
            else
              CircleAvatar(
                radius: 40,
                backgroundColor: (user['color'] as Color).withAlpha(40),
                child: Text(
                  user['avatar'] as String,
                  style: TextStyle(
                    fontSize:
                        (user['avatar'] as String).length > 1 ? 32 : 36,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              user['name'] as String,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isOnline ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (favorites.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Favorite Movies',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: favorites.map((movie) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(movie,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedChatUser = user);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isGroup ? 'View Group Chat' : 'Send Message',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Pick an emoji',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _emojiPickerEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    final text = _messageController.text;
                    final sel = _messageController.selection;
                    final start = sel.isValid ? sel.start : text.length;
                    final newText =
                        '${text.substring(0, start)}$emoji${text.substring(start)}';
                    _messageController.text = newText;
                    _messageController.selection =
                        TextSelection.collapsed(
                            offset: start + emoji.length);
                    Navigator.pop(ctx);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingDot({bool isOnline = true}) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isOnline ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                        color: Colors.green.withAlpha(100),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupAvatarStack(List<String> memberIds,
      {double radius = 14}) {
    final members = memberIds.take(3).map((id) =>
      _chatUsers.firstWhere((u) => u['id'] == id,
          orElse: () =>
              {'avatar': '?', 'color': Colors.grey, 'name': '?'})
    ).toList();

    return SizedBox(
      width: radius * 2 + (members.length - 1) * radius * 0.7,
      height: radius * 2,
      child: Stack(
        children: [
          for (int i = 0; i < members.length; i++)
            Positioned(
              left: i * radius * 0.7,
              child: CircleAvatar(
                radius: radius,
                backgroundColor:
                    (members[i]['color'] as Color).withAlpha(40),
                child: Text(
                  members[i]['avatar'] as String,
                  style: TextStyle(
                    fontSize: members.length > 1 ? radius * 0.7 : radius,
                  ),
                ),
              ),
            ),
          if (memberIds.length > 3)
            Positioned(
              left: 3 * radius * 0.7,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Colors.black54,
                child: Text(
                  '+${memberIds.length - 3}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.65,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingDotController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase =
                        (_typingDotController.value - i * 0.3) % 1.0;
                    final scale =
                        (math.sin(phase * math.pi) * 0.6) + 0.4;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildListAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text('Chat',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildPulsingDot(),
          const SizedBox(width: 6),
          const Text(
            'Online',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        InteractiveCard(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _showRoomList = !_showRoomList);
          },
          scaleAmount: 0.88,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              _showRoomList ? Icons.chat : Icons.meeting_room_outlined,
              color: _showRoomList ? const Color(0xFFE50914) : Colors.white54,
            ),
          ),
        ),
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
              const SnackBar(
                content: Text('New message'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          scaleAmount: 0.88,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child:
                Icon(Icons.edit_outlined, color: Colors.white54),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildChatAppBar() {
    final user = _selectedChatUser!;
    final isOnline = _onlineUsers.contains(user['id']);
    final isGroup = user['isGroup'] == true;

    return AppBar(
      leading: InteractiveCard(
        onTap: () => setState(() => _selectedChatUser = null),
        scaleAmount: 0.85,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.arrow_back, color: Colors.white70),
        ),
      ),
      title: GestureDetector(
        onTap: () {
          setState(() => _selectedChatUser = null);
          _showUserProfile(user);
        },
        child: Row(
          children: [
            if (isGroup)
              _buildGroupAvatarStack(
                  user['members'] as List<String>? ?? [],
                  radius: 16)
            else
              CircleAvatar(
                radius: 16,
                backgroundColor: (user['color'] as Color).withAlpha(40),
                child: Text(
                  user['avatar'] as String,
                  style: TextStyle(
                    fontSize:
                        (user['avatar'] as String).length > 1 ? 12 : 14,
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] as String,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (_typingUsers.contains(user['id']))
                  const Text(
                    'Typing...',
                    style: TextStyle(
                        color: Color(0xFFE50914),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  )
                else
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: isOnline ? Colors.green : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        InteractiveCard(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search in conversation'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          scaleAmount: 0.88,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child:
                Icon(Icons.search, color: Colors.white54),
          ),
        ),
        InteractiveCard(
          onTap: _requestContacts,
          scaleAmount: 0.88,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.more_vert, color: Colors.white54),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentRoom != null
          ? _buildRoomAppBar()
          : (_selectedChatUser != null
              ? _buildChatAppBar()
              : _buildListAppBar()),
      body: Column(
        children: [
          Expanded(
            child: _currentRoom != null
                ? _buildRoomChatView()
                : (_selectedChatUser != null || _messages.isNotEmpty
                    ? _buildChatView()
                    : _buildChatList()),
          ),
          if (_currentRoom != null || _selectedChatUser != null || _messages.isNotEmpty)
            _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: const TextStyle(color: Colors.white30),
          prefixIcon:
              const Icon(Icons.search, color: Colors.white38, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    HapticFeedback.lightImpact();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.clear, color: Colors.white38, size: 18),
                  ),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1F1F1F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildChatList() {
    return Column(
      children: [
        if (_showRoomList) _buildRoomsList(),
        _buildStatusRow(),
        _buildSearchBar(),
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'No conversations found'
                        : 'No conversations yet',
                    style: const TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _filteredUsers.length,
                  separatorBuilder: (_, _) => const Divider(
                      color: Color(0xFF2A2A2A),
                      height: 1,
                      indent: 76),
                  itemBuilder: (context, index) {
                    return _buildChatListTile(index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatListTile(int index) {
    final user = _filteredUsers[index];
    final isOnline = _onlineUsers.contains(user['id']);
    final isGroup = user['isGroup'] == true;
    final isTyping = _typingUsers.contains(user['id']);

    return InteractiveCard(
      onTap: () => _showUserProfile(user),
      child: ListTile(
        leading: Stack(
          children: [
            if (isGroup)
              _buildGroupAvatarStack(
                  user['members'] as List<String>? ?? [])
            else
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    (user['color'] as Color).withAlpha(40),
                child: Text(
                  user['avatar'] as String,
                  style: TextStyle(
                    fontSize:
                        (user['avatar'] as String).length > 1 ? 18 : 20,
                  ),
                ),
              ),
            if (isOnline && !isGroup)
              Positioned(
                bottom: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF141414),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withAlpha(120),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isGroup) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Group',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 9)),
              ),
            ],
            const SizedBox(width: 6),
            if (user['unread'] > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${user['unread']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            if (isTyping)
              const Expanded(
                child: Text(
                  'Typing...',
                  style: TextStyle(
                    color: Color(0xFFE50914),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else ...[
              Icon(
                _readMessageIds.contains(user['id'])
                    ? Icons.done_all
                    : Icons.check,
                size: 14,
                color: _readMessageIds.contains(user['id'])
                    ? const Color(0xFF4FC3F7)
                    : Colors.white38,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  user['lastMsg'],
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          user['time'],
          style:
              const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _chatUsers.take(6).length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (_, i) {
            final user = _chatUsers[i];
            final isOnline = _onlineUsers.contains(user['id']);
            final isGroup = user['isGroup'] == true;
            return InteractiveCard(
              onTap: () => _showUserProfile(user),
              scaleAmount: 0.9,
              child: Column(
                children: [
                  Stack(
                    children: [
                      if (isGroup)
                        _buildGroupAvatarStack(
                            user['members'] as List<String>? ?? [],
                            radius: 18)
                      else
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              (user['color'] as Color).withAlpha(40),
                          child: Text(
                            user['avatar'] as String,
                            style: TextStyle(
                              fontSize: (user['avatar'] as String)
                                      .length >
                                  1
                                  ? 14
                                  : 16,
                            ),
                          ),
                        ),
                      if (isOnline && !isGroup)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF141414),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.green.withAlpha(100),
                                        blurRadius: 3,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['name'].split(' ').first,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedChatUser != null
                            ? 'Chat with ${_selectedChatUser!['name']}'
                            : 'Chat',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Send a message to start the conversation',
                        style:
                            TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(index);
                  },
                ),
        ),
        if (_selectedChatUser != null &&
            _typingUsers.contains(_selectedChatUser!['id']))
          _buildTypingIndicator(),
      ],
    );
  }

  Widget _buildMessageBubble(int index) {
    final msg = _messages[index];
    final isMe = msg.userId == 'me';
    final user = _chatUsers.firstWhere(
      (u) => u['id'] == msg.userId,
      orElse: () =>
          {'name': 'User', 'avatar': 'U', 'color': Colors.grey},
    );
    final reactions = _messageReactions[msg.id] ?? [];
    final status = _messageStatuses[msg.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => _showUserProfile(
                  _chatUsers.firstWhere((u) => u['id'] == msg.userId,
                      orElse: () => user)),
              child: CircleAvatar(
                radius: 16,
                backgroundColor:
                    (user['color'] as Color).withAlpha(40),
                child: Text(
                  user['avatar'] as String,
                  style: TextStyle(
                    fontSize:
                        (user['avatar'] as String).length > 1 ? 12 : 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showReactionPicker(msg.id),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFFE50914)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft:
                            Radius.circular(isMe ? 18 : 4),
                        bottomRight:
                            Radius.circular(isMe ? 4 : 18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4),
                            child: Text(
                              user['name'] as String,
                              style: const TextStyle(
                                color: Color(0xFFE50914),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          msg.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(msg.createdAt),
                              style: TextStyle(
                                color: Colors.white.withAlpha(120),
                                fontSize: 10,
                              ),
                            ),
                            if (isMe && status != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                _getMessageStatusIcon(status),
                                size: 12,
                                color: status == 'read'
                                    ? const Color(0xFF4FC3F7)
                                    : Colors.white.withAlpha(120),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF1F1F1F),
                              width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final emoji in reactions)
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 1),
                                child: Text(emoji,
                                    style: const TextStyle(
                                        fontSize: 14)),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
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
              onTap: () => _showAttachmentSheet(),
              scaleAmount: 0.85,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.add,
                    color: Colors.white54, size: 20),
              ),
            ),
            const SizedBox(width: 6),
            InteractiveCard(
              onTap: _showEmojiPicker,
              scaleAmount: 0.85,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.emoji_emotions_outlined,
                    color: Colors.white54, size: 20),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
                child: const Icon(Icons.send,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
    }
    return count.toString();
  }

  PreferredSizeWidget _buildRoomAppBar() {
    final room = _currentRoom!;
    return AppBar(
      leading: InteractiveCard(
        onTap: () => setState(() => _currentRoom = null),
        scaleAmount: 0.85,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.arrow_back, color: Colors.white70),
        ),
      ),
      title: Row(
        children: [
          Text(room.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '${_formatMemberCount(room.memberCount)} members',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      actions: [
        InteractiveCard(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Room info for ${room.name}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          scaleAmount: 0.88,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.info_outline, color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: 136,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _chatRooms.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final room = _chatRooms[i];
            return InteractiveCard(
              onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Joined ${room.name} - starting chat...'),
                    backgroundColor: room.gradient.last,
                    duration: const Duration(seconds: 2),
                  ),
                );
                setState(() => _currentRoom = room);
              },
              scaleAmount: 0.92,
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: room.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(room.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 12),
                    Text(
                      room.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatMemberCount(room.memberCount)} members',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoomHeader(_ChatRoom room) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: room.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(room.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatMemberCount(room.memberCount)} members',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomChatView() {
    final room = _currentRoom!;
    final messages = _roomMessages[room.id] ?? [];
    return Column(
      children: [
        _buildRoomHeader(room),
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${room.icon}  ${room.name}',
                        style: const TextStyle(color: Colors.white38, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Send a message to start the conversation',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildRoomMessageBubble(messages[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoomMessageBubble(ChatMessageModel msg) {
    final isMe = msg.userId == 'me' || msg.userId == (authService.currentUser?.id ?? guestService.guestId);
    final reactions = _messageReactions[msg.id] ?? [];
    final status = _messageStatuses[msg.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF2A2A2A),
              child: Text(
                msg.username.isNotEmpty ? msg.username[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showReactionPicker(msg.id),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
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
                            child: Text(
                              msg.username,
                              style: const TextStyle(
                                color: Color(0xFFE50914),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          msg.content,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(msg.createdAt),
                              style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 10),
                            ),
                            if (isMe && status != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                _getMessageStatusIcon(status),
                                size: 12,
                                color: status == 'read' ? const Color(0xFF4FC3F7) : Colors.white.withAlpha(120),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1F1F1F), width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final emoji in reactions)
                              Padding(
                                padding: const EdgeInsets.only(right: 1),
                                child: Text(emoji, style: const TextStyle(fontSize: 14)),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  IconData _getMessageStatusIcon(String status) {
    switch (status) {
      case 'read':
        return Icons.done_all;
      case 'delivered':
        return Icons.done_all;
      case 'sent':
      default:
        return Icons.check;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
