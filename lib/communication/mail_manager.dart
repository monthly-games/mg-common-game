import 'dart:async';
import 'package:flutter/material.dart';

enum MailType {
  system,
  reward,
  announcement,
  social,
  promotion,
  support,
  gift,
}

enum MailStatus {
  unread,
  read,
  collected,
  expired,
  deleted,
}

class MailAttachment {
  final String itemId;
  final String itemName;
  final int quantity;
  final String itemType;
  final Map<String, dynamic> metadata;

  const MailAttachment({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.itemType,
    required this.metadata,
  });
}

class GameMail {
  final String mailId;
  final String title;
  final String body;
  final MailType type;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? recipientId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final MailStatus status;
  final bool hasAttachments;
  final List<MailAttachment> attachments;
  final bool attachmentsCollected;
  final DateTime? readAt;
  final DateTime? collectedAt;
  final bool isGlobal;
  final Map<String, dynamic>? data;

  const GameMail({
    required this.mailId,
    required this.title,
    required this.body,
    required this.type,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.recipientId,
    required this.createdAt,
    this.expiresAt,
    required this.status,
    required this.hasAttachments,
    required this.attachments,
    required this.attachmentsCollected,
    this.readAt,
    this.collectedAt,
    required this.isGlobal,
    this.data,
  });

  bool get isUnread => status == MailStatus.unread;
  bool get isRead => status == MailStatus.read;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isCollectible => hasAttachments && !attachmentsCollected && !isExpired;
  bool get canDelete => !isCollectible;
  Duration get timeUntilExpiry {
    if (expiresAt == null) return Duration.zero;
    return expiresAt!.difference(DateTime.now());
  }
}

class MailTemplate {
  final String templateId;
  final String name;
  final String title;
  final String body;
  final MailType type;
  final bool hasAttachments;
  final List<MailAttachment> defaultAttachments;
  final Duration expiryDuration;
  final bool isGlobal;

  const MailTemplate({
    required this.templateId,
    required this.name,
    required this.title,
    required this.body,
    required this.type,
    required this.hasAttachments,
    required this.defaultAttachments,
    required this.expiryDuration,
    required this.isGlobal,
  });
}

class MassMail {
  final String mailId;
  final String title;
  final String body;
  final MailType type;
  final List<String> recipientIds;
  final List<MailAttachment> attachments;
  final DateTime scheduledAt;
  final DateTime? expiresAt;
  final int totalRecipients;
  final int sentCount;
  final bool isSent;

  const MassMail({
    required this.mailId,
    required this.title,
    required this.body,
    required this.type,
    required this.recipientIds,
    required this.attachments,
    required this.scheduledAt,
    this.expiresAt,
    required this.totalRecipients,
    required this.sentCount,
    required this.isSent,
  });

  double get progress => totalRecipients > 0 ? sentCount / totalRecipients : 0.0;
}

class MailManager {
  static final MailManager _instance = MailManager._();
  static MailManager get instance => _instance;

  MailManager._();

  final Map<String, List<GameMail>> _userMails = {};
  final Map<String, MailTemplate> _templates = {};
  final Map<String, MassMail> _massMails = {};
  final StreamController<MailEvent> _eventController = StreamController.broadcast();
  Timer? _cleanupTimer;
  int _maxMailSlots = 100;

  Stream<MailEvent> get onMailEvent => _eventController.stream;

  Future<void> initialize({int maxMailSlots = 100}) async {
    _maxMailSlots = maxMailSlots;
    await _loadDefaultTemplates();
    _startCleanupTimer();
  }

