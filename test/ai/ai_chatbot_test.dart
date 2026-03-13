import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ai/ai_chatbot.dart';

void main() {
  group('AIChatbotManager', () {
    late AIChatbotManager chatbot;

    setUp(() {
      chatbot = AIChatbotManager.instance;
    });

    test('API 키 설정', () {
      chatbot.setApiKey('test_api_key');

      // 예외 없으면 성공
      expect(true, true);
    });

    test('LLM 제공자 설정', () {
      chatbot.setProvider(LLMProvider.anthropic);

      // 예외 없으면 성공
      expect(true, true);
    });

    test('NPC 채팅 (시뮬레이션)', () async {
      final response = await chatbot.chatWithNPC(
        npcId: 'quest_giver',
        userMessage: '안녕하세요',
      );

      expect(response, isNotNull);
      expect(response.isNotEmpty, true);
    });

    test('NPC 등록', () {
      final npc = const NPCPersona(
        id: 'custom_npc',
        name: '커스텀 NPC',
        personality: '친절함',
        background: '배경',
        speakingStyle: '정중함',
        knowledge: {'test': '테스트 지식'},
      );

      chatbot.registerNPC(npc);

      // 예외 없으면 성공
      expect(true, true);
    });

    test('퀘스트 생성', () async {
      final quest = await chatbot.generateQuest(
        theme: '드래곤 사냥',
        difficulty: 5,
        context: {
          'location': '火山',
          'rewards': '경험치',
        },
      );

      expect(quest, isNotNull);
      expect(quest.contains('드래곤'), true);
    });

    test('감정 분석', () async {
      final positiveSentiment = await chatbot.analyzeSentiment('정말 좋아요! 최고입니다!');
      expect(positiveSentiment['sentiment'], 'positive');

      final negativeSentiment = await chatbot.analyzeSentiment('정말 싫어요. 최악입니다.');
      expect(negativeSentiment['sentiment'], 'negative');

      final neutralSentiment = await chatbot.analyzeSentiment('그렇군요.');
      expect(neutralSentiment['sentiment'], 'neutral');
    });

    test('음성 입력 처리', () async {
      final result = await chatbot.processVoiceInput('/path/to/audio.wav');

      expect(result, isNotNull);
    });

    test('대화 기록 초기화', () {
      chatbot.clearHistory();

      // 예외 없으면 성공
      expect(true, true);
    });
  });

  group('EmotionalNPC', () {
    test('감정 업데이트', () {
      final npc = EmotionalNPC(
        id: 'npc_001',
        name: '감정 NPC',
      );

      npc.updateEmotion('정말 좋아요!', {'sentiment': 'positive', 'confidence': 0.8});

      expect(npc.currentEmotion, 'happy');
    });

    test('부정적 감정', () {
      final npc = EmotionalNPC(
        id: 'npc_002',
        name: '부정 NPC',
      );

      npc.updateEmotion('싫어요', {'sentiment': 'negative', 'confidence': 0.8});

      expect(npc.currentEmotion, 'sad');
    });

    test('중립적 감정', () {
      final npc = EmotionalNPC(
        id: 'npc_003',
        name: '중립 NPC',
      );

      npc.updateEmotion('그렇군요', {'sentiment': 'neutral', 'confidence': 0.5});

      expect(npc.currentEmotion, 'neutral');
    });

    test('감정에 따른 응답', () {
      final npc = EmotionalNPC(
        id: 'npc_004',
        name: '응답 NPC',
      );

      npc.updateEmotion('좋아요!', {'sentiment': 'positive', 'confidence': 0.8});
      final happyResponse = npc.getEmotionalResponse();

      expect(happyResponse, contains('좋아요'));

      npc.updateEmotion('싫어요', {'sentiment': 'negative', 'confidence': 0.8});
      final sadResponse = npc.getEmotionalResponse();

      expect(sadResponse, contains('도와'));
    });
  });

  group('ChatMessage', () {
    test('메시지 직렬화', () {
      final message = ChatMessage(
        id: 'msg_001',
        role: MessageRole.user,
        content: '테스트 메시지',
        timestamp: DateTime(2024, 1, 1, 12, 0),
        metadata: {'key': 'value'},
      );

      final json = message.toJson();

      expect(json['id'], 'msg_001');
      expect(json['role'], 'user');
      expect(json['content'], '테스트 메시지');
      expect(json['metadata'], {'key': 'value'});
    });

    test('메시지 역직렬화', () {
      final json = {
        'id': 'msg_001',
        'role': 'assistant',
        'content': '응답 메시지',
        'timestamp': '2024-01-01T12:00:00.000Z',
        'metadata': null,
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, 'msg_001');
      expect(message.role, MessageRole.assistant);
      expect(message.content, '응답 메시지');
    });
  });
}
