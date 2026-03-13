import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 티켓 카테고리
enum TicketCategory {
  account,        // 계정
  payment,        // 결제
  bug,            // 버그
  gameplay,       // 게임플레이
  harassment,     // 하라스먼트
  technical,      // 기술적 문제
  suggestion,     // 제안
  other,          // 기타
}

/// 티켓 우선순위
enum TicketPriority {
  low,            // 낮음
  normal,         // 보통
  high,           // 높음
  urgent,         // 긴급
}

/// 티켓 상태
enum TicketStatus {
  open,           // 열림
  pending,        // 대기 중
  answered,       // 답변 완료
  resolved,       // 해결됨
  closed,         // 닫힘
  reopened,       // 재오픈
}

/// 지원 티켓
class SupportTicket {
  final String ticketId;
  final String userId;
  final String username;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final String subject;
  final String description;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? assignedAgentId;
  final String? assignedAgentName;
  final List<TicketMessage> messages;
  final int? satisfactionRating; // 1-5

  const SupportTicket({
    required this.ticketId,
    required this.userId,
    required this.username,
    required this.category,
    required this.priority,
    required this.status,
    required this.subject,
    required this.description,
    this.attachments,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.assignedAgentId,
    this.assignedAgentName,
    required this.messages,
    this.satisfactionRating,
  });

  /// 미해결 여부
  bool get isUnresolved => status.index <= TicketStatus.answered.index;

  /// 응답 대기 시간
  Duration? get responseTime {
    if (status != TicketStatus.open) return null;
    return DateTime.now().difference(createdAt);
  }

  /// 마지막 메시지
  TicketMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }
}

/// 티켓 메시지
class TicketMessage {
  final String messageId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final bool isAgent; // 상담원 여부
  final String content;
  final List<String>? attachments;
  final DateTime timestamp;
  final bool isInternal; // 내부 메모

  const TicketMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.isAgent,
    required this.content,
    this.attachments,
    required this.timestamp,
    this.isInternal = false,
  });
}

/// FAQ
class FAQ {
  final String faqId;
  final String category;
  final String question;
  final String answer;
  final int order;
  final List<String> tags;
  final int viewCount;
  final bool isHelpful;

  const FAQ({
    required this.faqId,
    required this.category,
    required this.question,
    required this.answer,
    required this.order,
    required this.tags,
    required this.viewCount,
    required this.isHelpful,
  });
}

/// 지원 챗봇 메시지
class ChatbotMessage {
  final String messageId;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<ChatbotSuggestion>? suggestions;

  const ChatbotMessage({
    required this.messageId,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.suggestions,
  });
}

/// 챗봇 제안
class ChatbotSuggestion {
  final String text;
  final String action;
  final Map<String, dynamic>? data;

  const ChatbotSuggestion({
    required this.text,
    required this.action,
    this.data,
  });
}

/// 지원 통계
class SupportStatistics {
  final int totalTickets;
  final int openTickets;
  final int resolvedTickets;
  final double averageResolutionTime; // hours
  final double satisfactionRate;
  final Map<TicketCategory, int> categoryDistribution;

  const SupportStatistics({
    required this.totalTickets,
    required this.openTickets,
    required this.resolvedTickets,
    required this.averageResolutionTime,
    required this.satisfactionRate,
    required this.categoryDistribution,
  });
}

/// 고객 지원 관리자
class CustomerSupportManager {
  static final CustomerSupportManager _instance =
      CustomerSupportManager._();
  static CustomerSupportManager get instance => _instance;

  CustomerSupportManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final List<SupportTicket> _tickets = [];
  final List<FAQ> _faqs = [];
  final List<ChatbotMessage> _chatbotHistory = [];

  final StreamController<SupportTicket> _ticketController =
      StreamController<SupportTicket>.broadcast();
  final StreamController<TicketMessage> _messageController =
      StreamController<TicketMessage>.broadcast();

  Stream<SupportTicket> get onTicketUpdate => _ticketController.stream;
  Stream<TicketMessage> get onNewMessage => _messageController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // FAQ 로드
    _loadFAQs();

    // 티켓 로드
    if (_currentUserId != null) {
      await _loadTickets(_currentUserId!);
    }

