import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NLP 작업 타입
enum NLPTaskType {
  translation,      // 번역
  sentiment,        // 감정 분석
  intent,           // 의도 파악
  entity,           // 개체 인식
  summarization,    // 요약
  chat,             // 채팅
}

/// 지원 언어
enum Language {
  korean,          // 한국어
  english,         // 영어
  japanese,        // 일본어
  chinese,         // 중국어
  spanish,         // 스페인어
  french,          // 프랑스어
  german,          // 독일어
  russian,         // 러시아어
}

/// 감정 라벨
enum SentimentLabel {
  positive,        // 긍정
  negative,        // 부정
  neutral,         // 중립
}

/// 의도 타입
enum IntentType {
  greeting,        // 인사
  request,         // 요청
  complaint,       // 불만
  inquiry,         // 문의
  command,         // 명령
  feedback,        // 피드백
  chat,            // 채팅
}

/// 개체 타입
enum EntityType {
  person,          // 사람
  location,        // 위치
  organization,    // 조직
  item,            // 아이템
  champion,        // 챔피언
  skill,           // 스킬
  number,          // 숫자
  date,            // 날짜
}

/// 감정 분석 결과
class SentimentResult {
  final String text;
  final SentimentLabel label;
  final double confidence; // 0.0 - 1.0
  final double positiveScore;
  final double negativeScore;
  final double neutralScore;

  const SentimentResult({
    required this.text,
    required this.label,
    required this.confidence,
    required this.positiveScore,
    required this.negativeScore,
    required this.neutralScore,
  });
}

/// 의도 파악 결과
class IntentResult {
  final String text;
  final IntentType intent;
  final double confidence; // 0.0 - 1.0
  final Map<String, String> entities;
  final String? action;

  const IntentResult({
    required this.text,
    required this.intent,
    required this.confidence,
    required this.entities,
    this.action,
  });
}

/// 개체 인식 결과
class EntityResult {
  final String text;
  final String entity;
  final EntityType type;
  final int startIndex;
  final int endIndex;
  final double confidence;

  const EntityResult({
    required this.text,
    required this.entity,
    required this.type,
    required this.startIndex,
    required this.endIndex,
    required this.confidence,
  });
}

/// 번역 결과
class TranslationResult {
  final String originalText;
  final String translatedText;
  final Language sourceLanguage;
  final Language targetLanguage;
  final double confidence;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.confidence,
  });
}

/// 요약 결과
class SummarizationResult {
  final String originalText;
  final String summary;
  final double compressionRatio; // 원문 대비 요약 길이 비율
  final List<String> keyPoints;

  const SummarizationResult({
    required this.originalText,
    required this.summary,
    required this.compressionRatio,
    required this.keyPoints,
  });
}

/// 챗봇 응답
class ChatbotResponse {
  final String userMessage;
  final String botResponse;
  final IntentType intent;
  final List<String> suggestedActions;
  final double confidence;

  const ChatbotResponse({
    required this.userMessage,
    required this.botResponse,
    required this.intent,
    required this.suggestedActions,
    required this.confidence,
  });
}

/// 음성 인식 결과
class SpeechRecognitionResult {
  final String transcript;
  final double confidence;
  final Duration duration;
  final Language detectedLanguage;

  const SpeechRecognitionResult({
    required this.transcript,
    required this.confidence,
    required this.duration,
    required this.detectedLanguage,
  });
}

/// NLP 관리자
class NLPManager {
  static final NLPManager _instance = NLPManager._();
  static NLPManager get instance => _instance;

  NLPManager._();

  SharedPreferences? _prefs;

  final Map<String, List<SentimentResult>> _sentimentHistory = {};
  final Map<String, List<IntentResult>> _intentHistory = {};
  final Map<String, List<TranslationResult>> _translationCache = {};

  final StreamController<SentimentResult> _sentimentController =
      StreamController<SentimentResult>.broadcast();
  final StreamController<IntentResult> _intentController =
      StreamController<IntentResult>.broadcast();

