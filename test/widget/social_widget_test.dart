import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/social/social_manager.dart';

void main() {
  group('Social Widget Tests', () {
    testWidgets('친구 목록 위젯', (WidgetTester tester) async {
      final friends = [
        Friend(
          userId: 'user1',
          nickname: '친구1',
          status: FriendStatus.online,
          level: 10,
        ),
        Friend(
          userId: 'user2',
          nickname: '친구2',
          status: FriendStatus.inGame,
          level: 15,
          currentGame: 'Racing',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(friend.nickname[0]),
                  ),
                  title: Text(friend.nickname),
                  subtitle: Text(_getStatusText(friend.status)),
                  trailing: Text('Lv.${friend.level}'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('친구1'), findsOneWidget);
      expect(find.text('친구2'), findsOneWidget);
      expect(find.text('온라인'), findsOneWidget);
      expect(find.text('게임 중'), findsOneWidget);
    });

    testWidgets('리더보드 위젯', (WidgetTester tester) async {
      final entries = [
        LeaderboardEntry(
          userId: 'user1',
          nickname: '플레이어1',
          score: 1000,
          rank: 1,
        ),
        LeaderboardEntry(
          userId: 'user2',
          nickname: '플레이어2',
          score: 900,
          rank: 2,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  leading: Text('#${entry.rank}'),
                  title: Text(entry.nickname),
                  trailing: Text('${entry.score}점'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('1000점'), findsOneWidget);
      expect(find.text('900점'), findsOneWidget);
    });

    testWidgets('채팅 메시지 위젯', (WidgetTester tester) async {
      final messages = [
        ChatMessage(
          messageId: 'msg1',
          senderId: 'user1',
          senderNickname: '플레이어1',
          content: '안녕하세요!',
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          messageId: 'msg2',
          senderId: 'user2',
          senderNickname: '플레이어2',
          content: '반갑습니다!',
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  title: Text(message.senderNickname),
                  subtitle: Text(message.content),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('안녕하세요!'), findsOneWidget);
      expect(find.text('반갑습니다!'), findsOneWidget);
    });
  });

  group('Social Manager Widget Tests', () {
    testWidgets('친구 추가 다이얼로그', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('친구 추가'),
                      content: const TextField(
                        decoration: InputDecoration(
                          hintText: '사용자 ID 입력',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('추가'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('친구 추가'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('친구 추가'));
      await tester.pumpAndSettle();

      expect(find.text('친구 추가'), findsWidgets);
      expect(find.text('취소'), findsOneWidget);
    });

    testWidgets('프로필 수정 화면', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('프로필'),
            ),
            body: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: '닉네임',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('닉네임'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
    });
  });
}

String _getStatusText(FriendStatus status) {
  switch (status) {
    case FriendStatus.online:
      return '온라인';
    case FriendStatus.inGame:
      return '게임 중';
    case FriendStatus.away:
      return '자리 비움';
    case FriendStatus.offline:
      return '오프라인';
  }
}
