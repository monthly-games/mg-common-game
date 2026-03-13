import 'package:flutter/material.dart';
import 'package:mg_common_game/ai/ai_chatbot.dart';

/// AI 챗봇 대화 화면
class AIChatbotScreen extends StatefulWidget {
  final String npcId;

  const AIChatbotScreen({super.key, required this.npcId});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final _chatbot = AIChatbotManager.instance;
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  NPCPersona? _npc;

  @override
  void initState() {
    super.initState();
    _loadNPC();
  }

  void _loadNPC() {
    // NPC 정보 로드
    final npcs = {
      'quest_giver': const NPCPersona(
        id: 'quest_giver',
        name: '퀘스트 마스터',
        personality: '친절하고 도움을 줌',
        background: '수년간 모험가들에게 퀘스트를 제공해왔습니다',
        speakingStyle: '정중하고 예의 바름',
        knowledge: {
          'world_lore': '판타지 세계의 역사와 지리',
          'monsters': '몬스터의 약점과 공략법',
        },
      ),
      'merchant': const NPCPersona(
        id: 'merchant',
        name: '상인 라스',
        personality: '상술적이고 친절함',
        background: '전국을 여행하는 상인으로 귀한 물건을 많이 가지고 있습니다',
        speakingStyle: '장사적인 어조',
        knowledge: {
          'items': '아이템의 가격과 희귀성',
          'markets': '각 지역의 시세',
        },
      ),
      'trainer': const NPCPersona(
        id: 'trainer',
        name: '트레이너 리오',
        personality: '엄격하지만 열정적임',
        background: '전설적인 영웅으로 젊은이들을 훈련시킵니다',
        speakingStyle: '동기부여를 주며 명확함',
        knowledge: {
          'combat': '전투 기술과 전략',
          'fitness': '체력 단련법',
        },
      ),
    };

    setState(() => _npc = npcs[widget.npcId]);

    // 환영 메시지
    _addMessage(
      ChatMessage(
        id: 'welcome',
        role: MessageRole.assistant,
        content: _getWelcomeMessage(),
        timestamp: DateTime.now(),
      ),
    );
  }

  String _getWelcomeMessage() {
    if (_npc == null) return '안녕하세요!';

    switch (_npc!.id) {
      case 'quest_giver':
        return '어서 오세요, 모험가님! 오늘 어떤 퀘스트를 찾고 계신가요?';
      case 'merchant':
        return '어서 오세요~ 제 가게에는 최고의 물건들이 가득합니다!';
      case 'trainer':
        return '자, 훈련을 시작할 준비가 되었나?';
      default:
        return '안녕하세요!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_npc?.name ?? 'NPC'),
            if (_isTyping)
              const Text(
                '입력 중...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showVoiceInput,
            icon: const Icon(Icons.mic),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _chatbot.clearHistory();
                  setState(() => _messages.clear());
                  break;
                case 'quest':
                  _showQuestGenerator();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'quest',
                child: ListTile(
                  leading: Icon(Icons.assignment),
                  title: Text('퀘스트 생성'),
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear),
                  title: Text('대화 초기화'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
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
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '${_npc?.name ?? 'NPC'}에게 메시지를 보내세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _sendMessage(_messageController.text),
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    _messageController.clear();

    _addMessage(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    ));

    setState(() => _isTyping = true);

    try {
      final response = await _chatbot.chatWithNPC(
        npcId: widget.npcId,
        userMessage: text,
      );

      setState(() => _isTyping = false);

      _addMessage(ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch + 1}',
        role: MessageRole.assistant,
        content: response,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      setState(() => _isTyping = false);

      _addMessage(ChatMessage(
        id: 'error',
        role: MessageRole.assistant,
        content: '죄송합니다. 잠시 연결할 수 없습니다.',
        timestamp: DateTime.now(),
      ));
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() => _messages.add(message));

    // 스크롤을 맨 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showVoiceInput() {
    showModalBottomSheet(
      context: context,
      builder: (context) => VoiceInputSheet(
        onSubmit: (text) => _sendMessage(text),
      ),
    );
  }

  void _showQuestGenerator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => QuestGeneratorSheet(
        npcId: widget.npcId,
        onGenerated: (quest) {
          _addMessage(ChatMessage(
            id: 'quest_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.assistant,
            content: quest,
            timestamp: DateTime.now(),
          ));
        },
      ),
    );
  }
}

