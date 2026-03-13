import 'package:flutter/material.dart';
import 'package:mg_common_game/communication/mail_manager.dart';

class MailWidget extends StatefulWidget {
  final String userId;

  const MailWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MailWidget> createState() => _MailWidgetState();
}

class _MailWidgetState extends State<MailWidget> {
  final MailManager _mailManager = MailManager.instance;

  List<GameMail> _mails = [];
  int _unreadCount = 0;
  int _collectibleCount = 0;
  bool _isLoading = true;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _loadMails();
  }

  Future<void> _loadMails() async {
    await _mailManager.initialize(maxMailSlots: 100);
    setState(() => _isLoading = true);
    _mails = _mailManager.getMails(widget.userId);
    _unreadCount = _mailManager.getUnreadCount(widget.userId);
    _collectibleCount = _mailManager.getCollectibleCount(widget.userId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mailbox'),
        actions: [
          Stack(
            children: [
              const Icon(Icons.mail),
              if (_collectibleCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_collectibleCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _deleteAllMails,
            tooltip: 'Delete All',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMails.isEmpty
                    ? const Center(child: Text('No mails'))
                    : ListView.builder(
                        itemCount: _filteredMails.length,
                        itemBuilder: (context, index) {
                          final mail = _filteredMails[index];
                          return _buildMailTile(mail);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _buildTab('all', 'All'),
            _buildTab('unread', 'Unread ($_unreadCount)'),
            _buildTab('collectible', 'Collectible ($_collectibleCount)'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String id, String label) {
    final isSelected = _selectedTab == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedTab = id);
        },
      ),
    );
  }

  List<GameMail> get _filteredMails {
    switch (_selectedTab) {
      case 'unread':
        return _mails.where((m) => m.isUnread && !m.isExpired).toList();
      case 'collectible':
        return _mails.where((m) => m.isCollectible).toList();
      default:
        return _mails;
    }
  }

  Widget _buildMailTile(GameMail mail) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _openMail(mail),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _getMailTypeColor(mail.type),
                width: 4,
              ),
            ),
          ),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  child: Icon(_getMailTypeIcon(mail.type)),
                ),
                if (mail.isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    mail.title,
                    style: TextStyle(
                      fontWeight: mail.isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (mail.isCollectible)
                  const Icon(Icons.card_giftcard, color: Colors.amber),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mail.senderName,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  _formatDate(mail.createdAt),
                  style: const TextStyle(fontSize: 11),
                ),
                if (mail.expiresAt != null)
                  Text(
                    'Expires: ${_formatDate(mail.expiresAt!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: mail.isExpired ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
            trailing: mail.isCollectible
                ? IconButton(
                    icon: const Icon(Icons.collect_package_rounded),
                    onPressed: () => _collectAttachments(mail),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteMail(mail),
                  ),
          ),
        ),
      ),
    );
  }

  Color _getMailTypeColor(MailType type) {
    switch (type) {
      case MailType.reward:
        return Colors.amber;
      case MailType.announcement:
        return Colors.blue;
      case MailType.social:
        return Colors.green;
      case MailType.promotion:
        return Colors.purple;
      case MailType.system:
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getMailTypeIcon(MailType type) {
    switch (type) {
      case MailType.reward:
        return Icons.card_giftcard;
      case MailType.announcement:
        return Icons.campaign;
      case MailType.social:
        return Icons.people;
      case MailType.promotion:
        return Icons.local_offer;
      case MailType.system:
        return Icons.settings;
      default:
        return Icons.mail;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _openMail(GameMail mail) async {
    if (!mail.isRead) {
      await _mailManager.markAsRead(
        userId: widget.userId,
        mailId: mail.mailId,
      );
      _loadMails();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getMailTypeIcon(mail.type), color: _getMailTypeColor(mail.type)),
            const SizedBox(width: 8),
            Expanded(child: Text(mail.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From: ${mail.senderName}'),
              const SizedBox(height: 8),
              Text(mail.body),
              if (mail.hasAttachments) ...[
                const SizedBox(height: 16),
                const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...mail.attachments.map((attachment) => ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: Text(attachment.itemName),
                  subtitle: Text('x${attachment.quantity}'),
                  trailing: Text(attachment.itemType),
                )),
              ],
            ],
          ),
        ),
        actions: [
          if (mail.isCollectible)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _collectAttachments(mail);
              },
              child: const Text('Collect All'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _collectAttachments(GameMail mail) async {
    final success = await _mailManager.collectAttachments(
      userId: widget.userId,
      mailId: mail.mailId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Collected ${mail.attachments.length} items!')),
      );
      _loadMails();
    }
  }

  Future<void> _deleteMail(GameMail mail) async {
    final success = await _mailManager.deleteMail(
      userId: widget.userId,
      mailId: mail.mailId,
    );

    if (success) {
      _loadMails();
    }
  }

  Future<void> _deleteAllMails() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Mails'),
        content: const Text('Are you sure you want to delete all mails?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _mailManager.deleteAllMails(widget.userId);
      _loadMails();
    }
  }
}
