import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 티켓 상태
enum TicketStatus {
  open,
  inProgress,
  waitingCustomer,
  resolved,
  closed,
}

/// 티켓 카테고리
enum TicketCategory {
  bug,
  account,
  payment,
  gameplay,
  harassment,
  other,
}

/// 티켓 우선순위
enum TicketPriority {
  low,
  medium,
  high,
  urgent,
}

/// 고객센터 티켓
class Ticket {
  final String id;
  final String userId;
  final String username;
  final TicketCategory category;
  final TicketPriority priority;
  final String subject;
  final String description;
  final List<String> attachments;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? assignedAgentId;
  final List<TicketComment> comments;

  const Ticket({
    required this.id,
    required this.userId,
    required this.username,
    required this.category,
    required this.priority,
    required this.subject,
    required this.description,
    required this.attachments,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.assignedAgentId,
    this.comments = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'category': category.name,
        'priority': priority.name,
        'subject': subject,
        'description': description,
        'attachments': attachments,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'assignedAgentId': assignedAgentId,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'] as String,
        userId: json['userId'] as String,
        username: json['username'] as String,
        category: TicketCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => TicketCategory.other,
        ),
        priority: TicketPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => TicketPriority.medium,
        ),
        subject: json['subject'] as String,
        description: json['description'] as String,
        attachments: (json['attachments'] as List).cast<String>(),
        status: TicketStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TicketStatus.open,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
        assignedAgentId: json['assignedAgentId'] as String?,
        comments: (json['comments'] as List?)
                ?.map((c) => TicketComment.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// 티켓 댓글
class TicketComment {
  final String id;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final bool isAgent;

  const TicketComment({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.isAgent = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isAgent': isAgent,
      };

  factory TicketComment.fromJson(Map<String, dynamic> json) => TicketComment(
        id: json['id'] as String,
        userId: json['userId'] as String,
        username: json['username'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isAgent: json['isAgent'] as bool? ?? false,
      );
}

/// FAQ 항목
class FAQItem {
  final String id;
  final String category;
  final String question;
  final String answer;
  final List<String> tags;
  final int viewCount;
  final bool isHelpful;

  const FAQItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.tags,
    this.viewCount = 0,
    this.isHelpful = false,
  });
}

/// CS 매니저
class CustomerServiceManager {
  static final CustomerServiceManager _instance = CustomerServiceManager._();
  static CustomerServiceManager get instance => _instance;

  CustomerServiceManager._();

  SharedPreferences? _prefs;
  final Map<String, Ticket> _tickets = {};
  final List<FAQItem> _faqs = [];

  final StreamController<Ticket> _ticketController =
      StreamController<Ticket>.broadcast();

  Stream<Ticket> get onTicketUpdate => _ticketController.stream;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTickets();
    _loadDefaultFAQs();
  }

  Future<void> _loadTickets() async {
    final ticketsJson = _prefs!.getStringList('cs_tickets');
    if (ticketsJson != null) {
      for (final json in ticketsJson) {
        final ticket = Ticket.fromJson(jsonDecode(json) as Map<String, dynamic>);
        _tickets[ticket.id] = ticket;
      }
    }
  }

  void _loadDefaultFAQs() {
    _faqs.addAll([
      FAQItem(
        id: 'faq_001',
        category: '계정',
        question: '비밀번호를 잊어버렸어요',
        answer: '설정 > 계정 > 비밀번호 찾기에서 재설정할 수 있습니다.',
        tags: ['비밀번호', '계정'],
      ),
      FAQItem(
        id: 'faq_002',
        category: '결제',
        question: '결제가 실패했어요',
        answer: '결제 수단을 확인하시고 재시도해 주세요. 문제 지속 시 고객센터로 문의 바랍니다.',
        tags: ['결제', '환불'],
      ),
      FAQItem(
        id: 'faq_003',
        category: '게임',
        question: '저장이 안 되어요',
        answer: '인터넷 연결을 확인하고 앱을 재시작해 주세요.',
        tags: ['저장', '데이터'],
      ),
    ]);
  }

  Future<Ticket> createTicket({
    required String userId,
    required String username,
    required TicketCategory category,
    required TicketPriority priority,
    required String subject,
    required String description,
  }) async {
    final ticket = Ticket(
      id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      username: username,
      category: category,
      priority: priority,
      subject: subject,
      description: description,
      attachments: [],
      status: TicketStatus.open,
      createdAt: DateTime.now(),
    );

    _tickets[ticket.id] = ticket;
    await _saveTickets();

    _ticketController.add(ticket);
    return ticket;
  }

  Future<void> addComment({
    required String ticketId,
    required String userId,
    required String username,
    required String content,
    bool isAgent = false,
  }) async {
    final ticket = _tickets[ticketId];
    if (ticket == null) return;

    final comment = TicketComment(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      username: username,
      content: content,
      createdAt: DateTime.now(),
      isAgent: isAgent,
    );

    final updated = Ticket(
      id: ticket.id,
      userId: ticket.userId,
      username: ticket.username,
      category: ticket.category,
      priority: ticket.priority,
      subject: ticket.subject,
      description: ticket.description,
      attachments: ticket.attachments,
      status: ticket.status,
      createdAt: ticket.createdAt,
      resolvedAt: ticket.resolvedAt,
      assignedAgentId: ticket.assignedAgentId,
      comments: [...ticket.comments, comment],
    );

    _tickets[ticketId] = updated;
    await _saveTickets();

    _ticketController.add(updated);
  }

  List<FAQItem> searchFAQs(String query) {
    final lowerQuery = query.toLowerCase();

    return _faqs.where((faq) =>
      faq.question.toLowerCase().contains(lowerQuery) ||
      faq.answer.toLowerCase().contains(lowerQuery) ||
      faq.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  Ticket? getTicket(String ticketId) {
    return _tickets[ticketId];
  }

  List<Ticket> getUserTickets(String userId) {
    return _tickets.values.where((t) => t.userId == userId).toList();
  }

  Future<void> updateTicketStatus({
    required String ticketId,
    required TicketStatus newStatus,
  }) async {
    final ticket = _tickets[ticketId];
    if (ticket == null) return;

    final updated = Ticket(
      id: ticket.id,
      userId: ticket.userId,
      username: ticket.username,
      category: ticket.category,
      priority: ticket.priority,
      subject: ticket.subject,
      description: ticket.description,
      attachments: ticket.attachments,
      status: newStatus,
      createdAt: ticket.createdAt,
      resolvedAt: newStatus == TicketStatus.resolved ? DateTime.now() : ticket.resolvedAt,
      assignedAgentId: ticket.assignedAgentId,
      comments: ticket.comments,
    );

    _tickets[ticketId] = updated;
    await _saveTickets();
    _ticketController.add(updated);
  }

  Future<void> _saveTickets() async {
    final ticketsJson = _tickets.values.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs!.setStringList('cs_tickets', ticketsJson);
  }

  void dispose() {
    _ticketController.close();
  }
}
