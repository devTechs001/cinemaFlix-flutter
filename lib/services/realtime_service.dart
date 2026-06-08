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
    if (_isConnected) return;
    _isConnected = true;

    _channel = _supabase.channel('public:messages')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        table: 'messages',
        callback: (payload) {
          final message = ChatMessageModel.fromMap(payload.newRecord);
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

  Future<void> sendMessage(ChatMessageModel message) async {
    await _supabase.table('messages').insert(message.toMap());
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
