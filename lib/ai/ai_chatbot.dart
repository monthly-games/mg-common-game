import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// LLM 제공자
enum LLMProvider {
  openAI,
  anthropic,
  google,
  local,
}

/// 메시지 역할
enum MessageRole {
  system,
  user,
  assistant,
}

/// 채팅 메시지
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: MessageRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => MessageRole.user,
        ),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

/// NPC 페르소나
class NPCPersona {
  final String id;
  final String name;
  final String personality; // 성격 유형
  final String background;
  final String speakingStyle; // 말투
  final Map<String, dynamic> knowledge; // 배경 지식

  const NPCPersona({
    required this.id,
    required this.name,
    required this.personality,
    required this.background,
    required this.speakingStyle,
    required this.knowledge,
  });
}

/// AI 챗봇 매니저
class AIChatbotManager {
  static final AIChatbotManager _instance = AIChatbotManager._();
  static AIChatbotManager get instance => _instance;

  AIChatbotManager._();

  LLMProvider _provider = LLMProvider.openAI;
  String? _apiKey;
  final Map<String, NPCPersona> _npcs = {};

  final List<ChatMessage> _conversationHistory = [];

  // NPC 페르나 로드
  void _loadNPCPersonas() {
    _npcs['quest_giver'] = const NPCPersona(
      id: 'quest_giver',
      name: '퀘스트 마스터',
      personality: '친절하고 도움을 줌',
      background: '수년간 모험가들에게 퀘스트를 제공해왔습니다',
      speakingStyle: '정중하고 예의 바름',
      knowledge: {
        'world_lore': '판타지 세계의 역사와 지리',
        'monsters': '몬스터의 약점과 공략법',
      },
    );

    _npcs['merchant'] = const NPCPersona(
      id: 'merchant',
      name: '상인 라스',
      personality: '상술적이고 친절함',
      background: '전국을 여행하는 상인으로 귀한 물건을 많이 가지고 있습니다',
      speakingStyle: '장사적인 어조',
      knowledge: {
        'items': '아이템의 가격과 희귀성',
        'markets': '각 지역의 시세',
      },
    );

    _npcs['trainer'] = const NPCPersona(
      id: 'trainer',
      name: '트레이너 리오',
      personality: '엄격하지만 열정적임',
      background: '전설적인 영웅으로 젊은이들을 훈련시킵니다',
      speakingStyle: '동기부여를 주며 명확함',
      knowledge: {
        'combat': '전투 기술과 전략',
        'fitness': '체력 단련법',
      },
    );
  }

  /// NPC 채팅
  Future<String> chatWithNPC({
    required String npcId,
    required String userMessage,
    Map<String, dynamic>? context,
  }) async {
    final npc = _npcs[npcId];
    if (npc == null) {
      return '죄송합니다. 해당 NPC를 찾을 수 없습니다.';
    }

    // 시스템 프롬프트
    final systemPrompt = _buildSystemPrompt(npc, context);

    // 대화 기록에 추가
    _conversationHistory.add(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: userMessage,
      timestamp: DateTime.now(),
    ));

