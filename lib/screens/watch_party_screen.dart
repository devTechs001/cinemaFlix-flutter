import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/watch_party_service.dart';
import '../widgets/interactive_card.dart';

class WatchPartyScreen extends StatefulWidget {
  final String movieId;
  final String movieTitle;
  const WatchPartyScreen({super.key, required this.movieId, required this.movieTitle});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final _service = watchPartyService;
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isHost = false;
  Timer? _mockJoinTimer;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
    _initParty();
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _mockJoinTimer?.cancel();
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _initParty() async {
    await _service.createParty(widget.movieId, widget.movieTitle, 'You');
    _isHost = true;
    _mockJoinTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_service.currentParty != null && _service.currentParty!.users.length < 4) {
        _service.joinParty(_service.currentParty!.id, 'User${_service.currentParty!.users.length + 1}');
      }
    });
  }

  String _posStr(Duration d) {
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final party = _service.currentParty;
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.movieTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (party != null)
              Text('${party.users.length} watching', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11)),
          ],
        ),
        actions: [
          if (party != null && _isHost)
            InteractiveCard(
              onTap: () {
                HapticFeedback.mediumImpact();
                _service.togglePlayPause();
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(party.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white70),
              ),
            ),
          InteractiveCard(
            onTap: () {
              HapticFeedback.mediumImpact();
              _service.leaveParty();
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.exit_to_app, color: Color(0xFFE50914)),
            ),
          ),
        ],
      ),
      body: party == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : Column(
              children: [
                _buildPartyBar(party),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                Expanded(child: _buildChatArea(party)),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildPartyBar(WatchParty party) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 80,
                    color: Colors.black,
                    child: Center(
                      child: Icon(Icons.movie_outlined, color: Colors.white.withAlpha(60), size: 32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_posStr(party.position), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(party.isPlaying ? '● LIVE' : '⏸ Paused', style: TextStyle(color: party.isPlaying ? const Color(0xFFE50914) : Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: party.users.map((u) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: u.isOnline ? const Color(0xFFE50914).withAlpha(30) : Colors.white10,
                child: Text(u.name[0], style: TextStyle(color: u.isOnline ? const Color(0xFFE50914) : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(WatchParty party) {
    if (party.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, color: Colors.white.withAlpha(40), size: 56),
            const SizedBox(height: 12),
            Text('No messages yet', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 15)),
            Text('Start the conversation!', style: TextStyle(color: Colors.white.withAlpha(50), fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: party.messages.length,
      itemBuilder: (context, index) {
        final msg = party.messages[index];
        final isMe = msg.userId == 'host';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white.withAlpha(15),
                  child: Text(msg.userName[0], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      bottomLeft: !isMe ? Radius.zero : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Text(msg.userName, style: const TextStyle(color: Color(0xFFE50914), fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
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

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        color: Color(0xFF1F1F1F),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          InteractiveCard(
            onTap: () => _sendMessage(_messageCtrl.text),
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _service.sendMessage(text.trim());
    _messageCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }
}
