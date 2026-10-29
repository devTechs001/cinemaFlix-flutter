import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import 'supabase_service.dart';

class RealtimeService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final List<ChatMessageModel> _messages = [];
  RealtimeChannel? _channel;
  bool _isConnected = false;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;

  void connect() {
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
          notifyListeners();
        },
      )
      ..subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('Realtime: Connected to messages channel');
        }
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