    // LLM 요청
    try {
      final response = await _sendToLLM(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
      );

      // 응답을 대화 기록에 추가
      _conversationHistory.add(ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch + 1}',
        role: MessageRole.assistant,
        content: response,
        timestamp: DateTime.now(),
      ));

      return response;
    } catch (e) {
      debugPrint('[AIChatbot] Error: $e');
      return '${npc.name}: 죄송합니다. 잠시 연결할 수 없습니다.';
    }
  }

  String _buildSystemPrompt(NPCPersona npc, Map<String, dynamic>? context) {
    final buffer = StringBuffer();

    buffer.writeln('당신은 게임 속 NPC입니다.');
    buffer.writeln('이름: ${npc.name}');
    buffer.writeln('성격: ${npc.personality}');
    buffer.writeln('배경: ${npc.background}');
    buffer.writeln('말투: ${npc.speakingStyle}');
    buffer.writeln();
    buffer.writeln('지식:');
    npc.knowledge.forEach((key, value) {
      buffer.writeln('- $key: $value');
    });
    buffer.writeln();

    if (context != null) {
      buffer.writeln('현재 상황:');
      context.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }

    buffer.writeln('지침:');
    buffer.writeln('1. 캐릭터 역할에 맞게 대응하세요.');
    buffer.writeln('2. 설정된 말투를 유지하세요.');
    buffer.writeln('3. 100자 이내로 간결명하게 답변하세요.');
    buffer.writeln('4. 게임 플레이어에게 도움이나 정보를 제공하세요.');

    return buffer.toString();
  }

  Future<String> _sendToLLM({
    required String systemPrompt,
    required String userMessage,
  }) async {
    // 실제 LLM API 호출 (시뮬레이션)

    // API 키 확인
    if (_apiKey == null || _apiKey!.isEmpty) {
      // 시뮬레이션 응답
      return _simulateResponse(userMessage);
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('[AIChatbot] API Error: ${response.statusCode}');
        return _simulateResponse(userMessage);
      }
    } catch (e) {
      debugPrint('[AIChatbot] Request Error: $e');
      return _simulateResponse(userMessage);
    }
  }

  String _simulateResponse(String userMessage) {
    // 간단한 규칙 기반 응답 (실제로는 LLM 사용)
    if (userMessage.contains('안녕') || userMessage.contains('반가워')) {
      return '반가워요! 오늘 어떻게 도와드릴까요?';
    } else if (userMessage.contains('퀘스트') || userMessage.contains('미션')) {
      return '현재 진행 가능한 퀘스트가 있습니다. 확인해보시겠어요?';
    } else if (userMessage.contains('상점') || userMessage.contains('팝')) {
      return '상점에서 다양한 아이템을 판매하고 있습니다. 둘러보시겠어요?';
    } else if (userMessage.contains('도움') || userMessage.contains('도전')) {
      return '무엇을 도와드릴까요? 퀘스트, 아이템, 전투 중 무엇이든 물어보세요.';
    } else {
      return '그렇군요. 더 자세히 말씀해 주시겠어요?';
    }
  }

  /// API 키 설정
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    debugPrint('[AIChatbot] API key configured');
  }

  /// LLM 제공자 설정
  void setProvider(LLMProvider provider) {
    _provider = provider;
    debugPrint('[AIChatbot] Provider set to: $provider');
  }

  /// 대화 기록 초기화
  void clearHistory() {
    _conversationHistory.clear();
    debugPrint('[AIChatbot] Conversation history cleared');
  }

  /// 퀘스트 자동 생성
  Future<String> generateQuest({
    required String theme,
    required int difficulty,
    required Map<String, dynamic> context,
  }) async {
    final prompt = StringBuffer();
    prompt.writeln('다음 조건에 맞는 퀘스트를 생성하세요:');
    prompt.writeln('테마: $theme');
    prompt.writeln('난이도: $difficulty (1-10)');
    prompt.writeln('컨텍스트: $context');
    prompt.writeln();
    prompt.writeln('출력 형식:');
    prompt.writeln('- 퀘스트 제목');
    prompt.writeln('- 목표 (예: 몬스터 5마리 처치)');
    prompt.writeln('- 보상');
    prompt.writeln('- 제한 시간');

    try {
      final response = await _sendToLLM(
        systemPrompt: '당신은 게임 퀘스트 디자이너입니다.',
        userMessage: prompt.toString(),
      );

      return response;
    } catch (e) {
      // 기본 퀘스트 템플릿 반환
      return '$theme 퀘스트\n목표: $theme 관련 활동 완료\n보상: 골드 100\n제한: 1시간';
    }
  }

  /// NPC 대화 감정 분석
  Future<Map<String, dynamic>> analyzeSentiment(String message) async {
    // 간단한 감정 분석 (실제로는 LLM 사용)
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('좋') || lowerMessage.contains('최고') ||
        lowerMessage.contains('사랑') || lowerMessage.contains('감사')) {
      return {'sentiment': 'positive', 'confidence': 0.8};
    } else if (lowerMessage.contains('싫') || lowerMessage.contains('밉') ||
        lowerMessage.contains('나쁜') || lowerMessage.contains('형편')) {
      return {'sentiment': 'negative', 'confidence': 0.8};
    }

    return {'sentiment': 'neutral', 'confidence': 0.5};
  }

  /// 음성 채팅 지원
  Future<String> processVoiceInput(String audioFilePath) async {
    // 실제로는 STT (Speech-to-Text) API 사용
    // 여기서는 시뮬레이션
    debugPrint('[AIChatbot] Processing voice: $audioFilePath');
    return '[음성 입력 처리됨]';
  }

  /// NPC 추가
  void registerNPC(NPCPersona persona) {
    _npcs[persona.id] = persona;
    debugPrint('[AIChatbot] NPC registered: ${persona.name}');
  }

  void dispose() {
    _conversationHistory.clear();
  }
}

/// 감정 인식 NPC
class EmotionalNPC {
  final String id;
  final String name;
  String currentEmotion;

  EmotionalNPC({
    required this.id,
    required this.name,
    this.currentEmotion = 'neutral',
  });

  /// 감정 상태 업데이트
  void updateEmotion(String userMessage, Map<String, dynamic> sentiment) {
    final sentimentType = sentiment['sentiment'] as String? ?? 'neutral';

    switch (sentimentType) {
      case 'positive':
        currentEmotion = 'happy';
        break;
      case 'negative':
        currentEmotion = 'sad';
        break;
      default:
        currentEmotion = 'neutral';
    }

    debugPrint('[NPC] $name emotion: $currentEmotion');
  }

  /// 감정에 따른 응답
  String getEmotionalResponse() {
    switch (currentEmotion) {
      case 'happy':
        return '아주 좋아요! 계속 그런 분위기여서!';
      case 'sad':
        return '무슨 일이 있으신가요? 제가 도와드릴게요.';
      case 'neutral':
      default:
        return '그렇군요. 어떻게 도와드릴까요?';
    }
  }
}