  Stream<SentimentResult> get onSentiment => _sentimentController.stream;
  Stream<IntentResult> get onIntent => _intentController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    debugPrint('[NLP] Initialized');
  }

  /// 감정 분석
  Future<SentimentResult> analyzeSentiment(String text) async {
    // 간단한 감정 분석 (시뮬레이션)
    final lowerText = text.toLowerCase();

    var positiveScore = 0.0;
    var negativeScore = 0.0;

    // 긍정 단어
    final positiveWords = [
      '좋아', '최고', '감사', '칭찬', '만족', '훌륭', '좋습니다', '고마워',
      '좋은', '신나', '재밌', '즐겁', 'happy', 'good', 'great', 'thanks',
    ];

    // 부정 단어
    final negativeWords = [
      '별로', '최악', '불만', '화남', '속상', '나쁜', '안돼', '싫어',
      '짜증', '버그', '오류', 'slow', 'bad', 'hate', 'angry',
    ];

    for (final word in positiveWords) {
      if (lowerText.contains(word)) {
        positiveScore += 0.2;
      }
    }

    for (final word in negativeWords) {
      if (lowerText.contains(word)) {
        negativeScore += 0.2;
      }
    }

    final totalScore = positiveScore + negativeScore;
    final neutralScore = 1.0 - totalScore.clamp(0.0, 1.0);

    SentimentLabel label;
    if (positiveScore > negativeScore && positiveScore > 0.3) {
      label = SentimentLabel.positive;
    } else if (negativeScore > positiveScore && negativeScore > 0.3) {
      label = SentimentLabel.negative;
    } else {
      label = SentimentLabel.neutral;
    }

    final result = SentimentResult(
      text: text,
      label: label,
      confidence: totalScore.clamp(0.3, 0.9),
      positiveScore: positiveScore.clamp(0.0, 1.0),
      negativeScore: negativeScore.clamp(0.0, 1.0),
      neutralScore: neutralScore.clamp(0.0, 1.0),
    );

    _sentimentController.add(result);

    debugPrint('[NLP] Sentiment analyzed: ${label.name}');

    return result;
  }

  /// 의도 파악
  Future<IntentResult> detectIntent(String text) async {
    final lowerText = text.toLowerCase();

    IntentType intent;
    double confidence;
    final entities = <String, String>{};
    String? action;

    // 인사
    if (_containsAny(lowerText, ['안녕', 'hello', 'hi', '안녕하세요'])) {
      intent = IntentType.greeting;
      confidence = 0.9;
      action = 'greet';
    }
    // 불만
    else if (_containsAny(lowerText, ['불만', '화나', '최악', '별로', 'complaint', 'angry'])) {
      intent = IntentType.complaint;
      confidence = 0.85;
      action = 'handle_complaint';
      entities['reason'] = _extractReason(text);
    }
    // 요청
    else if (_containsAny(lowerText, ['도와', '도와줘', '도와주세요', 'help', 'assist'])) {
      intent = IntentType.request;
      confidence = 0.8;
      action = 'provide_help';
    }
    // 문의
    else if (_containsAny(lowerText, ['궁금', '어떻게', 'how', 'what', 'question'])) {
      intent = IntentType.inquiry;
      confidence = 0.75;
      action = 'answer_inquiry';
    }
    // 피드백
    else if (_containsAny(lowerText, ['피드백', '제안', 'suggestion', 'feedback'])) {
      intent = IntentType.feedback;
      confidence = 0.8;
      action = 'collect_feedback';
    }
    // 명령
    else if (_containsAny(lowerText, ['시작', '중지', 'stop', 'start'])) {
      intent = IntentType.command;
      confidence = 0.85;
      action = _extractCommand(text);
    }
    // 기본 채팅
    else {
      intent = IntentType.chat;
      confidence = 0.5;
      action = 'chat';
    }

    final result = IntentResult(
      text: text,
      intent: intent,
      confidence: confidence,
      entities: entities,
      action: action,
    );

    _intentController.add(result);

    debugPrint('[NLP] Intent detected: ${intent.name}');

    return result;
  }

  /// 개체 인식
  Future<List<EntityResult>> extractEntities(String text) async {
    final entities = <EntityResult>[];

    // 숫자 추출
    final numberRegex = RegExp(r'\d+');
    for (final match in numberRegex.allMatches(text)) {
      entities.add(EntityResult(
        text: match.group(0)!,
        entity: match.group(0)!,
        type: EntityType.number,
        startIndex: match.start,
        endIndex: match.end,
        confidence: 0.95,
      ));
    }

    // 게임 관련 개체
    final gameEntities = {
      '아리': [EntityType.champion, 'champion'],
      '검사': [EntityType.champion, 'champion'],
      '마법사': [EntityType.champion, 'champion'],
      '힐': [EntityType.skill, 'skill'],
      '디버프': [EntityType.skill, 'skill'],
      '룬': [EntityType.item, 'item'],
    };

    for (final entry in gameEntities.entries) {
      final keyword = entry.key;
      final info = entry.value;

      if (text.contains(keyword)) {
        final index = text.indexOf(keyword);
        entities.add(EntityResult(
          text: keyword,
          entity: info[1],
          type: info[0],
          startIndex: index,
          endIndex: index + keyword.length,
          confidence: 0.8,
        ));
      }
    }

    debugPrint('[NLP] Extracted ${entities.length} entities');

    return entities;
  }

  /// 번역
  Future<TranslationResult> translate({
    required String text,
    required Language targetLanguage,
  }) async {
    // 원본 언어 감지 (시뮬레이션)
    final sourceLanguage = _detectLanguage(text);

    // 캐시 확인
    final cacheKey = '${sourceLanguage.name}_${targetLanguage.name}_${text.hashCode}';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!.first;
    }

    // 번역 (시뮬레이션)
    String translatedText;
    if (sourceLanguage == targetLanguage) {
      translatedText = text;
    } else {
      // 실제로는 번역 API 호출
      translatedText = await _callTranslationAPI(text, sourceLanguage, targetLanguage);
    }

    final result = TranslationResult(
      originalText: text,
      translatedText: translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      confidence: 0.85,
    );

    // 캐시 저장
    _translationCache.putIfAbsent(cacheKey, () => []).add(result);

    debugPrint('[NLP] Translated: ${sourceLanguage.name} -> ${targetLanguage.name}');

    return result;
  }

  /// 언어 감지
  Language _detectLanguage(String text) {
    // 간단한 언어 감지 (시뮬레이션)
    final koreanChars = RegExp(r'[가-힣]');
    final englishChars = RegExp(r'[a-zA-Z]');
    final japaneseChars = RegExp(r'[\u3040-\u309F\u30A0-\u30FF]');
    final chineseChars = RegExp(r'[\u4E00-\u9FFF]');

    if (koreanChars.hasMatch(text)) return Language.korean;
    if (japaneseChars.hasMatch(text)) return Language.japanese;
    if (chineseChars.hasMatch(text)) return Language.chinese;
    if (englishChars.hasMatch(text)) return Language.english;

    return Language.english; // 기본값
  }

  /// 번역 API 호출 (시뮬레이션)
  Future<String> _callTranslationAPI(
    String text,
    Language source,
    Language target,
  ) async {
    // 실제 환경에서는 Google Translate API 등 호출
    await Future.delayed(const Duration(milliseconds: 500));

    // 시뮬레이션을 위해 원문 반환
    return '[$translated] $text';
  }

  /// 요약
  Future<SummarizationResult> summarize(String text) async {
    // 문장 분리
    final sentences = text.split(RegExp(r'[.!?]'));
    if (sentences.isEmpty) {
      return SummarizationResult(
        originalText: text,
        summary: text,
        compressionRatio: 1.0,
        keyPoints: [],
      );
    }

    // 간단한 요약 (시뮬레이션)
    final summaryLength = (sentences.length * 0.3).ceil().clamp(1, sentences.length);
    final summary = sentences.take(summaryLength).join('. ') + '.';
    final compressionRatio = summary.length / text.length;

    // 핵심 문장 추출
    final keyPoints = <String>[];
    for (final sentence in sentences) {
      if (sentence.contains('중요') || sentence.contains('필심')) {
        keyPoints.add(sentence.trim());
      }
    }

    final result = SummarizationResult(
      originalText: text,
      summary: summary,
      compressionRatio: compressionRatio,
      keyPoints: keyPoints,
    );

    debugPrint('[NLP] Summarized: ${(compressionRatio * 100).toStringAsFixed(0)}%');

    return result;
  }

  /// 챗봇 응답
  Future<ChatbotResponse> chat(String message) async {
    // 의도 파악
    final intentResult = await detectIntent(message);

    // 감정 분석
    final sentimentResult = await analyzeSentiment(message);

    // 응답 생성
    String botResponse;
    final suggestedActions = <String>[];

    switch (intentResult.intent) {
      case IntentType.greeting:
        botResponse = '안녕하세요! 오늘도 게임을 즐기시나요? 무엇을 도와드릴까요?';
        suggestedActions.addAll(['오늘의 이벤트', '게임 가이드', '고객센터']);
        break;

      case IntentType.complaint:
        botResponse = '불편을 드려 죄송합니다. 문제를 신속히 해결해 드리겠습니다. 어떤 문제가 발생했나요?';
        suggestedActions.addAll(['버그 신고', '1:1 문의', '공지사항']);
        break;

      case IntentType.request:
        botResponse = '도움이 필요하신가요? 무엇을 알아드려 드릴까요?';
        suggestedActions.addAll(['자주 묻는 질문', '게임 방법', '시스템 안내']);
        break;

      case IntentType.inquiry:
        botResponse = '질문해 주셔서 감사합니다. 검색해 보겠습니다.';
        suggestedActions.addAll(['FAQ 보기', '검색', '문의하기']);
        break;

      case IntentType.feedback:
        botResponse = '소중한 피드백 감사합니다! 더 나은 서비스를 제공하기 위해 노력하겠습니다.';
        suggestedActions.addAll(['추가 의견', '설문조사', '확인']);
        break;

      case IntentType.command:
        botResponse = '명령을 실행하겠습니다.';
        suggestedActions.addAll(['확인', '취소']);
        break;

      case IntentType.chat:
        if (sentimentResult.label == SentimentLabel.positive) {
          botResponse = '긍정적인 분위기네요! 즐거운 게임 되세요!';
        } else if (sentimentResult.label == SentimentLabel.negative) {
          botResponse = '무슨 일이 있으신가요? 도와드릴 수 있어요.';
        } else {
          botResponse = '네, 무엇이든 물어보세요.';
        }
        suggestedActions.addAll(['다른 질문', '상담원 연결']);
        break;
    }

    final result = ChatbotResponse(
      userMessage: message,
      botResponse: botResponse,
      intent: intentResult.intent,
      suggestedActions: suggestedActions,
      confidence: (intentResult.confidence + sentimentResult.confidence) / 2,
    );

    debugPrint('[NLP] Chat response: ${result.intent.name}');

    return result;
  }

  /// 음성 인식 (시뮬레이션)
  Future<SpeechRecognitionResult> recognizeSpeech() async {
    // 실제 환경에서는 음성 인식 API 호출
    await Future.delayed(const Duration(seconds: 2));

    final result = SpeechRecognitionResult(
      transcript: '안녕하세요 오늘도 게임을 즐기시나요',
      confidence: 0.9,
      duration: const Duration(seconds: 2),
      detectedLanguage: Language.korean,
    );

    debugPrint('[NLP] Speech recognized: ${result.transcript}');

    return result;
  }

  /// 텍스트 분석
  Future<Map<String, dynamic>> analyzeText(String text) async {
    final sentiment = await analyzeSentiment(text);
    final intent = await detectIntent(text);
    final entities = await extractEntities(text);

    return {
      'sentiment': {
        'label': sentiment.label.name,
        'confidence': sentiment.confidence,
        'scores': {
          'positive': sentiment.positiveScore,
          'negative': sentiment.negativeScore,
          'neutral': sentiment.neutralScore,
        },
      },
      'intent': {
        'type': intent.intent.name,
        'confidence': intent.confidence,
        'action': intent.action,
      },
      'entities': entities.map((e) => {
        'text': e.text,
        'type': e.type.name,
        'confidence': e.confidence,
      }).toList(),
      'textLength': text.length,
      'wordCount': text.split(RegExp(r'\s+')).length,
    };
  }

  /// 배치 처리
  Future<List<SentimentResult>> batchAnalyzeSentiment(List<String> texts) async {
    final results = <SentimentResult>[];

    for (final text in texts) {
      final result = await analyzeSentiment(text);
      results.add(result);
    }

    return results;
  }

  /// 다국어 지원 확인
  bool isLanguageSupported(Language language) {
    return Language.values.contains(language);
  }

  /// 언어 코드 변환
  String getLanguageCode(Language language) {
    switch (language) {
      case Language.korean:
        return 'ko';
      case Language.english:
        return 'en';
      case Language.japanese:
        return 'ja';
      case Language.chinese:
        return 'zh';
      case Language.spanish:
        return 'es';
      case Language.french:
        return 'fr';
      case Language.german:
        return 'de';
      case Language.russian:
        return 'ru';
    }
  }

  /// 도움말 포함 여부 확인
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// 이유 추출
  String? _extractReason(String text) {
    if (text.contains('버그')) return 'bug';
    if (text.contains('렉')) return 'lag';
    if (text.contains('결제')) return 'payment';
    return null;
  }

  /// 명령 추출
  String? _extractCommand(String text) {
    if (text.contains('시작')) return 'start';
    if (text.contains('중지')) return 'stop';
    if (text.contains('재시작')) return 'restart';
    return null;
  }

  void dispose() {
    _sentimentController.close();
    _intentController.close();
  }
}
