import 'dart:async';
import 'package:flutter/foundation.dart';

class WatchPartyUser {
  final String id;
  final String name;
  final String avatar;
  bool isHost;
  bool isReady;
  bool isOnline;

  WatchPartyUser({
    required this.id,
    required this.name,
    this.avatar = '',
    this.isHost = false,
    this.isReady = false,
    this.isOnline = true,
  });
}

class WatchPartyMessage {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;

  WatchPartyMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class WatchParty {
  final String id;
  final String movieId;
  final String movieTitle;
  final List<WatchPartyUser> users;
  final List<WatchPartyMessage> messages;
  bool isPlaying;
  Duration position;
  bool isPaused;

  WatchParty({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    this.users = const [],
    this.messages = const [],
    this.isPlaying = false,
    this.position = Duration.zero,
    this.isPaused = false,
  });
}

class WatchPartyService extends ChangeNotifier {
  WatchParty? _currentParty;
  Timer? _syncTimer;

  WatchParty? get currentParty => _currentParty;

  Future<WatchParty> createParty(String movieId, String movieTitle, String hostName) async {
    final party = WatchParty(
      id: 'party_${DateTime.now().millisecondsSinceEpoch}',
      movieId: movieId,
      movieTitle: movieTitle,
      users: [
        WatchPartyUser(id: 'host', name: hostName, isHost: true, isOnline: true),
      ],
    );
    _currentParty = party;
    _startSync();
    notifyListeners();
    return party;
  }

  void joinParty(String partyId, String userName) {
    if (_currentParty == null) return;
    _currentParty!.users.add(WatchPartyUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: userName,
      isOnline: true,
    ));
    notifyListeners();
  }

  void sendMessage(String text) {
    if (_currentParty == null) return;
    _currentParty!.messages.add(WatchPartyMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'host',
      userName: 'You',
      text: text,
    ));
    notifyListeners();
  }

  void togglePlayPause() {
    if (_currentParty == null) return;
    _currentParty!.isPlaying = !_currentParty!.isPlaying;
    _currentParty!.isPaused = !_currentParty!.isPaused;
    notifyListeners();
  }

  void seekTo(Duration position) {
    if (_currentParty == null) return;
    _currentParty!.position = position;
    notifyListeners();
  }

  void leaveParty() {
    _syncTimer?.cancel();
    _currentParty = null;
    notifyListeners();
  }

  void _startSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_currentParty != null && _currentParty!.isPlaying) {
        _currentParty!.position += const Duration(seconds: 2);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

final watchPartyService = WatchPartyService();
