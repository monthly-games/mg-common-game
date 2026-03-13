import 'package:flutter/material.dart';
import 'package:mg_common_game/cs/customer_service.dart';

/// 고객센터 메인 화면
class CustomerServiceScreen extends StatefulWidget {
  const CustomerServiceScreen({super.key});

  @override
  State<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen> {
  final _csManager = CustomerServiceManager.instance;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객센터'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          FAQListScreen(),
          TicketListScreen(),
          ContactFormScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'FAQ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: '내 티켓',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: '문의하기',
          ),
        ],
      ),
    );
  }
}

/// FAQ 목록 화면
class FAQListScreen extends StatefulWidget {
  const FAQListScreen({super.key});

  @override
  State<FAQListScreen> createState() => _FAQListScreenState();
}

class _FAQListScreenState extends State<FAQListScreen> {
  final _csManager = CustomerServiceManager.instance;
  final _searchController = TextEditingController();
  List<FAQItem> _searchResults = [];
  bool _hasSearched = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'FAQ 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _hasSearched = false;
                          _searchResults = [];
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _searchResults = _csManager.searchFAQs(value);
                  _hasSearched = true;
                });
              } else {
                setState(() {
                  _hasSearched = false;
                  _searchResults = [];
                });
              }
            },
          ),
        ),
        Expanded(
          child: _hasSearched
              ? _searchResults.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final faq = _searchResults[index];
                        return FAQCard(faq: faq);
                      },
                    )
              : const FAQCategoryList(),
        ),
      ],
    );
  }
}

/// FAQ 카테고리 목록
class FAQCategoryList extends StatelessWidget {
  const FAQCategoryList({super.key});