  Future<void> _loadDefaultTemplates() async {
    final templates = [
      MailTemplate(
        templateId: 'daily_reward',
        name: 'Daily Reward',
        title: 'Daily Login Reward',
        body: 'Thank you for playing! Here is your daily reward.',
        type: MailType.reward,
        hasAttachments: true,
        defaultAttachments: const [
          MailAttachment(
            itemId: 'coins',
            itemName: 'Coins',
            quantity: 100,
            itemType: 'currency',
            metadata: {},
          ),
        ],
        expiryDuration: const Duration(days: 7),
        isGlobal: false,
      ),
      MailTemplate(
        templateId: 'welcome_bonus',
        name: 'Welcome Bonus',
        title: 'Welcome to the Game!',
        body: 'Here is your welcome bonus package.',
        type: MailType.reward,
        hasAttachments: true,
        defaultAttachments: const [
          MailAttachment(
            itemId: 'starter_pack',
            itemName: 'Starter Pack',
            quantity: 1,
            itemType: 'bundle',
            metadata: {},
          ),
        ],
        expiryDuration: const Duration(days: 30),
        isGlobal: true,
      ),
      MailTemplate(
        templateId: 'event_announcement',
        name: 'Event Announcement',
        title: 'New Event Started!',
        body: 'A new event has begun. Join now for exclusive rewards!',
        type: MailType.announcement,
        hasAttachments: false,
        defaultAttachments: const [],
        expiryDuration: const Duration(days: 14),
        isGlobal: true,
      ),
    ];

    for (final template in templates) {
      _templates[template.templateId] = template;
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _cleanupExpiredMails(),
    );
  }

  Future<String> sendMail({
    required String recipientId,
    required String title,
    required String body,
    required MailType type,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    List<MailAttachment>? attachments,
    Duration? expiryDuration,
    bool isGlobal = false,
    Map<String, dynamic>? data,
  }) async {
    final mailId = 'mail_${DateTime.now().millisecondsSinceEpoch}';

    final mail = GameMail(
      mailId: mailId,
      title: title,
      body: body,
      type: type,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      recipientId: recipientId,
      createdAt: DateTime.now(),
      expiresAt: expiryDuration != null
          ? DateTime.now().add(expiryDuration)
          : null,
      status: MailStatus.unread,
      hasAttachments: attachments != null && attachments.isNotEmpty,
      attachments: attachments ?? [],
      attachmentsCollected: false,
      isGlobal: isGlobal,
      data: data,
    );

    _addMailToUser(recipientId, mail);

    _eventController.add(MailEvent(
      type: MailEventType.mailSent,
      mailId: mailId,
      recipientId: recipientId,
      timestamp: DateTime.now(),
    ));

    return mailId;
  }

  void _addMailToUser(String userId, GameMail mail) {
    _userMails.putIfAbsent(userId, () => []);

    final mails = _userMails[userId]!;
    if (mails.length >= _maxMailSlots) {
      mails.removeLast();
    }

    mails.insert(0, mail);
  }

  Future<String> sendMailFromTemplate({
    required String recipientId,
    required String templateId,
    Map<String, dynamic>? variables,
    List<MailAttachment>? additionalAttachments,
  }) async {
    final template = _templates[templateId];
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    String title = template.title;
    String body = template.body;

    if (variables != null) {
      for (final entry in variables.entries) {
        title = title.replaceAll('${entry.key}', entry.value.toString());
        body = body.replaceAll('${entry.key}', entry.value.toString());
      }
    }

    final attachments = [...template.defaultAttachments];
    if (additionalAttachments != null) {
      attachments.addAll(additionalAttachments);
    }

    return sendMail(
      recipientId: recipientId,
      title: title,
      body: body,
      type: template.type,
      senderId: 'system',
      senderName: 'System',
      attachments: attachments,
      expiryDuration: template.expiryDuration,
      isGlobal: template.isGlobal,
    );
  }

  Future<String> sendMassMail({
    required String title,
    required String body,
    required MailType type,
    required List<String> recipientIds,
    List<MailAttachment>? attachments,
    DateTime? scheduledAt,
    Duration? expiryDuration,
  }) async {
    final mailId = 'mass_${DateTime.now().millisecondsSinceEpoch}';

    final massMail = MassMail(
      mailId: mailId,
      title: title,
      body: body,
      type: type,
      recipientIds: recipientIds,
      attachments: attachments ?? [],
      scheduledAt: scheduledAt ?? DateTime.now(),
      expiresAt: expiryDuration != null
          ? DateTime.now().add(expiryDuration)
          : null,
      totalRecipients: recipientIds.length,
      sentCount: 0,
      isSent: false,
    );

    _massMails[mailId] = massMail;

    if (scheduledAt == null) {
      await _processMassMail(mailId);
    } else {
      _scheduleMassMail(mailId);
    }

    return mailId;
  }