    debugPrint('[CustomerSupport] Initialized');
  }

  void _loadFAQs() {
    _faqs.addAll([
      const FAQ(
        faqId: 'faq_1',
        category: '계정',
        question: '비밀번호를 잊어버렸어요',
        answer: '로그인 화면에서 "비밀번호 찾기"를 클릭하세요. 이메일로 비밀번호 재설정 링크가 발송됩니다.',
        order: 1,
        tags: ['비밀번호', '로그인'],
        viewCount: 1523,
        isHelpful: true,
      ),
      const FAQ(
        faqId: 'faq_2',
        category: '결제',
        question: '결제가 완료되지 않았어요',
        answer: '결제 오류 발생 시 24시간 이내에 자동 환불됩니다. 재결제를 시도해 주세요.',
        order: 2,
        tags: ['결제', '환불'],
        viewCount: 892,
        isHelpful: false,
      ),
      const FAQ(
        faqId: 'faq_3',
        category: '게임',
        question: '게임이 중단되어요',
        answer: '최신 버전으로 업데이트했는지 확인해 주세요. 문제가 지속되면 재설치를 권장합니다.',
        order: 3,
        tags: ['버그', '중단'],
        viewCount: 2341,
        isHelpful: true,
      ),
      const FAQ(
        faqId: 'faq_4',
        category: '계정',
        question: '계정을 삭제하고 싶어요',
        answer: '설정 > 계정 > 계정 삭제 메뉴에서 진행할 수 있습니다. 삭제 후 30일 동안 복구 가능합니다.',
        order: 4,
        tags: ['탈퇴', '삭제'],
        viewCount: 456,
        isHelpful: false,
      ),
    ]);
  }

  Future<void> _loadTickets(String userId) async {
    final json = _prefs?.getString('tickets_$userId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[CustomerSupport] Error loading tickets: $e');
      }
    }

    // 샘플 티켓
    _tickets.add(SupportTicket(
      ticketId: 'ticket_1',
      userId: userId,
      username: 'Player123',
      category: TicketCategory.bug,
      priority: TicketPriority.normal,
      status: TicketStatus.resolved,
      subject: '던전 입장 불가',
      description: 'Lv.20 던전에 입장하려고 하는데 입장이 안됩니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 4)),
      assignedAgentName: '상담원 A',
      messages: const [
        TicketMessage(
          messageId: 'msg_1',
          senderId: userId,
          senderName: 'Player123',
          isAgent: false,
          content: '던전 입장이 안됩니다.',
          timestamp: DateTime(2024, 1, 10, 10, 0),
        ),
        TicketMessage(
          messageId: 'msg_2',
          senderId: 'agent_1',
          senderName: '상담원 A',
          isAgent: true,
          content: '안녕하세요. 문제를 확인했습니다. 클라이언트 업데이트 후 정상 작동할 것입니다.',
          timestamp: DateTime(2024, 1, 10, 11, 0),
        ),
      ],
      satisfactionRating: 5,
    ));
  }

  /// 티켓 생성
  Future<SupportTicket?> createTicket({
    required TicketCategory category,
    required TicketPriority priority,
    required String subject,
    required String description,
    List<String>? attachments,
  }) async {
    if (_currentUserId == null) return null;

    final ticket = SupportTicket(
      ticketId: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId!,
      username: 'Player123', // 실제 유저명
      category: category,
      priority: priority,
      status: TicketStatus.open,
      subject: subject,
      description: description,
      attachments: attachments,
      createdAt: DateTime.now(),
      messages: [
        TicketMessage(
          messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: _currentUserId!,
          senderName: 'Player123',
          isAgent: false,
          content: description,
          timestamp: DateTime.now(),
        ),
      ],
    );

    _tickets.add(ticket);
    _ticketController.add(ticket);

    await _saveTickets();

    debugPrint('[CustomerSupport] Ticket created: ${ticket.ticketId}');

    return ticket;
  }

  /// 티켓에 메시지 추가
  Future<bool> addMessage({
    required String ticketId,
    required String content,
    List<String>? attachments,
  }) async {
    if (_currentUserId == null) return false;

    final ticketIndex = _tickets.indexWhere((t) => t.ticketId == ticketId);
    if (ticketIndex == -1) return false;

    final ticket = _tickets[ticketIndex];

    final message = TicketMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUserId!,
      senderName: 'Player123',
      isAgent: false,
      content: content,
      attachments: attachments,
      timestamp: DateTime.now(),
    );

    final updated = SupportTicket(
      ticketId: ticket.ticketId,
      userId: ticket.userId,
      username: ticket.username,
      category: ticket.category,
      priority: ticket.priority,
      status: ticket.status == TicketStatus.resolved
          ? TicketStatus.reopened
          : ticket.status,
      subject: ticket.subject,
      description: ticket.description,
      attachments: ticket.attachments,
      createdAt: ticket.createdAt,
      updatedAt: DateTime.now(),
      resolvedAt: ticket.resolvedAt,
      assignedAgentId: ticket.assignedAgentId,
      assignedAgentName: ticket.assignedAgentName,
      messages: [...ticket.messages, message],
      satisfactionRating: ticket.satisfactionRating,
    );

    _tickets[ticketIndex] = updated;
    _ticketController.add(updated);
    _messageController.add(message);

    await _saveTickets();

    return true;
  }

  /// 티켓 닫기
  Future<bool> closeTicket(String ticketId) async {
    final ticketIndex = _tickets.indexWhere((t) => t.ticketId == ticketId);
    if (ticketIndex == -1) return false;

    final ticket = _tickets[ticketIndex];

    final updated = SupportTicket(
      ticketId: ticket.ticketId,
      userId: ticket.userId,
      username: ticket.username,
      category: ticket.category,
      priority: ticket.priority,
      status: TicketStatus.closed,
      subject: ticket.subject,
      description: ticket.description,
      attachments: ticket.attachments,
      createdAt: ticket.createdAt,
      updatedAt: DateTime.now(),
      resolvedAt: DateTime.now(),
      assignedAgentId: ticket.assignedAgentId,
      assignedAgentName: ticket.assignedAgentName,
      messages: ticket.messages,
      satisfactionRating: ticket.satisfactionRating,
    );

    _tickets[ticketIndex] = updated;
    _ticketController.add(updated);

    await _saveTickets();

    debugPrint('[CustomerSupport] Ticket closed: $ticketId');

    return true;
  }

  /// 만족도 평가
  Future<bool> rateTicket({
    required String ticketId,
    required int rating, // 1-5
  }) async {
    if (rating < 1 || rating > 5) return false;

    final ticketIndex = _tickets.indexWhere((t) => t.ticketId == ticketId);
    if (ticketIndex == -1) return false;

    final ticket = _tickets[ticketIndex];

    final updated = SupportTicket(
      ticketId: ticket.ticketId,
      userId: ticket.userId,
      username: ticket.username,
      category: ticket.category,
      priority: ticket.priority,
      status: ticket.status,
      subject: ticket.subject,
      description: ticket.description,
      attachments: ticket.attachments,
      createdAt: ticket.createdAt,
      updatedAt: DateTime.now(),
      resolvedAt: ticket.resolvedAt,
      assignedAgentId: ticket.assignedAgentId,
      assignedAgentName: ticket.assignedAgentName,
      messages: ticket.messages,
      satisfactionRating: rating,
    );

    _tickets[ticketIndex] = updated;
    _ticketController.add(updated);

    await _saveTickets();

    debugPrint('[CustomerSupport] Ticket rated: $ticketId - $rating/5');

    return true;
  }

  /// FAQ 검색
  List<FAQ> searchFAQs(String query) {
    if (query.isEmpty) return _faqs.toList();

    final lowerQuery = query.toLowerCase();
    return _faqs.where((faq) =>
        faq.question.toLowerCase().contains(lowerQuery) ||
        faq.answer.toLowerCase().contains(lowerQuery) ||
        faq.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// 카테고리별 FAQ
  List<FAQ> getFAQsByCategory(String category) {
    return _faqs.where((faq) => faq.category == category).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// FAQ 도움됨 표시
  Future<bool> markFAQHelpful(String faqId, bool isHelpful) async {
    final index = _faqs.indexWhere((f) => f.faqId == faqId);
    if (index == -1) return false;

    // 실제로는 서버 업데이트
    debugPrint('[CustomerSupport] FAQ rated: $faqId - $isHelpful');

    return true;
  }

  /// 챗봇 메시지 전송
  Future<ChatbotMessage?> sendChatbotMessage(String message) async {
    final userMessage = ChatbotMessage(
      messageId: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _chatbotHistory.add(userMessage);

    // 챗봇 응답 생성 (시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 500));

    final response = _generateChatbotResponse(message);
    final botMessage = ChatbotMessage(
      messageId: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      content: response.content,
      isUser: false,
      timestamp: DateTime.now(),
      suggestions: response.suggestions,
    );

    _chatbotHistory.add(botMessage);

    return botMessage;
  }

  ChatbotMessage _generateChatbotResponse(String query) {
    final lowerQuery = query.toLowerCase();

    // 간단한 키워드 기반 응답
    if (lowerQuery.contains('비밀번호') || lowerQuery.contains('로그인')) {
      return const ChatbotMessage(
        messageId: '',
        content: '비밀번호를 잊으셨나요? 로그인 화면에서 "비밀번호 찾기"를 클릭하시면 이메일로 재설정 링크가 발송됩니다.',
        isUser: false,
        timestamp: null,
        suggestions: [
          ChatbotSuggestion(
            text: '비밀번호 찾기',
            action: 'open_password_reset',
          ),
          ChatbotSuggestion(
            text: '로그인 문제',
            action: 'open_login_help',
          ),
          ChatbotSuggestion(
            text: '상담원 연결',
            action: 'create_ticket',
          ),
        ],
      );
    }

    if (lowerQuery.contains('결제') || lowerQuery.contains('환불')) {
      return const ChatbotMessage(
        messageId: '',
        content: '결제 관련 문제는 고객센터로 문의해 주시면 빠르게 도와드리겠습니다. 결제 오류 시 24시간 이내 자동 환불됩니다.',
        isUser: false,
        timestamp: null,
        suggestions: [
          ChatbotSuggestion(
            text: '결제 문의 티켓',
            action: 'create_payment_ticket',
          ),
          ChatbotSuggestion(
            text: '환불 안내',
            action: 'open_refund_policy',
          ),
        ],
      );
    }

    if (lowerQuery.contains('버그') || lowerQuery.contains('오류')) {
      return const ChatbotMessage(
        messageId: '',
        content: '버그를 신고해 주셔서 감사합니다. 자세한 내용을 알려주시면 빠르게 확인하겠습니다.',
        isUser: false,
        timestamp: null,
        suggestions: [
          ChatbotSuggestion(
            text: '버그 신고',
            action: 'create_bug_ticket',
          ),
          ChatbotSuggestion(
            text: '자주 묻는 질문',
            action: 'show_faq',
          ),
        ],
      );
    }

    // 기본 응답
    return const ChatbotMessage(
      messageId: '',
      content: '무엇을 도와드릴까요? 아래 버튼을 선택하시거나 구체적으로 물어봐 주세요.',
      isUser: false,
      timestamp: null,
      suggestions: [
        ChatbotSuggestion(
          text: '계정 문제',
          action: 'category_account',
        ),
        ChatbotSuggestion(
          text: '결제 문제',
          action: 'category_payment',
        ),
        ChatbotSuggestion(
          text: '버그 신고',
          action: 'category_bug',
        ),
        ChatbotSuggestion(
          text: '상담원 연결',
          action: 'create_ticket',
        ),
      ],
    );
  }

  /// 티켓 목록
  List<SupportTicket> getTickets({TicketStatus? status}) {
    var tickets = _tickets.toList();
    if (status != null) {
      tickets = tickets.where((t) => t.status == status).toList();
    }
    return tickets..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 티켓 조회
  SupportTicket? getTicket(String ticketId) {
    return _tickets.cast<SupportTicket?>.firstWhere(
      (t) => t?.ticketId == ticketId,
      orElse: () => null,
    );
  }

  /// 챗봇 기록
  List<ChatbotMessage> getChatbotHistory() {
    return _chatbotHistory.toList();
  }

  /// 챗봇 기록 초기화
  void clearChatbotHistory() {
    _chatbotHistory.clear();
  }

  Future<void> _saveTickets() async {
    if (_currentUserId == null) return;

    final data = {
      'tickets': _tickets.map((t) => {
        'ticketId': t.ticketId,
        'status': t.status.name,
        'category': t.category.name,
      }).toList(),
    };

    await _prefs?.setString(
      'tickets_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _ticketController.close();
    _messageController.close();
  }
}
