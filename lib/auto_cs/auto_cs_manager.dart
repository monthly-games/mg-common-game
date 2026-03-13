import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 티켓 카테고리
enum TicketCategory {
  billing,           // 결제
  technical,         // 기술적
  gameplay,          // 게임플레이
  account,           // 계정
  bug,               // 버그
  suggestion,        // 제안
  other,             // 기타
}

/// 티켓 상태
enum TicketStatus {
  open,               // 접수
  investigating,       // 조사 중
  waiting,            // 대기 중
  resolved,           // 해결됨
  closed,             // 종료됨
}

/// 티켓 우선순위
enum TicketPriority {
  low,                // 낮음
  normal,             // 보통
  high,               // 높음
  urgent,             // 긴급
}

/// 티켓
class Ticket {
  final String id;
  final String userId;
  final String username;
  final TicketCategory category;
  final TicketStatus status;
  final TicketPriority priority;
  final String subject;
  final String description;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? assignedTo;
  final List<TicketMessage> messages;

  const Ticket({
    required this.id,
    required this.userId,
    required this.username,
    required this.category,
    required this.status,
    required this.priority,
    required this.subject,
    required this.description,
    this.attachments = const [],
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.assignedTo,
    this.messages = const [],
  });
}

/// 티켓 메시지
class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String content;
  final bool isFromSupport;
  final DateTime timestamp;
  final List<String>? attachments;

  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.isFromSupport,
    required this.timestamp,
    this.attachments,
  });
}

/// FAQ
class FAQ {
  final String id;
  final String question;
  final String answer;
  final TicketCategory category;
  final List<String> keywords;
  final int viewCount;
  final bool isPublished;

  const FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.keywords = const [],
    this.viewCount = 0,
    this.isPublished = true,
  });
}

/// 챗봇 응답
class ChatbotResponse {
  final String response;
  final double confidence;
  final List<String> suggestedActions;
  final String? ticketCategory;
  final bool needsHumanSupport;

  const ChatbotResponse({
    required this.response,
    required this.confidence,
    this.suggestedActions = const [],
    this.ticketCategory,
    this.needsHumanSupport = false,
  });
}

/// 감정 분석 결과
class SentimentAnalysis {
  final double score; // -1.0 to 1.0
  final String label; // positive, negative, neutral
  final Map<String, double> emotions;

  const SentimentAnalysis({
    required this.score,
    required this.label,
    required this.emotions,
  });
}

/// 자동 CS 관리자
class AutoCSManager {
  static final AutoCSManager _instance = AutoCSManager._();
  static AutoCSManager get instance => _instance;

  AutoCSManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, Ticket> _tickets = {};
  final Map<String, FAQ> _faqs = {};
  final Map<String, SentimentAnalysis> _sentimentCache = {};

  final StreamController<Ticket> _ticketController =
      StreamController<Ticket>.broadcast();
  final StreamController<TicketMessage> _messageController =
      StreamController<TicketMessage>.broadcast();

  Stream<Ticket> get onTicketUpdate => _ticketController.stream;
  Stream<TicketMessage> get onMessage => _messageController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // FAQ 로드
    _loadFAQs();

    // 티켓 로드
    await _loadTickets();

