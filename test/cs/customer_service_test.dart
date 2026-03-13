import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/cs/customer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialize Flutter binding for tests that use SharedPreferences or platform channels
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('CustomerServiceManager', () {
    late CustomerServiceManager csManager;

    setUp(() async {
      // Mock SharedPreferences before CustomerServiceManager initialization
      SharedPreferences.setMockInitialValues({});
      csManager = CustomerServiceManager.instance;
      await csManager.initialize();
    });

    test('티켓 생성', () async {
      final ticket = await csManager.createTicket(
        userId: 'user_001',
        username: '테스터',
        category: TicketCategory.bug,
        priority: TicketPriority.high,
        subject: '버그 신고',
        description: '게임이 종료됩니다',
      );

      expect(ticket.id, startsWith('ticket_'));
      expect(ticket.userId, 'user_001');
      expect(ticket.category, TicketCategory.bug);
      expect(ticket.status, TicketStatus.open);
    });

    test('티켓 댓글 추가', () async {
      final ticket = await csManager.createTicket(
        userId: 'user_001',
        username: '테스터',
        category: TicketCategory.account,
        priority: TicketPriority.medium,
        subject: '계정 문제',
        description: '로그인이 안 됩니다',
      );

      await csManager.addComment(
        ticketId: ticket.id,
        userId: 'agent_001',
        username: '상담원',
        content: '확인하겠습니다',
        isAgent: true,
      );

      final updatedTicket = csManager.getTicket(ticket.id);
      expect(updatedTicket?.comments.length, 1);
      expect(updatedTicket?.comments.first.isAgent, true);
    });

    test('FAQ 검색', () {
      final results = csManager.searchFAQs('비밀번호');

      expect(results.length, greaterThan(0));
      expect(results.first.question, contains('비밀번호'));
    });

    test('티켓 태그 검색', () {
      final results = csManager.searchFAQs('결제');

      expect(results.length, greaterThan(0));
      expect(results.any((faq) => faq.tags.contains('결제')), true);
    });

    test('진행 중인 티켓 조회', () async {
      await csManager.createTicket(
        userId: 'user_001',
        username: '테스터',
        category: TicketCategory.payment,
        priority: TicketPriority.urgent,
        subject: '결제 실패',
        description: '결제가 안 됩니다',
      );

      final userTickets = csManager.getUserTickets('user_001');
      expect(userTickets.length, 1);
    });

    test('티켓 상태 변경', () async {
      final ticket = await csManager.createTicket(
        userId: 'user_001',
        username: '테스터',
        category: TicketCategory.gameplay,
        priority: TicketPriority.low,
        subject: '게임 질문',
        description: '어떻게 하나요?',
      );

      await csManager.updateTicketStatus(
        ticketId: ticket.id,
        newStatus: TicketStatus.inProgress,
      );

      final updated = csManager.getTicket(ticket.id);
      expect(updated?.status, TicketStatus.inProgress);
    });

    test('FAQ 도움말 투표', () {
      final faqs = csManager.searchFAQs('저장');

      if (faqs.isNotEmpty) {
        // FAQ 도움말 여부 확인
        expect(faqs.first.isHelpful, isA<bool>());
      }
    });
  });
}
