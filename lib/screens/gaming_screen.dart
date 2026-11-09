import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/globals.dart';
import '../services/sound_service.dart';
import 'package:cinemaflix/services/wallet_service.dart';

/// Gaming system — casual games paid with wallet diamonds, with payouts wired
/// straight back into the user's wallet (per bugs.txt "gaming system as well
/// needed (real points, gifts, sounds, currency, deposits, payments,
/// conversions)"). Includes a live leaderboard.
class GamingScreen extends StatefulWidget {
  const GamingScreen({super.key});

  @override
  State<GamingScreen> createState() => _GamingScreenState();
}

class _GamingScreenState extends State<GamingScreen> {
  List<Map<String, dynamic>> _games = [];
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic>? _lastResult;
  bool _loading = true;
  bool _playing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final games = await _api('/games');
      final lb = await _api('/games/leaderboard');
      _games = List<Map<String, dynamic>>.from((games['games'] as List?) ?? []);
      _leaderboard = List<Map<String, dynamic>>.from((lb['leaderboard'] as List?) ?? []);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (_games.isEmpty) {
      _games = [
        {'id': 'quiz_blitz', 'name': 'CineQuiz Blitz', 'entryDiamonds': 2, 'description': 'Answer movie trivia fast for diamonds'},
        {'id': 'spin_reel', 'name': 'Reel Spinner', 'entryDiamonds': 5, 'description': 'Spin the reel — win diamonds up to 10x'},
        {'id': 'guess_frames', 'name': 'Guess the Frames', 'entryDiamonds': 3, 'description': 'Guess the movie from blurred frames'},
      ];
    }
    setState(() => _loading = false);
  }

  Future<void> _play(Map<String, dynamic> game) async {
    final userId = authService.currentUser?.id;
    setState(() => _playing = true);
    soundService.play(SoundEvent.success);
    try {
      final res = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/games/${game['id']}/play')),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${authService.token ?? ''}',
              'x-user-id': userId ?? '',
            },
            body: jsonEncode({'username': authService.currentUser?.username}),
          )
          .timeout(const Duration(seconds: 10));
      final decoded = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) throw Exception(decoded['error'] ?? 'HTTP ${res.statusCode}');
      _lastResult = decoded;
      final win = decoded['outcome'] == 'win';
      soundService.play(win ? SoundEvent.celebrate : SoundEvent.popups);
      final remote = decoded['wallet'];
      if (remote is Map<String, dynamic>) walletService.applyRemote(remote);
      if (win) {
        notificationService.notifyWallet(
          title: 'Arcade win',
          body: '+◆ ${decoded['reward']} on ${game['name']}',
        );
      }
      await _refresh();
      if (!mounted) return;
      _showSnack(win ? '🎉 You won ◆ ${decoded['reward']}' : 'Round lost — ◆ ${(decoded['reward'] as num?)?.toInt() ?? 0} won');
    } catch (e) {
      // Offline / unauth: play against the local wallet so arcade still works.
      final entry = (game['entryDiamonds'] as num?)?.toInt() ?? 2;
      if (!walletService.spendDiamonds(entry, 'Arcade: ${game['name']}')) {
        _showSnack('Need ◆ $entry to play');
      } else {
        final roll = DateTime.now().millisecond % 100;
        final win = roll < 40;
        final reward = win ? entry * (roll < 8 ? 10 : 2) : 0;
        if (reward > 0) walletService.addDiamonds(reward, 'Arcade win: ${game['name']}');
        _lastResult = {'outcome': win ? 'win' : 'lose', 'reward': reward, 'multiplier': win ? reward / entry : 0};
        soundService.play(win ? SoundEvent.celebrate : SoundEvent.popups);
        if (win) {
          notificationService.notifyWallet(title: 'Arcade win', body: '+◆ $reward on ${game['name']}');
        }
        _showSnack(win ? '🎉 You won ◆ $reward' : 'Round lost');
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>> _api(String path) async {
    final res = await http.get(Uri.parse(ApiConfig.apiPath(path)), headers: _headers).timeout(const Duration(seconds: 8));
    final decoded = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw Exception(decoded['error'] ?? 'HTTP ${res.statusCode}');
    return decoded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Row(children: [
          Icon(Icons.sports_esports, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Text('Arcade', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          ListenableBuilder(
            listenable: walletService,
            builder: (_, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('◆ ${walletService.diamonds}',
                    style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFE50914).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFE50914), fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                if (_lastResult != null) _resultBanner(),
                ..._games.map(_gameCard),
                const SizedBox(height: 16),
                _leaderboardCard(),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _resultBanner() {
    final win = _lastResult!['outcome'] == 'win';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (win ? const Color(0xFF10B981) : const Color(0xFFE50914)).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (win ? const Color(0xFF10B981) : const Color(0xFFE50914)).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(win ? Icons.emoji_events : Icons.casino, color: win ? const Color(0xFF10B981) : const Color(0xFFE50914)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              win ? 'Win! +◆ ${_lastResult!['reward']} ×${_lastResult!['multiplier']}' : 'No luck this round — your wallet was updated',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameCard(Map<String, dynamic> game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.casino, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${game['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${game['description']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                Text('Entry: ◆ ${game['entryDiamonds']}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _playing ? null : () => _play(game),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LEADERBOARD', style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_leaderboard.isEmpty)
            const Padding(padding: EdgeInsets.all(12), child: Text('Play a round to appear here', style: TextStyle(color: Colors.white24, fontSize: 12)))
          else
            ..._leaderboard.take(10).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('#${i + 1}', style: TextStyle(color: i < 3 ? const Color(0xFFF59E0B) : Colors.white38, fontWeight: FontWeight.bold)),
                    Expanded(child: Text('${row['username']}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('◆ ${row['diamondsWon']}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 13)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}