    debugPrint('[AutoCS] Initialized');
  }

  void _loadFAQs() {
    // 결제 관련 FAQ
    _faqs['billing_refund'] = const FAQ(
      id: 'billing_refund',
      question: '환불은 어떻게 하나요?',
      answer: '구매일로부터 7일 이내에 환불 가능합니다. 설정 > 결제 내역에서 환불을 요청하세요.',
      category: TicketCategory.billing,
      keywords: ['환불', '환불방법', '결제취소'],
    );

    _faqs['billing_error'] = const FAQ(
      id: 'billing_error',
      question: '결제가 오류가 뜹니다',
      answer: '인터넷 연결을 확인하고 다시 시도해 주세요. 계속 문제가 발생하면 고객센터에 문의해 주세요.',
      category: TicketCategory.billing,
      keywords: ['결제오류', '결제실패', '결제불가'],
    );

    // 기술적 문제 FAQ
    _faqs['technical_lag'] = const FAQ(
      id: 'technical_lag',
      question: '게임이 지연됩니다',
      answer: '와이파이 연결을 확인하고 주변 앱을 종료해 주세요. 설정 > 그래픽 옵션에서 품질을 낮추면 개선될 수 있습니다.',
      category: TicketCategory.technical,
      keywords: ['랙', '지연', '느림', '버벼'],
    );

    // 계정 관련 FAQ
    _faqs['account_password'] = const FAQ(
      id: 'account_password',
      question: '비밀번호를 잊어버렸습니다',
      answer: '로그인 화면에서 "비밀번호 찾기"를 클릭하고 이메일을 입력하여 재설정하세요.',
      category: TicketCategory.account,
      keywords: ['비밀번호찾기', '비번재설정', '로그인불가'],
    );
  }

  Future<void> _loadTickets() async {
    // 시뮬레이션: 저장된 티켓 로드
    final ticketsJson = await _prefs?.getString('tickets');
    if (ticketsJson != null) {
      // 실제로는 파싱
    }
  }

  /// 티켓 생성
  Future<Ticket> createTicket({
    required String userId,
    required String username,
    required TicketCategory category,
    required TicketPriority priority,
    required String subject,
    required String description,
    List<String>? attachments,
  }) async {
    // 감정 분석
    final sentiment = _analyzeSentiment(description);

    final ticket = Ticket(
      id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      username: username,
      category: category,
      status: TicketStatus.open,
      priority: sentiment.score < -0.5 ? TicketPriority.high : priority,
      subject: subject,
      description: description,
      attachments: attachments ?? [],
      createdAt: DateTime.now(),
    );

    _tickets[ticket.id] = ticket;
    _ticketController.add(ticket);

    await _saveTicket(ticket);

    debugPrint('[AutoCS] Ticket created: ${ticket.id}');

    return ticket;
  }

  /// 챗봇 질문
  Future<ChatbotResponse> askChatbot({
    required String question,
    String? userId,
  }) async {
    // FAQ 검색
    final matchedFAQs = _searchFAQs(question);

    if (matchedFAQs.isNotEmpty) {
      final faq = matchedFAQs.first;

      return ChatbotResponse(
        response: faq.answer,
        confidence: 0.9,
        suggestedActions: [
          '이 답변이 도움이 되셨나요?',
          '추가 질문이 있으신가요?',
        ],
        ticketCategory: faq.category.name,
        needsHumanSupport: false,
      );
    }

    // 감정 분석
    final sentiment = _analyzeSentiment(question);

    // LLM 기반 응답 (시뮬레이션)
    final response = _generateLLMResponse(question, sentiment);

    return ChatbotResponse(
      response: response,
      confidence: 0.7,
      suggestedActions: [
        '티켓을 생성하시겠습니까?',
        '다른 질문이 있으신가요?',
      ],
      needsHumanSupport: sentiment.score < -0.7,
    );
  }

  /// FAQ 검색
  List<FAQ> _searchFAQs(String query) {
    final lowerQuery = query.toLowerCase();

    // 키워드 매칭
    final keywordMatches = _faqs.values.where((faq) =>
        faq.keywords.any((keyword) => lowerQuery.contains(keyword.toLowerCase()))).toList();

    if (keywordMatches.isNotEmpty) {
      return keywordMatches;
    }

    // 텍스트 매칭
    final textMatches = _faqs.values.where((faq) =>
        faq.question.toLowerCase().contains(lowerQuery) ||
        faq.answer.toLowerCase().contains(lowerQuery)).toList();

    return textMatches;
  }

  /// 감정 분석
  SentimentAnalysis _analyzeSentiment(String text) {
    if (_sentimentCache.containsKey(text)) {
      return _sentimentCache[text]!;
    }

    // 간단한 감정 분석 (시뮬레이션)
    double score = 0.0;
    final emotions = <String, double>{};

    // 긍정적 단어
    final positiveWords = ['좋아', '감사', '최고', '칭찬', '만족', '좋습니다'];
    // 부정적 단어
    final negativeWords = ['별로', '최악', '불불', '속상', '화남', '안돼', '버그'];

    final lowerText = text.toLowerCase();

    for (final word in positiveWords) {
      if (lowerText.contains(word)) {
        score += 0.2;
        emotions['joy'] = (emotions['joy'] ?? 0.0) + 0.2;
      }
    }

    for (final word in negativeWords) {
      if (lowerText.contains(word)) {
        score -= 0.3;
        emotions['anger'] = (emotions['anger'] ?? 0.0) + 0.3;
        emotions['sadness'] = (emotions['sadness'] ?? 0.0) + 0.3;
      }
    }

    // 라벨 결정
    String label;
    if (score >= 0.3) {
      label = 'positive';
    } else if (score <= -0.3) {
      label = 'negative';
    } else {
      label = 'neutral';
    }

    final analysis = SentimentAnalysis(
      score: score.clamp(-1.0, 1.0),
      label: label,
      emotions: emotions,
    );

    _sentimentCache[text] = analysis;

    return analysis;
  }

  /// LLM 응답 생성
  String _generateLLMResponse(String query, SentimentAnalysis sentiment) {
    // 실제로는 LLM API 호출 (시뮬레이션)
    final responses = {
      'positive': '피드백을 주셔서 감사합니다. 더 도와드릴까요?',
      'negative': '불시해 드려 죄송합니다. 빠르게 해결해 드리겠습니다.',
      'neutral': '무엇을 도와드릴까요?',
    };

    return responses[sentiment.label] ?? responses['neutral']!;
  }

  /// 티켓 자동 분류
  TicketCategory _classifyTicket(String subject, String description) {
    final text = '$subject $description'.toLowerCase();

    // 키워드 기반 분류
    if (text.contains('결제') || text.contains('환불') || text.contains('청구')) {
      return TicketCategory.billing;
    } else if (text.contains('오류') || text.contains('버그') || text.contains('지연')) {
      return TicketCategory.technical;
    } else if (text.contains('로그인') || text.contains('비밀번호') || text.contains('계정')) {
      return TicketCategory.account;
    } else if (text.contains('제안') || text.contains('아이디어')) {
      return TicketCategory.suggestion;
    }

    return TicketCategory.other;
  }

  /// 티켓 업데이트
  Future<void> updateTicket({
    required String ticketId,
    TicketStatus? status,
    TicketPriority? priority,
    String? assignedTo,
    List<TicketMessage>? messages,
  }) async {
    final ticket = _tickets[ticketId];
    if (ticket == null) return;

    final updated = Ticket(
      id: ticket.id,
      userId: ticket.userId,
      username: ticket.username,
      category: ticket.category,
      status: status ?? ticket.status,
      priority: priority ?? ticket.priority,
      subject: ticket.subject,
      description: ticket.description,
      attachments: ticket.attachments,
      createdAt: ticket.createdAt,
      updatedAt: DateTime.now(),
      resolvedAt: status == TicketStatus.resolved ? DateTime.now() : ticket.resolvedAt,
      assignedTo: assignedTo ?? ticket.assignedTo,
      messages: messages ?? ticket.messages,
    );

    _tickets[ticketId] = updated;
    _ticketController.add(updated);

    await _saveTicket(updated);

    debugPrint('[AutoCS] Ticket updated: $ticketId');
  }

  /// 메시지 추가
  Future<void> addMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String content,
    bool isFromSupport = false,
    List<String>? attachments,
  }) async {
    final ticket = _tickets[ticketId];
    if (ticket == null) return;

    final message = TicketMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      ticketId: ticketId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      isFromSupport: isFromSupport,
      timestamp: DateTime.now(),
      attachments: attachments,
    );

    final updated = Ticket(
      id: ticket.id,
      userId: ticket.userId,
      username: ticket.username,
      category: ticket.category,
      status: ticket.status,
      priority: ticket.priority,
      subject: ticket.subject,
      description: ticket.description,
      attachments: ticket.attachments,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
      resolvedAt: ticket.resolvedAt,
      assignedTo: ticket.assignedTo,
      messages: [...ticket.messages, message],
    );

    _tickets[ticketId] = updated;
    _messageController.add(message);
    _ticketController.add(updated);

    debugPrint('[AutoCS] Message added: ${message.id}');
  }

  /// 자동 응답
  Future<void> sendAutoResponse({
    required String ticketId,
    required String response,
  }) async {
    final ticket = _tickets[ticketId];
    if (ticket == null) return;

    await addMessage(
      ticketId: ticketId,
      senderId: 'system',
      senderName: '자동 응답',
      content: response,
      isFromSupport: true,
    );

    debugPrint('[AutoCS] Auto response sent: $ticketId');
  }

  /// 티켓 조회
  Ticket? getTicket(String ticketId) {
    return _tickets[ticketId];
  }

  /// 사용자 티켓 목록
  List<Ticket> getUserTickets(String userId) {
    return _tickets.values
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 모든 티켓 조회
  List<Ticket> getAllTickets({TicketStatus? status}) {
    var tickets = _tickets.values.toList();

    if (status != null) {
      tickets = tickets.where((t) => t.status == status).toList();
    }

    return tickets;
  }

  /// FAQ 목록 조회
  List<FAQ> getFAQs({TicketCategory? category}) {
    var faqs = _faqs.values.toList();

    if (category != null) {
      faqs = faqs.where((f) => f.category == category).toList();
    }

    return faqs;
  }

  /// FAQ 조회수 증가
  Future<void> incrementFAQViews(String faqId) async {
    final faq = _faqs[faqId];
    if (faq == null) return;

    final updated = FAQ(
      id: faq.id,
      question: faq.question,
      answer: faq.answer,
      category: faq.category,
      keywords: faq.keywords,
      viewCount: faq.viewCount + 1,
      isPublished: faq.isPublished,
    );

    _faqs[faqId] = updated;

    debugPrint('[AutoCS] FAQ viewed: $faqId');
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    final statusCounts = <TicketStatus, int>{};
    for (final status in TicketStatus.values) {
      statusCounts[status] = _tickets.values.where((t) => t.status == status).length;
    }

    final avgResolutionTime = _calculateAvgResolutionTime();

    return {
      'totalTickets': _tickets.length,
      'statusDistribution': statusCounts.map((k, v) => MapEntry(k.name, v)),
      'avgResolutionTime': avgResolutionTime,
      'faqCount': _faqs.length,
    };
  }

  Duration _calculateAvgResolutionTime() {
    final resolved = _tickets.values.where((t) => t.resolvedAt != null);

    if (resolved.isEmpty) return Duration.zero;

    final totalMinutes = resolved.fold<int>(0, (sum, t) =>
        sum + t.resolvedAt!.difference(t.createdAt).inMinutes);

    return Duration(minutes: totalMinutes ~/ resolved.length);
  }

  Future<void> _saveTicket(Ticket ticket) async {
    await _prefs?.setString(
      'ticket_${ticket.id}',
      jsonEncode({
        'id': ticket.id,
        'userId': ticket.userId,
        'username': ticket.username,
        'category': ticket.category.name,
        'status': ticket.status.name,
        'priority': ticket.priority.name,
        'subject': ticket.subject,
        'description': ticket.description,
        'createdAt': ticket.createdAt.toIso8601String(),
      }),
    );
  }

  void dispose() {
    _ticketController.close();
    _messageController.close();
  }
}