  Future<void> _scheduleMassMail(String mailId) async {
    final massMail = _massMails[mailId];
    if (massMail == null) return;

    final delay = massMail.scheduledAt.difference(DateTime.now());
    if (delay.isNegative) {
      await _processMassMail(mailId);
    } else {
      Future.delayed(delay, () => _processMassMail(mailId));
    }
  }

  Future<void> _processMassMail(String mailId) async {
    final massMail = _massMails[mailId];
    if (massMail == null) return;

    for (final recipientId in massMail.recipientIds) {
      final mail = GameMail(
        mailId: 'mail_${DateTime.now().millisecondsSinceEpoch}_${recipientId}',
        title: massMail.title,
        body: massMail.body,
        type: massMail.type,
        senderId: 'system',
        senderName: 'System',
        recipientId: recipientId,
        createdAt: DateTime.now(),
        expiresAt: massMail.expiresAt,
        status: MailStatus.unread,
        hasAttachments: massMail.attachments.isNotEmpty,
        attachments: massMail.attachments,
        attachmentsCollected: false,
        isGlobal: true,
      );

      _addMailToUser(recipientId, mail);

      final updated = MassMail(
        mailId: massMail.mailId,
        title: massMail.title,
        body: massMail.body,
        type: massMail.type,
        recipientIds: massMail.recipientIds,
        attachments: massMail.attachments,
        scheduledAt: massMail.scheduledAt,
        expiresAt: massMail.expiresAt,
        totalRecipients: massMail.totalRecipients,
        sentCount: massMail.sentCount + 1,
        isSent: massMail.sentCount + 1 >= massMail.totalRecipients,
      );

      _massMails[mailId] = updated;
    }

    _eventController.add(MailEvent(
      type: MailEventType.massMailCompleted,
      mailId: mailId,
      timestamp: DateTime.now(),
    ));
  }

  List<GameMail> getMails(String userId) {
    return _userMails[userId] ?? [];
  }

  List<GameMail> getUnreadMails(String userId) {
    return getMails(userId).where((mail) => mail.isUnread && !mail.isExpired).toList();
  }

  List<GameMail> getCollectibleMails(String userId) {
    return getMails(userId).where((mail) => mail.isCollectible).toList();
  }