/// 메시지 버블
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 음성 입력 시트
class VoiceInputSheet extends StatefulWidget {
  final Function(String) onSubmit;

  const VoiceInputSheet({super.key, required this.onSubmit});

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet> {
  bool _isRecording = false;
  final _chatbot = AIChatbotManager.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isRecording ? '듣고 있습니다...' : '음성 입력',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _toggleRecording,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: _isRecording ? Colors.red : Colors.grey[300],
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 40,
                color: _isRecording ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_isRecording ? 'tap to stop' : 'tap to record'),
        ],
      ),
    );
  }

  void _toggleRecording() async {
    setState(() => _isRecording = !_isRecording);

    if (!_isRecording) {
      // 녹음 중지 및 처리
      final result = await _chatbot.processVoiceInput('/path/to/audio.wav');

      if (mounted) {
        Navigator.pop(context);
        widget.onSubmit(result);
      }
    }
  }
}

/// 퀘스트 생성기 시트
class QuestGeneratorSheet extends StatefulWidget {
  final String npcId;
  final Function(String) onGenerated;

  const QuestGeneratorSheet({
    super.key,
    required this.npcId,
    required this.onGenerated,
  });

  @override
  State<QuestGeneratorSheet> createState() => _QuestGeneratorSheetState();
}

class _QuestGeneratorSheetState extends State<QuestGeneratorSheet> {
  final _themeController = TextEditingController();
  final _chatbot = AIChatbotManager.instance;

  int _difficulty = 5;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AI 퀘스트 생성',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _themeController,
            decoration: const InputDecoration(
              labelText: '퀘스트 테마',
              border: OutlineInputBorder(),
              helperText: '예: 드래곤 사냥, 보물 찾기',
            ),
          ),
          const SizedBox(height: 16),
          const Text('난이도'),
          Slider(
            value: _difficulty.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_difficulty',
            onChanged: (value) {
              setState(() => _difficulty = value.toInt());
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generating ? null : _generateQuest,
            child: _generating
                ? const CircularProgressIndicator()
                : const Text('생성하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQuest() async {
    if (_themeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('퀘스트 테마를 입력하세요')),
      );
      return;
    }

    setState(() => _generating = true);

    final quest = await _chatbot.generateQuest(
      theme: _themeController.text,
      difficulty: _difficulty,
      context: {
        'npc': widget.npcId,
      },
    );

    setState(() => _generating = false);

    if (mounted) {
      Navigator.pop(context);
      widget.onGenerated(quest);
    }
  }
}

/// NPC 선택 화면
class NPCSelectorScreen extends StatelessWidget {
  const NPCSelectorScreen({super.key});

  final npcs = const [
    {
      'id': 'quest_giver',
      'name': '퀘스트 마스터',
      'description': '다양한 퀘스트를 제공합니다',
      'icon': Icons.assignment,
      'color': Colors.blue,
    },
    {
      'id': 'merchant',
      'name': '상인 라스',
      'description': '아이템을 거래합니다',
      'icon': Icons.store,
      'color': Colors.amber,
    },
    {
      'id': 'trainer',
      'name': '트레이너 리오',
      'description': '전투 훈련을 도와줍니다',
      'icon': Icons.fitness_center,
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NPC와 대화')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: npcs.length,
        itemBuilder: (context, index) {
          final npc = npcs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (npc['color'] as Color).withOpacity(0.1),
                child: Icon(npc['icon'] as IconData, color: npc['color'] as Color),
              ),
              title: Text(npc['name'] as String),
              subtitle: Text(npc['description'] as String),
              trailing: const Icon(Icons.chat_bubble),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIChatbotScreen(
                      npcId: npc['id'] as String,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
