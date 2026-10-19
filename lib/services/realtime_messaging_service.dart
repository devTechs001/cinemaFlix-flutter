import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_config.dart';
import 'globals.dart';
import 'sound_service.dart';

class RealtimeMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String type;

  RealtimeMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type = 'text',
  });
}

class RealtimeComment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime timestamp;
  int likes;

  RealtimeComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timestamp,
    this.likes = 0,
  });
}

class RealtimeMessagingService extends ChangeNotifier {
  final Map<String, List<RealtimeMessage>> _conversations = {};
  final Map<String, List<RealtimeComment>> _comments = {};
  final List<Map<String, dynamic>> _onlineUsers = [];
  final List<Map<String, dynamic>> _typingUsers = [];
  Timer? _simulatedMessageTimer;
  Timer? _wsReconnectTimer;
  final Random _random = Random();
  bool _isConnected = false;
  WebSocketChannel? _channel;
  String _myUserId = '';

  bool get isConnected => _isConnected;
  List<Map<String, dynamic>> get onlineUsers => List.unmodifiable(_onlineUsers);
  List<Map<String, dynamic>> get typingUsers => List.unmodifiable(_typingUsers);

  List<String> get conversationIds => _conversations.keys.toList();

  List<RealtimeMessage> getMessages(String conversationId) {
    return _conversations[conversationId] ?? [];
  }

  List<RealtimeComment> getComments(String contentId) {
    return _comments[contentId] ?? [];
  }

  /// Connects to the CinemaFlix backend WebSocket gateway (`/ws`). Falls back
  /// to the local-only mode when the backend is unreachable — the
  /// conversations/comments API stays identical either way.
  void connect({String? userId, String? userName, String? token}) async {
    void optimistic() {
      if (!_isConnected) {
        _isConnected = true;
        notifyListeners();
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = token ?? prefs.getString('auth_token');
      String id = userId ?? '';
      String name = userName ?? 'Cinema Fan';
      if (id.isEmpty && prefs.getString('auth_user') != null) {
        final user = jsonDecode(prefs.getString('auth_user')!) as Map<String, dynamic>;
        id = user['id']?.toString() ?? '';
        name = (user['username']?.toString()) ?? name;
      }
      _myUserId = id;
      final wsBase = ApiConfig.baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final query = tokenParmeter(savedToken, id, name);
      _channel = WebSocketChannel.connect(Uri.parse('$wsBase/ws$query'));
      _channel!.stream.listen(_onWsMessage, onDone: () {
        _isConnected = false;
        _scheduleReconnect(userId: id, userName: name, token: savedToken);
        notifyListeners();
      }, onError: (_) {
        _isConnected = false;
        _scheduleReconnect(userId: id, userName: name, token: savedToken);
        notifyListeners();
      });
      optimistic();
    } catch (e) {
      debugPrint('RealtimeMessagingService: ws connect failed, local mode: $e');
      optimistic();
    }
  }

  String tokenParmeter(String? token, String id, String name) {
    if (token != null && token.isNotEmpty) return '?token=${Uri.encodeComponent(token)}';
    return '?userId=${Uri.encodeComponent(id)}&userName=${Uri.encodeComponent(name)}';
  }

  void _scheduleReconnect({String? userId, String? userName, String? token}) {
    _wsReconnectTimer?.cancel();
    _wsReconnectTimer = Timer(const Duration(seconds: 5), () {
      connect(userId: userId, userName: userName, token: token);
    });
  }

  void _onWsMessage(dynamic raw) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw.toString()) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (data['type']) {
      case 'presence':
        final list = data['online'];
        if (list is List) setOnlineUsers(List<Map<String, dynamic>>.from(list));
        break;
      case 'message':
        final room = data['room']?.toString() ?? 'general';
        final msg = RealtimeMessage(
          id: data['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: data['senderId']?.toString() ?? '',
          senderName: data['senderName']?.toString() ?? 'user',
          text: data['text']?.toString() ?? '',
          timestamp: DateTime.tryParse(data['ts']?.toString() ?? '') ?? DateTime.now(),
        );
        // The server relays the sender's own message back; skip to avoid a
        // duplicate of the optimistic local echo.
        final alreadyThere = (_conversations[room] ?? []).any((m) => m.id == msg.id);
        final ownEcho = msg.senderId.isNotEmpty && msg.senderId == _myUserId;
        if (!alreadyThere && !ownEcho) {
          _conversations.putIfAbsent(room, () => []);
          _conversations[room]!.add(msg);
          saveRoomMessages(room, _conversations[room]!);
          soundService.play(SoundEvent.comment);
          notifyListeners();
        }
        break;
      case 'typing':
        setTyping(data['room']?.toString() ?? 'general', data['userName']?.toString() ?? 'someone');
        break;
      case 'notification':
        soundService.play(SoundEvent.notification);
        break;
      default:
        break;
    }
  }