  GameMail? getMail(String userId, String mailId) {
    final mails = _userMails[userId];
    if (mails == null) return null;
    try {
      return mails.firstWhere((mail) => mail.mailId == mailId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> markAsRead({
    required String userId,
    required String mailId,
  }) async {
    final mails = _userMails[userId];
    if (mails == null) return false;

    final index = mails.indexWhere((m) => m.mailId == mailId);
    if (index < 0) return false;

    final mail = mails[index];
    if (mail.isRead) return true;

    final updated = GameMail(
      mailId: mail.mailId,
      title: mail.title,
      body: mail.body,
      type: mail.type,
      senderId: mail.senderId,
      senderName: mail.senderName,
      senderAvatar: mail.senderAvatar,
      recipientId: mail.recipientId,
      createdAt: mail.createdAt,
      expiresAt: mail.expiresAt,
      status: MailStatus.read,
      hasAttachments: mail.hasAttachments,
      attachments: mail.attachments,
      attachmentsCollected: mail.attachmentsCollected,
      readAt: DateTime.now(),
      collectedAt: mail.collectedAt,
      isGlobal: mail.isGlobal,
      data: mail.data,
    );

    mails[index] = updated;

    _eventController.add(MailEvent(
      type: MailEventType.mailRead,
      mailId: mailId,
      recipientId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> collectAttachments({
    required String userId,
    required String mailId,
  }) async {
    final mails = _userMails[userId];
    if (mails == null) return false;

    final index = mails.indexWhere((m) => m.mailId == mailId);
    if (index < 0) return false;

    final mail = mails[index];
    if (!mail.hasAttachments || mail.attachmentsCollected) return false;
    if (mail.isExpired) return false;

    final updated = GameMail(
      mailId: mail.mailId,
      title: mail.title,
      body: mail.body,
      type: mail.type,
      senderId: mail.senderId,
      senderName: mail.senderName,
      senderAvatar: mail.senderAvatar,
      recipientId: mail.recipientId,
      createdAt: mail.createdAt,
      expiresAt: mail.expiresAt,
      status: MailStatus.collected,
      hasAttachments: mail.hasAttachments,
      attachments: mail.attachments,
      attachmentsCollected: true,
      readAt: mail.readAt,
      collectedAt: DateTime.now(),
      isGlobal: mail.isGlobal,
      data: mail.data,
    );

    mails[index] = updated;

    _eventController.add(MailEvent(
      type: MailEventType.attachmentsCollected,
      mailId: mailId,
      recipientId: userId,
      timestamp: DateTime.now(),
      data: {'attachments': mail.attachments},
    ));

    return true;
  }

  Future<bool> deleteMail({
    required String userId,
    required String mailId,
  }) async {
    final mails = _userMails[userId];
    if (mails == null) return false;

    final mail = getMail(userId, mailId);
    if (mail == null) return false;
    if (mail.isCollectible) return false;

    mails.removeWhere((m) => m.mailId == mailId);

    _eventController.add(MailEvent(
      type: MailEventType.mailDeleted,
      mailId: mailId,
      recipientId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> deleteAllMails(String userId) async {
    final mails = _userMails[userId];
    if (mails == null) return false;

    final collectibleCount = mails.where((m) => m.isCollectible).length;
    final deletableCount = mails.length - collectibleCount;

    mails.removeWhere((m) => !m.isCollectible);

    _eventController.add(MailEvent(
      type: MailEventType.mailDeleted,
      recipientId: userId,
      timestamp: DateTime.now(),
      data: {'count': deletableCount},
    ));

    return true;
  }

  MailTemplate? getTemplate(String templateId) {
    return _templates[templateId];
  }

  List<MailTemplate> getAllTemplates() {
    return _templates.values.toList();
  }

  MassMail? getMassMail(String mailId) {
    return _massMails[mailId];
  }

  List<MassMail> getAllMassMails() {
    return _massMails.values.toList();
  }

  int getUnreadCount(String userId) {
    return getUnreadMails(userId).length;
  }

  int getCollectibleCount(String userId) {
    return getCollectibleMails(userId).length;
  }

  Map<String, dynamic> getMailStats(String userId) {
    final mails = getMails(userId);
    final unread = getUnreadMails(userId).length;
    final collectible = getCollectibleMails(userId).length;
    final expired = mails.where((m) => m.isExpired).length;

    return {
      'totalMails': mails.length,
      'unreadMails': unread,
      'collectibleMails': collectible,
      'expiredMails': expired,
      'maxSlots': _maxMailSlots,
      'usedSlots': mails.length,
      'availableSlots': _maxMailSlots - mails.length,
    };
  }

  void _cleanupExpiredMails() {
    for (final userId in _userMails.keys) {
      final mails = _userMails[userId];
      if (mails == null) continue;

      final expired = mails.where((m) => m.isExpired).toList();
      for (final mail in expired) {
        if (mail.canDelete) {
          mails.remove(mail);
        }
      }
    }
  }

  void setMaxMailSlots(int maxSlots) {
    _maxMailSlots = maxSlots;
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _eventController.close();
  }
}

class MailEvent {
  final MailEventType type;
  final String? mailId;
  final String? recipientId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const MailEvent({
    required this.type,
    this.mailId,
    this.recipientId,
    required this.timestamp,
    this.data,
  });
}

enum MailEventType {
  mailSent,
  mailRead,
  mailDeleted,
  attachmentsCollected,
  mailExpired,
  massMailSent,
  massMailCompleted,
  templateCreated,
}