  final categories = const [
    {'icon': Icons.person, 'title': '계정', 'color': Colors.blue},
    {'icon': Icons.payment, 'title': '결제', 'color': Colors.green},
    {'icon': Icons.gamepad, 'title': '게임', 'color': Colors.purple},
    {'icon': Icons.bug_report, 'title': '버그', 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    final csManager = CustomerServiceManager.instance;

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final icon = category['icon'] as IconData;
        final title = category['title'] as String;
        final color = category['color'] as Color;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            title: Text(title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final faqs = csManager.searchFAQs(title);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FAQCategoryScreen(
                    category: title,
                    faqs: faqs,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// FAQ 카테고리 화면
class FAQCategoryScreen extends StatelessWidget {
  final String category;
  final List<FAQItem> faqs;

  const FAQCategoryScreen({
    super.key,
    required this.category,
    required this.faqs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: faqs.isEmpty
          ? const Center(child: Text('등록된 FAQ가 없습니다'))
          : ListView.builder(
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                return FAQCard(faq: faq);
              },
            ),
    );
  }
}

/// FAQ 카드
class FAQCard extends StatelessWidget {
  final FAQItem faq;

  const FAQCard({super.key, required this.faq});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(faq.question),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(faq.answer),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: faq.tags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.visibility, size: 16),
                    const SizedBox(width: 4),
                    Text('${faq.viewCount} 조회'),
                    const SizedBox(width: 16),
                    const Icon(Icons.thumb_up, size: 16),
                    const SizedBox(width: 4),
                    const Text('도움이 됨'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 티켓 목록 화면
class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final _csManager = CustomerServiceManager.instance;
  List<Ticket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _loading = true);

    // 실제로는 현재 사용자의 티켓 로드
    _tickets = _csManager.getUserTickets('current_user');

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _tickets.isEmpty
            ? const Center(child: Text('등록된 티켓이 없습니다'))
            : ListView.builder(
                itemCount: _tickets.length,
                itemBuilder: (context, index) {
                  final ticket = _tickets[index];
                  return TicketCard(ticket: ticket);
                },
              );
  }
}

/// 티켓 카드
class TicketCard extends StatelessWidget {
  final Ticket ticket;

  const TicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticket: ticket),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 8),
              Text(ticket.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCategoryChip(),
                  const SizedBox(width: 8),
                  _buildPriorityChip(),
                  const Spacer(),
                  Text(
                    ticket.createdAt.toString().split('.')[0],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final statusInfo = _getStatusInfo(ticket.status);

    return Chip(
      label: Text(statusInfo['label'] as String),
      backgroundColor: statusInfo['color'] as Color,
      labelStyle: const TextStyle(color: Colors.white),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildCategoryChip() {
    return Chip(
      label: Text(_getCategoryName(ticket.category)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPriorityChip() {
    final priorityColor = _getPriorityColor(ticket.priority);

    return Chip(
      label: Text(_getPriorityName(ticket.priority)),
      backgroundColor: priorityColor.withOpacity(0.1),
      labelStyle: TextStyle(color: priorityColor),
      visualDensity: VisualDensity.compact,
    );
  }

  Map<String, dynamic> _getStatusInfo(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return {'label': '접수', 'color': Colors.blue};
      case TicketStatus.inProgress:
        return {'label': '처리중', 'color': Colors.orange};
      case TicketStatus.waitingCustomer:
        return {'label': '고객대기', 'color': Colors.purple};
      case TicketStatus.resolved:
        return {'label': '해결', 'color': Colors.green};
      case TicketStatus.closed:
        return {'label': '종료', 'color': Colors.grey};
    }
  }

  String _getCategoryName(TicketCategory category) {
    switch (category) {
      case TicketCategory.bug:
        return '버그';
      case TicketCategory.account:
        return '계정';
      case TicketCategory.payment:
        return '결제';
      case TicketCategory.gameplay:
        return '게임';
      case TicketCategory.harassment:
        return '신고';
      case TicketCategory.other:
        return '기타';
    }
  }

  String _getPriorityName(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return '낮음';
      case TicketPriority.medium:
        return '보통';
      case TicketPriority.high:
        return '높음';
      case TicketPriority.urgent:
        return '긴급';
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Colors.grey;
      case TicketPriority.medium:
        return Colors.blue;
      case TicketPriority.high:
        return Colors.orange;
      case TicketPriority.urgent:
        return Colors.red;
    }
  }
}

/// 티켓 상세 화면
class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _csManager = CustomerServiceManager.instance;
  final _commentController = TextEditingController();
  Ticket? _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  @override
  Widget build(BuildContext context) {
    if (_ticket == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text(_ticket!.subject)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTicketInfo(),
                const SizedBox(height: 24),
                const Text(
                  '댓글',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._ticket!.comments.map((comment) => CommentTile(comment: comment)),
              ],
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildTicketInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_ticket!.description),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TicketCard(ticket: _ticket!)._buildStatusChip(),
                TicketCard(ticket: _ticket!)._buildCategoryChip(),
                TicketCard(ticket: _ticket!)._buildPriorityChip(),
              ],
            ),
            const SizedBox(height: 8),
            Text('생성일: ${_ticket!.createdAt}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: '댓글을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _addComment,
            icon: const Icon(Icons.send),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    await _csManager.addComment(
      ticketId: _ticket!.id,
      userId: 'current_user',
      username: '사용자',
      content: _commentController.text,
    );

    _commentController.clear();

    // 티켓 새로고침
    final updated = _csManager.getTicket(_ticket!.id);
    setState(() => _ticket = updated);
  }
}

/// 댓글 타일
class CommentTile extends StatelessWidget {
  final TicketComment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: comment.isAgent ? Colors.blue : Colors.grey,
          child: Icon(comment.isAgent ? Icons.support_agent : Icons.person),
        ),
        title: Text(comment.username),
        subtitle: Text(comment.createdAt.toString().split('.')[0]),
        trailing: comment.isAgent
            ? const Chip(label: Text('상담원'), visualDensity: VisualDensity.compact)
            : null,
      ),
    );
  }
}

/// 문의하기 양식
class ContactFormScreen extends StatefulWidget {
  const ContactFormScreen({super.key});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  TicketCategory _selectedCategory = TicketCategory.other;
  TicketPriority _selectedPriority = TicketPriority.medium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의하기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<TicketCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              items: TicketCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryName(category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TicketPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: '우선순위',
                border: OutlineInputBorder(),
              ),
              items: TicketPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(_getPriorityName(priority)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPriority = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? '제목을 입력하세요' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
              validator: (value) => value?.isEmpty ?? true ? '내용을 입력하세요' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitTicket,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('접수하기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final csManager = CustomerServiceManager.instance;

    await csManager.createTicket(
      userId: 'current_user',
      username: '사용자',
      category: _selectedCategory,
      priority: _selectedPriority,
      subject: _subjectController.text,
      description: _descriptionController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('티켓이 접수되었습니다')),
      );
      Navigator.pop(context);
    }
  }

  String _getCategoryName(TicketCategory category) {
    switch (category) {
      case TicketCategory.bug:
        return '버그';
      case TicketCategory.account:
        return '계정';
      case TicketCategory.payment:
        return '결제';
      case TicketCategory.gameplay:
        return '게임';
      case TicketCategory.harassment:
        return '신고';
      case TicketCategory.other:
        return '기타';
    }
  }

  String _getPriorityName(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return '낮음';
      case TicketPriority.medium:
        return '보통';
      case TicketPriority.high:
        return '높음';
      case TicketPriority.urgent:
        return '긴급';
    }
  }
}