  /// Tells the backend gateway which room this client is listening to so
  /// messages relayed to it can be surfaced through [getMessages].
  void joinRoom(String conversationId) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode({'type': 'join', 'room': conversationId}));
    } catch (e) {
      debugPrint('RealtimeMessagingService: join failed: $e');
    }
  }

  void disconnect() {
    _wsReconnectTimer?.cancel();
    _simulatedMessageTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    notifyListeners();
  }

  void sendMessage(String conversationId, String senderId, String senderName, String text) {
    final msg = RealtimeMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );
    _conversations.putIfAbsent(conversationId, () => []);
    _conversations[conversationId]!.add(msg);
    notifyListeners();
    // Relay through the backend WS when connected (rooms joined by chat UI);
    // local mode keeps conversation history only.
    final channel = _channel;
    if (channel != null) {
      try {
        channel.sink.add(jsonEncode({'type': 'message', 'room': conversationId, 'text': text}));
      } catch (e) {
        debugPrint('RealtimeMessagingService: send relaying failed: $e');
      }
    }
  }

  void addComment(String contentId, String userId, String userName, String text) {
    final comment = RealtimeComment(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userAvatar: userName.isNotEmpty ? userName[0].toUpperCase() : '?',
      text: text,
      timestamp: DateTime.now(),
    );
    _comments.putIfAbsent(contentId, () => []);
    _comments[contentId]!.insert(0, comment);
    notifyListeners();
  }

  void likeComment(String contentId, String commentId) {
    final comments = _comments[contentId];
    if (comments == null) return;
    final idx = comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    comments[idx].likes++;
    notifyListeners();
  }

  void setOnlineUsers(List<Map<String, dynamic>> users) {
    _onlineUsers
      ..clear()
      ..addAll(users);
    notifyListeners();
  }

  void setTyping(String conversationId, String userName) {
    _typingUsers.removeWhere((u) => u['conversation'] == conversationId);
    _typingUsers.add({'conversation': conversationId, 'userName': userName});
    notifyListeners();
    final channel = _channel;
    if (channel != null) {
      try {
        channel.sink.add(jsonEncode({'type': 'typing', 'room': conversationId}));
      } catch (_) {}
    }
    Future.delayed(const Duration(seconds: 2), () {
      _typingUsers.removeWhere((u) => u['conversation'] == conversationId);
      notifyListeners();
    });
  }

  void startSimulatedMessages(String conversationId) {
    _simulatedMessageTimer?.cancel();
    _simulatedMessageTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      final botResponses = [
        'That\'s a great movie choice!',
        'I love that one too!',
        'Have you seen the director\'s other work?',
        'The cinematography in that film is amazing.',
        'I could watch that again and again.',
        'The soundtrack is incredible!',
        'That scene always gives me chills.',
        'Definitely in my top 10.',
      ];
      final text = botResponses[_random.nextInt(botResponses.length)];
      sendMessage(conversationId, 'bot_ai', 'MovieBot', text);
    });
  }

  void stopSimulatedMessages() {
    _simulatedMessageTimer?.cancel();
  }

  Future<void> saveRoomMessages(String roomId, List<RealtimeMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final data = messages.map((m) => jsonEncode({
      'id': m.id,
      'senderId': m.senderId,
      'senderName': m.senderName,
      'text': m.text,
      'timestamp': m.timestamp.toIso8601String(),
      'type': m.type,
    })).toList();
    await prefs.setStringList('room_messages_$roomId', data);
  }

  Future<List<RealtimeMessage>> loadRoomMessages(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('room_messages_$roomId');
    if (data == null) return [];
    return data.map((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return RealtimeMessage(
        id: map['id'] as String,
        senderId: map['senderId'] as String,
        senderName: map['senderName'] as String,
        text: map['text'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        type: map['type'] as String? ?? 'text',
      );
    }).toList();
  }

  void addRoomMessage(String roomId, RealtimeMessage message) {
    _conversations.putIfAbsent(roomId, () => []);
    _conversations[roomId]!.add(message);
    notifyListeners();
    saveRoomMessages(roomId, _conversations[roomId]!);
  }

  @override
  void dispose() {
    _simulatedMessageTimer?.cancel();
    _wsReconnectTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

final realtimeMessagingService = RealtimeMessagingService();
