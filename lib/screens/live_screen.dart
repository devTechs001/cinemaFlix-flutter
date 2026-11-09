import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../services/backend_api_service.dart';
import '../widgets/interactive_card.dart';
import '../widgets/real_me_bridge.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  int _viewerCount = 1284;
  String _currentRoom = 'Sci-Fi Night';
  bool _showRoomDetail = false;
  String _selectedCategory = 'All';
  bool _isHost = false;
  bool _isMicOn = true;
  bool _isStreamLive = true;
  Map<String, dynamic>? _selectedRoom;
  Timer? _refreshTimer;
  bool _loadingRooms = false;

  // Reactions
  final List<_FloatingReaction> _reactions = [];
  Timer? _reactionTimer;
  final List<String> _reactionEmojis = ['❤️', '🔥', '👏', '😂', '😮', '😍', '🎬', '🍿'];

  // Gift system
  int _diamonds = 500;

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
    // Real rooms from the backend, kept fresh while the screen is open.
    _loadLiveRooms();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_showRoomDetail) _loadLiveRooms();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _reactionTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Loads live rooms created through the backend and merges them into
  /// the list (existing rooms get refreshed viewer counts; new rooms are
  /// prepended). Demo rooms stay as offline fallback content.
  Future<void> _loadLiveRooms() async {
    if (_loadingRooms) return;
    _loadingRooms = true;
    try {
      final remote = await BackendApiService.getLiveRooms();
      if (!mounted || remote.isEmpty) return;
      setState(() {
        for (final raw in remote) {
          final id = (raw['callId'] ?? raw['call_id'])?.toString();
          if (id == null || id.isEmpty) continue;
          final ui = _adaptRemoteRoom(raw, id);
          final idx = _liveRooms.indexWhere((r) => r['call_id'] == id);
          if (idx >= 0) {
            _liveRooms[idx] = {
              ..._liveRooms[idx],
              'viewers': ui['viewers'],
              'name': ui['name'],
              'host': ui['host'],
              'active': ui['active'],
            };
          } else {
            _liveRooms.insert(0, ui);
          }
        }
        // Keep the currently open room object in sync.
        if (_selectedRoom?['call_id'] != null) {
          final openId = _selectedRoom!['call_id'];
          final match = _liveRooms.where((r) => r['call_id'] == openId);
          if (match.isNotEmpty) _selectedRoom = match.first;
        }
      });
    } finally {
      _loadingRooms = false;
    }
  }

  /// Maps the backend room JSON (see `liveRoomJSON` in systems.js) onto
  /// the card/detail shape the UI uses.
  Map<String, dynamic> _adaptRemoteRoom(Map<String, dynamic> raw, String id) {
    const palette = [
      Color(0xFFE50914), Color(0xFF1E88E5), Color(0xFF7B1FA2),
      Color(0xFF43A047), Color(0xFFFF6F00), Color(0xFF00ACC1),
    ];
    return {
      'name': (raw['title'] ?? 'Live room').toString(),
      'host': (raw['hostName'] ?? 'Host').toString(),
      'viewers': (raw['viewers'] as num?)?.toInt() ?? 0,
      'movie': (raw['topic'] ?? raw['movie'] ?? 'Watch party').toString(),
      'color': palette[id.hashCode.abs() % palette.length],
      'active': (raw['status'] ?? 'live') == 'live',
      'tags': ['Live'],
      'call_id': id,
      'host_id': (raw['hostId'] ?? raw['host_id'])?.toString(),
      'requires_approval': raw['requiresApproval'] == true,
    };
  }

  /// Ends the host's stream for real: tells the backend (best effort),
  /// closes the room view and drops the room from the grid.
  Future<void> _endLiveStream() async {
    final callId = _selectedRoom?['call_id']?.toString();
    var ended = true;
    if (callId != null && callId.isNotEmpty) {
      ended = await BackendApiService.endLiveRoom(callId);
    }
    if (!mounted) return;
    setState(() {
      _isStreamLive = false;
      _showRoomDetail = false;
      if (ended && callId != null && callId.isNotEmpty) {
        _liveRooms.removeWhere((r) => r['call_id'] == callId);
      }
      _selectedRoom = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ended ? '🔴 Stream ended' : 'Stream ended locally (backend offline)'),
        backgroundColor: const Color(0xFFE50914),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
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

  // ---- Live rooms: join-request / owner approval wiring ----

  bool _isRoomOwner(Map<String, dynamic> room) {
    final hostId = room['host_id']?.toString();
    if (hostId != null && hostId.isNotEmpty) {
      return authService.currentUser?.id == hostId;
    }
    final user = authService.currentUser;
    return room['call_id'] != null && room['host'] == (user?.username ?? 'You');
  }

  Future<void> _joinLiveRoom(Map<String, dynamic> room) async {
    HapticFeedback.mediumImpact();
    final callId = room['call_id'];
    final user = authService.currentUser;
    var joined = false;
    var needsApproval = false;
    if (callId != null) {
      BackendApiService.joinLiveRoom(callId);
      final result = await BackendApiService.requestLiveJoin(
        callId,
        userId: user?.id,
        userName: user?.username ?? 'Viewer',
      );
      if (result == null) {
        joined = true; // backend down — open room locally
      } else if (result['approved'] == true) {
        joined = true;
      } else {
        needsApproval = true;
      }
    } else {
      joined = true;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          needsApproval
              ? '⏳ Join request sent — waiting for \'${room['host']}\' to approve'
              : joined
                  ? 'Joined ${room['name']}!'
                  : 'Could not join room',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showRequestsSheet(Map<String, dynamic> room) async {
    HapticFeedback.lightImpact();
    List<Map<String, dynamic>> requests = [];
    if (room['call_id'] != null) {
      requests = await BackendApiService.getLiveJoinRequests(
        room['call_id'],
        userId: authService.currentUser?.id,
      );
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            Future<void> decide(int index, bool approve) async {
              final req = requests[index]['id'];
              if (req == null) return;
              final ok = await BackendApiService.decideLiveJoinRequest(
                req,
                approve: approve,
                userId: authService.currentUser?.id,
              );
              setSheetState(() {
                if (ok) requests.removeAt(index);
              });
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(approve ? '✅ Viewer approved — token issued' : 'Request rejected'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Join requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('Room: ${room['name']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 14),
                  if (requests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No pending requests', style: TextStyle(color: Colors.white38))),
                    )
                  else
                    ...requests.asMap().entries.map((entry) {
                      final i = entry.key;
                      final req = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF2A2A2A),
                              child: Icon(Icons.person, color: Colors.white54, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(req['userName'] ?? 'Viewer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  Text('requested to join', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => decide(i, false),
                              child: const Text('Reject', style: TextStyle(color: Colors.white38)),
                            ),
                            ElevatedButton(
                              onPressed: () => decide(i, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE50914),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedBanner() {
    final featured = _liveRooms.firstWhere((r) => r['active'] == true, orElse: () => _liveRooms.first);
    return GestureDetector(
      onTap: () => setState(() {
        _showRoomDetail = true;
        _currentRoom = featured['name'] as String;
      }),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [(featured['color'] as Color).withValues(alpha: 0.8), const Color(0xFF141414)],
          ),
          border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.4)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20, bottom: -20,
              child: Icon(Icons.live_tv, size: 120, color: Colors.white.withValues(alpha: 0.06)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 6),
                        Text('FEATURED LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(featured['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${featured['host']} · ${featured['viewers']} watching · ${featured['movie']}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoLiveDialog() {
    HapticFeedback.lightImpact();
    final titleController = TextEditingController(text: 'My Live Stream');
    final movieController = TextEditingController();
    String selectedCategory = 'Movies';
    bool requireApproval = false;

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
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                    child: const Center(child: SizedBox(width: 5, height: 5, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                  ),
                  const SizedBox(width: 8),
                  const Text('Go Live', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Stream Title',
                  labelStyle: const TextStyle(color: Colors.white38),
                  hintText: 'Enter a title for your stream',
                  hintStyle: const TextStyle(color: Colors.white24),
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
              TextField(
                controller: movieController,
                decoration: InputDecoration(
                  labelText: 'Movie / Topic',
                  labelStyle: const TextStyle(color: Colors.white38),
                  hintText: 'What are you watching?',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Category', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Movies', 'Gaming', 'Music', 'Chat', 'Education', 'Sports'].map((cat) {
                  final isSelected = cat == selectedCategory;
                  return InteractiveCard(
                    onTap: () => setDialogState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(cat, style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white54, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Require approval to join', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ),
                  Switch(
                    value: requireApproval,
                    activeThumbColor: const Color(0xFFE50914),
                    onChanged: (v) => setDialogState(() => requireApproval = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx);

                    final user = authService.currentUser;
                    final result = await BackendApiService.createLiveRoom(
                      title: titleController.text.trim(),
                      userId: user?.id,
                      userName: user?.username ?? 'You',
                      requiresApproval: requireApproval,
                    );

                    final newRoom = {
                      'name': titleController.text.trim(),
                      'host': user?.username ?? 'You',
                      'viewers': 0,
                      'movie': movieController.text.trim().isNotEmpty
                          ? movieController.text.trim()
                          : 'Live Stream',
                      'color': const Color(0xFFE50914),
                      'active': true,
                      'tags': ['New'],
                      if (result != null) 'call_id': result['call_id'],
                    };
                    if (!mounted) return;
                    setState(() {
                      _liveRooms.insert(0, newRoom);
                      _selectedCategory = 'All';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result != null
                              ? '🔴 You are live!'
                              : 'Stream started locally (backend unavailable)',
                        ),
                        backgroundColor: const Color(0xFFE50914),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: const Text('Start Stream', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
            onTap: () => _showGoLiveDialog(),
            scaleAmount: 0.88,
            child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.video_call_outlined, color: Colors.white54)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFeaturedBanner(),
          const RealMeBridge(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6C2BD9).withAlpha(15), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              dense: true,
              leading: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C2BD9), shape: BoxShape.circle,
                ),
              ),
              title: const Text('Go Live on RealMe',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('Stream with real-time chat, gifts & stickers',
                  style: const TextStyle(fontSize: 11)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C2BD9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Stream',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              onTap: _showGoLiveDialog,
            ),
          ),
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
    return RefreshIndicator(
      color: const Color(0xFFE50914),
      onRefresh: _loadLiveRooms,
      child: GridView.builder(
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
              _selectedRoom = room;
              _isHost = _isRoomOwner(room);
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
                        Flexible(child: Text('${room['viewers']} watching', style: const TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        const Icon(Icons.mic, color: Colors.white24, size: 12),
                        const SizedBox(width: 3),
                        Flexible(child: Text(room['host'], style: const TextStyle(color: Colors.white24, fontSize: 11), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
              ],
            ),
          ),
        );
      },
    );
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
            Row(
              children: [
                Text(room['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                ),
              ],
            ),
            Row(
              children: [
                Text('${room['viewers']} watching', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(4)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi, color: Color(0xFF10B981), size: 10),
                      SizedBox(width: 2),
                      Text('HD', style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          InteractiveCard(
            onTap: () => _showGiftSheet(room),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withAlpha(30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE50914).withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Color(0xFFE50914), size: 14),
                  const SizedBox(width: 4),
                  Text('$_diamonds', style: const TextStyle(color: Color(0xFFE50914), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          if (_isRoomOwner(room))
            InteractiveCard(
              onTap: () => _showRequestsSheet(room),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.people_alt, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text('Requests', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          InteractiveCard(
            onTap: () => _joinLiveRoom(room),
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
            child: Stack(
              children: [
                Container(
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
                  width: 240, height: 140,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (room['color'] as Color).withAlpha(80), width: 1),
                    image: const DecorationImage(
                      image: NetworkImage('https://picsum.photos/seed/livestream/800/450'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: (room['color'] as Color).withAlpha(60),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(Icons.play_arrow, color: room['color'], size: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(room['movie'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                _buildReactionBar(room),
                const SizedBox(height: 16),
                _buildHostControls(),
                    ],
                  ),
                ),
                ..._reactions.map((r) => Positioned(
                  top: 20 + (r.id % 100).toDouble(),
                  right: 20 + (r.id % 60).toDouble(),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(seconds: 2),
                    builder: (_, value, __) => Opacity(
                      opacity: 1 - value,
                      child: Transform.translate(
                        offset: Offset(0, -value * 80),
                        child: Text(r.emoji, style: TextStyle(fontSize: 24 + value * 16)),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
          _buildRoomChat(),
        ],
      ),
    );
  }

  Widget _buildReactionBar(Map<String, dynamic> room) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ..._reactionEmojis.take(4).map((e) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InteractiveCard(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _reactions.add(_FloatingReaction(emoji: e, id: DateTime.now().millisecondsSinceEpoch)));
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) setState(() => _reactions.removeAt(0));
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            ),
          )),
          const SizedBox(width: 8),
          _actionChip(Icons.thumb_up, 'Like'),
          const SizedBox(width: 8),
          InteractiveCard(
            onTap: () => _showGiftSheet(room),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE50914).withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.card_giftcard, color: Color(0xFFE50914), size: 16),
                  SizedBox(width: 4),
                  Text('Gift', style: TextStyle(color: Color(0xFFE50914), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InteractiveCard(
            onTap: () {
              HapticFeedback.lightImpact();
              _showShareSheet(room);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.share, color: Colors.white54, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InteractiveCard(
            onTap: () => setState(() => _isMicOn = !_isMicOn),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isMicOn ? Colors.white.withAlpha(15) : const Color(0xFFE50914).withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isMicOn ? Icons.mic : Icons.mic_off,
                color: _isMicOn ? Colors.white54 : const Color(0xFFE50914),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InteractiveCard(
            onTap: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🎥 Screen shared!'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.screen_share_outlined, color: Colors.white54, size: 20),
            ),
          ),
          if (_isHost) ...[
            const SizedBox(width: 8),
            InteractiveCard(
              onTap: () {
                HapticFeedback.heavyImpact();
                if (_isStreamLive) {
                  _endLiveStream();
                  return;
                }
                setState(() => _isStreamLive = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🔴 Stream resumed'),
                    backgroundColor: const Color(0xFFE50914),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isStreamLive ? Colors.white.withAlpha(15) : const Color(0xFFE50914).withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isStreamLive ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                  color: _isStreamLive ? const Color(0xFFE50914) : const Color(0xFF10B981),
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showGiftSheet(Map<String, dynamic> room) {
    HapticFeedback.lightImpact();
    final gifts = [
      {'emoji': '🎬', 'name': 'Popcorn', 'cost': 10},
      {'emoji': '🍿', 'name': 'Soda', 'cost': 25},
      {'emoji': '🎟️', 'name': 'Ticket', 'cost': 50},
      {'emoji': '🌟', 'name': 'Star', 'cost': 100},
      {'emoji': '👑', 'name': 'Crown', 'cost': 250},
      {'emoji': '🚀', 'name': 'Rocket', 'cost': 500},
      {'emoji': '💎', 'name': 'Diamond Ring', 'cost': 1000},
      {'emoji': '🏆', 'name': 'Trophy', 'cost': 2500},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Send a Gift', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(30), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.diamond, color: Color(0xFFE50914), size: 14),
                      const SizedBox(width: 4),
                      Text('$_diamonds', style: const TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: gifts.length,
              itemBuilder: (_, i) {
                final gift = gifts[i];
                final canAfford = _diamonds >= (gift['cost'] as int);
                return InteractiveCard(
                  onTap: canAfford ? () {
                    setState(() => _diamonds -= gift['cost'] as int);
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sent ${gift['emoji']} ${gift['name']} to ${room['host']}!'),
                        backgroundColor: const Color(0xFFE50914),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: canAfford ? Colors.white.withAlpha(10) : Colors.white.withAlpha(5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: canAfford ? Colors.white10 : Colors.white.withAlpha(5)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(gift['emoji'] as String, style: TextStyle(fontSize: 28, color: Colors.white.withAlpha(canAfford ? 255 : 100))),
                        const SizedBox(height: 4),
                        Text(gift['name'] as String, style: TextStyle(color: canAfford ? Colors.white70 : Colors.white30, fontSize: 10)),
                        Text('💎${gift['cost']}', style: TextStyle(color: canAfford ? const Color(0xFFE50914) : Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(Map<String, dynamic> room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Text('Share Stream', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareOption(Icons.share, 'Share', Colors.blue, () => Navigator.pop(ctx)),
                _shareOption(Icons.link, 'Copy Link', Colors.teal, () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied'), behavior: SnackBarBehavior.floating)); }),
                _shareOption(Icons.person_add, 'Invite', const Color(0xFF7B1FA2), () => Navigator.pop(ctx)),
                _shareOption(Icons.whatshot, 'WhatsApp', const Color(0xFF25D366), () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, {Color? color}) {
    return InteractiveCard(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label action'), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color?.withAlpha(40) ?? Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: color != null ? Border.all(color: color.withAlpha(100)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white54, size: 16),
            const SizedBox(width: 4),
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
                Row(
                  children: [
                    InteractiveCard(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final emoji = _reactionEmojis[DateTime.now().millisecondsSinceEpoch % _reactionEmojis.length];
                        setState(() => _messages.insert(0, {'user': 'You', 'msg': emoji, 'time': 'now'}));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.emoji_emotions_outlined, color: Colors.white38, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${_messages.length}', style: const TextStyle(color: Colors.white24, fontSize: 11)),
                  ],
                ),
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
                final isEmoji = (msg['msg'] as String).length <= 2 && (msg['msg'] as String).codeUnitAt(0) > 0x2000;
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
                            Text(msg['msg'], style: TextStyle(color: isEmoji ? Colors.white : Colors.white70, fontSize: isEmoji ? 24 : 12)),
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

class _FloatingReaction {
  final String emoji;
  final int id;
  _FloatingReaction({required this.emoji, required this.id});
}
