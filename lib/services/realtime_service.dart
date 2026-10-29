import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import 'supabase_service.dart';

/// Community chat over Supabase Realtime (postgres_changes on `messages`).
///
/// Handles dropped connections: when the channel errors, times out or
/// closes, it retries automatically after a short delay until
/// [disconnect] is called. [isConnected] reflects the live state so the
/// UI can show a truthful Online/Connecting indicator.
class RealtimeService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final List<ChatMessageModel> _messages = [];
  RealtimeChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _wantConnected = false;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;

  void connect() {
    _wantConnected = true;
    if (_isConnected || !_supabase.isInitialized) return;
    _isConnected = true;
    _loadHistory();

    _channel = _supabase.channel('public:messages')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        table: 'messages',
        callback: (payload) {
          final message = ChatMessageModel.fromMap(payload.newRecord);
          // Skip echoes of messages we already have (e.g. from history).
          if (_messages.any((m) => m.id == message.id)) return;
          _messages.add(message);
          if (_messages.length > 200) {
            _messages.removeRange(0, _messages.length - 200);
          }
          notifyListeners();
        },
      )
      ..subscribe((status, [error]) {
        switch (status) {
          case RealtimeSubscribeStatus.subscribed:
            debugPrint('Realtime: Connected to messages channel');
            if (!_isConnected) {
              _isConnected = true;
              notifyListeners();
            }
          case RealtimeSubscribeStatus.channelError:
          case RealtimeSubscribeStatus.timedOut:
          case RealtimeSubscribeStatus.closed:
            debugPrint('Realtime: channel $status ($error)');
            _scheduleReconnect();
        }
      });
    notifyListeners();
  }

  void _scheduleReconnect() {
    _channel?.unsubscribe();
    _channel = null;
    if (_isConnected) {
      _isConnected = false;
      notifyListeners();
    }
    if (!_wantConnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_wantConnected) connect();
    });
  }

  Future<void> _loadHistory() async {
    try {
      final rows = await _supabase
          .table('messages')
          .select()
          .order('created_at')
          .limit(50);
      _messages
        ..clear()
        ..addAll(rows.map((e) => ChatMessageModel.fromMap(e)));
      notifyListeners();
    } catch (e) {
      debugPrint('Realtime: failed to load message history: $e');
    }
  }

  Future<void> sendMessage(ChatMessageModel message) async {
    await _supabase.table('messages').insert(message.toMap());
  }

  /// Adds a message locally only (never written to the database).
  /// Used for client-side bot replies so we don't pollute the
  /// shared `messages` table with fake rows.
  void addLocalMessage(ChatMessageModel message) {
    _messages.add(message);
    notifyListeners();
  }

  void disconnect() {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    _channel?.unsubscribe();
    _channel = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
