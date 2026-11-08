import 'package:flutter_test/flutter_test.dart';
import 'package:cinemaflix/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel', () {
    final now = DateTime.now();

    test('fromMap creates correct instance', () {
      final map = {
        'id': 'msg-1',
        'user_id': 'user-1',
        'username': 'TestUser',
        'content': 'Hello!',
        'created_at': now.toIso8601String(),
        'avatar_url': 'https://example.com/avatar.png',
      };

      final msg = ChatMessageModel.fromMap(map);

      expect(msg.id, 'msg-1');
      expect(msg.userId, 'user-1');
      expect(msg.username, 'TestUser');
      expect(msg.content, 'Hello!');
      expect(msg.createdAt, now);
      expect(msg.avatarUrl, 'https://example.com/avatar.png');
    });

    test('fromMap defaults username to Anonymous', () {
      final map = {
        'id': 'msg-2',
        'user_id': 'user-2',
        'content': 'Hi!',
        'created_at': now.toIso8601String(),
      };

      final msg = ChatMessageModel.fromMap(map);

      expect(msg.username, 'Anonymous');
      expect(msg.avatarUrl, isNull);
    });

    test('toMap returns correct map', () {
      final msg = ChatMessageModel(
        id: 'msg-3',
        userId: 'user-3',
        username: 'Alice',
        content: 'How are you?',
        createdAt: now,
      );

      final map = msg.toMap();

      expect(map['id'], 'msg-3');
      expect(map['user_id'], 'user-3');
      expect(map['username'], 'Alice');
      expect(map['content'], 'How are you?');
      expect(map['created_at'], now.toIso8601String());
    });
  });
}
