import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math.dart';

/// 메타버스 월드 타입
enum WorldType {
  public,           // 공개
  private,          // 비공개
  social,           // 소셜
  gaming,           // 게이밍
  commercial,       // 상업
  educational,      // 교육
  entertainment,    // 엔터테인먼트
}

/// 아바타 커스터마이징
class AvatarAppearance {
  final String gender; // male, female, other
  final String skinColor;
  final String hairColor;
  final String hairStyle;
  final String faceShape;
  final String outfit;
  final List<String> accessories;
  final double height; // 0.8 - 1.2
  final double bodyType; // 0.0 - 1.0

  const AvatarAppearance({
    required this.gender,
    required this.skinColor,
    required this.hairColor,
    required this.hairStyle,
    required this.faceShape,
    required this.outfit,
    required this.accessories,
    required this.height,
    required this.bodyType,
  });
}

/// 아바타
class Avatar {
  final String id;
  final String userId;
  final String username;
  final AvatarAppearance appearance;
  final Vector3 position;
  final Quaternion rotation;
  final String? currentWorldId;
  final String? currentRoomId;
  final bool isOnline;
  final DateTime lastSeen;

  const Avatar({
    required this.id,
    required this.userId,
    required this.username,
    required this.appearance,
    required this.position,
    required this.rotation,
    this.currentWorldId,
    this.currentRoomId,
    required this.isOnline,
    required this.lastSeen,
  });
}

/// 가상 월드
class VirtualWorld {
  final String id;
  final String name;
  final String description;
  final WorldType type;
  final String ownerId;
  final int maxUsers;
  final List<String> currentUserIds;
  final String thumbnailUrl;
  final List<VirtualRoom> rooms;
  final List<String> tags;
  final bool isVoiceEnabled;
  final bool isTextEnabled;
  final DateTime createdAt;

  const VirtualWorld({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.ownerId,
    required this.maxUsers,
    required this.currentUserIds,
    required this.thumbnailUrl,
    required this.rooms,
    required this.tags,
    required this.isVoiceEnabled,
    required this.isTextEnabled,
    required this.createdAt,
  });

  /// 현재 인원 수
  int get currentUsers => currentUserIds.length;

  /// 접속 가능 여부
  bool get canJoin => currentUsers < maxUsers;
}

/// 가상 공간
class VirtualRoom {
  final String id;
  final String name;
  final String description;
  final int capacity;
  final List<String> userIds;
  final String? backgroundMusic;
  final String? environmentUrl; // 3D environment
  final Map<String, dynamic> settings;

  const VirtualRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.capacity,
    required this.userIds,
    this.backgroundMusic,
    this.environmentUrl,
    required this.settings,
  });
}

/// 음성 채팅 참가자
class VoiceParticipant {
  final String userId;
  final String username;
  final double volume; // 0.0 - 1.0
  final bool isMuted;
  final bool isSpeaking;

  const VoiceParticipant({
    required this.userId,
    required this.username,
    required this.volume,
    required this.isMuted,
    required this.isSpeaking,
  });
}

/// 메타버스 이벤트
class MetaverseEvent {
  final String id;
  final String title;
  final String description;
  final String worldId;
  final String? roomId;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> attendeeIds;
  final String organizerId;
  final String thumbnailUrl;
  final bool isLive;

  const MetaverseEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.worldId,
    this.roomId,
    required this.startTime,
    required this.endTime,
    required this.attendeeIds,
    required this.organizerId,
    required this.thumbnailUrl,
    required this.isLive,
  });
}

/// NFT/디지털 자산
class DigitalAsset {
  final String id;
  final String name;
  final String description;
  final String type; // wearables, decorations, collectibles, etc.
  final String imageUrl;
  final String modelUrl;
  final String? blockchainTokenId;
  final String? contractAddress;
  final String ownerUserId;
  final int rarity; // 1-5
  final DateTime mintedAt;

  const DigitalAsset({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.imageUrl,
    required this.modelUrl,
    this.blockchainTokenId,
    this.contractAddress,
    required this.ownerUserId,
    required this.rarity,
    required this.mintedAt,
  });
}

/// 메타버스 관리자
class MetaverseManager {
  static final MetaverseManager _instance = MetaverseManager._();
  static MetaverseManager get instance => _instance;

  MetaverseManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, VirtualWorld> _worlds = {};
  final Map<String, Avatar> _avatars = {};
  final Map<String, DigitalAsset> _assets = {};
  final Map<String, MetaverseEvent> _events = {};

  final StreamController<VirtualWorld> _worldController =
      StreamController<VirtualWorld>.broadcast();
  final StreamController<Avatar> _avatarController =
      StreamController<Avatar>.broadcast();
  final StreamController<VoiceParticipant> _voiceController =
      StreamController<VoiceParticipant>.broadcast();
  final StreamController<MetaverseEvent> _eventController =
      StreamController<MetaverseEvent>.broadcast();

  Stream<VirtualWorld> get onWorldUpdate => _worldController.stream;
  Stream<Avatar> get onAvatarUpdate => _avatarController.stream;
  Stream<VoiceParticipant> get onVoiceUpdate => _voiceController.stream;
  Stream<MetaverseEvent> get onEventUpdate => _eventController.stream;

  Timer? _positionUpdateTimer;
  List<VoiceParticipant> _voiceParticipants = [];

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 월드 로드
    await _loadWorlds();

    // 아바타 로드
    await _loadAvatar();

    debugPrint('[Metaverse] Initialized');
  }

  Future<void> _loadWorlds() async {
    // 기본 공개 월드 생성
    _worlds['plaza'] = const VirtualWorld(
      id: 'plaza',
      name: '중앙 광장',
      description: '모두가 모이는 메타버스 중심지',
      type: WorldType.public,
      ownerId: 'system',
      maxUsers: 1000,
      currentUserIds: [],
      thumbnailUrl: 'assets/thumbnails/plaza.png',
      rooms: [
        VirtualRoom(
          id: 'room_main',
          name: '메인 홀',
          description: '중앙 광장의 메인 홀',
          capacity: 100,
          userIds: [],
          settings: {},
        ),
      ],
      tags: ['social', 'meeting'],
      isVoiceEnabled: true,
      isTextEnabled: true,
      createdAt: DateTime.now(),
    );

    _worlds['gaming_hall'] = const VirtualWorld(
      id: 'gaming_hall',
      name: '게이밍 홀',
      description: '다양한 게임을 즐길 수 있는 공간',
      type: WorldType.gaming,
      ownerId: 'system',
      maxUsers: 500,
      currentUserIds: [],
      thumbnailUrl: 'assets/thumbnails/gaming.png',
      rooms: [],
      tags: ['gaming', 'competition'],
      isVoiceEnabled: true,
      isTextEnabled: true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _loadAvatar() async {
    if (_currentUserId != null) {
      _avatars[_currentUserId!] = Avatar(
        id: 'avatar_$_currentUserId',
        userId: _currentUserId!,
        username: 'User $_currentUserId',
        appearance: const AvatarAppearance(
          gender: 'male',
          skinColor: '#FFE0BD',
          hairColor: '#4A3728',
          hairStyle: 'short',
          faceShape: 'oval',
          outfit: 'casual',
          accessories: [],
          height: 1.0,
          bodyType: 0.5,
        ),
        position: Vector3(0, 0, 0),
        rotation: Quaternion.identity(),
        currentWorldId: null,
        currentRoomId: null,
        isOnline: false,
        lastSeen: DateTime.now(),
      );
    }
  }

  /// 월드 생성
  Future<VirtualWorld> createWorld({
    required String name,
    required String description,
    required WorldType type,
    int maxUsers = 100,
    List<String>? tags,
    bool isVoiceEnabled = true,
    bool isTextEnabled = true,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final worldId = 'world_${DateTime.now().millisecondsSinceEpoch}';
    final world = VirtualWorld(
      id: worldId,
      name: name,
      description: description,
      type: type,
      ownerId: _currentUserId!,
      maxUsers: maxUsers,
      currentUserIds: [],
      thumbnailUrl: 'assets/thumbnails/$worldId.png',
      rooms: const [],
      tags: tags ?? [],
      isVoiceEnabled: isVoiceEnabled,
      isTextEnabled: isTextEnabled,
      createdAt: DateTime.now(),
    );

    _worlds[worldId] = world;
    _worldController.add(world);

    await _saveWorld(world);

    debugPrint('[Metaverse] World created: $worldId');

    return world;
  }

  /// 월드 참가
  Future<void> joinWorld(String worldId) async {
    if (_currentUserId == null) return;

    final world = _worlds[worldId];
    if (world == null) {
      throw Exception('World not found');
    }

    if (!world.canJoin) {
      throw Exception('World is full');
    }

    // 아바타 위치 업데이트
    final avatar = _avatars[_currentUserId];
    if (avatar != null) {
      final updated = Avatar(
        id: avatar.id,
        userId: avatar.userId,
        username: avatar.username,
        appearance: avatar.appearance,
        position: Vector3(0, 0, 0),
        rotation: avatar.rotation,
        currentWorldId: worldId,
        currentRoomId: world.rooms.isNotEmpty ? world.rooms.first.id : null,
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      _avatars[_currentUserId!] = updated;
      _avatarController.add(updated);

      // 위치 업데이트 시작
      _startPositionUpdates();
    }

    // 월드 유저 목록 업데이트
    final updatedUsers = [...world.currentUserIds, _currentUserId!];
    final updatedWorld = VirtualWorld(
      id: world.id,
      name: world.name,
      description: world.description,
      type: world.type,
      ownerId: world.ownerId,
      maxUsers: world.maxUsers,
      currentUserIds: updatedUsers,
      thumbnailUrl: world.thumbnailUrl,
      rooms: world.rooms,
      tags: world.tags,
      isVoiceEnabled: world.isVoiceEnabled,
      isTextEnabled: world.isTextEnabled,
      createdAt: world.createdAt,
    );

    _worlds[worldId] = updatedWorld;
    _worldController.add(updatedWorld);

    // 음성 채팅 참가
    if (updatedWorld.isVoiceEnabled) {
      await _joinVoiceChat(worldId);
    }

    debugPrint('[Metaverse] Joined world: $worldId');
  }

  /// 월드 퇴장
  Future<void> leaveWorld(String worldId) async {
    if (_currentUserId == null) return;

    final world = _worlds[worldId];
    if (world == null) return;

    // 아바타 상태 업데이트
    final avatar = _avatars[_currentUserId];
    if (avatar != null) {
      final updated = Avatar(
        id: avatar.id,
        userId: avatar.userId,
        username: avatar.username,
        appearance: avatar.appearance,
        position: avatar.position,
        rotation: avatar.rotation,
        currentWorldId: null,
        currentRoomId: null,
        isOnline: false,
        lastSeen: DateTime.now(),
      );

      _avatars[_currentUserId!] = updated;
      _avatarController.add(updated);
    }

    // 월드 유저 목록 업데이트
    final updatedUsers = world.currentUserIds.where((id) => id != _currentUserId).toList();
    final updatedWorld = VirtualWorld(
      id: world.id,
      name: world.name,
      description: world.description,
      type: world.type,
      ownerId: world.ownerId,
      maxUsers: world.maxUsers,
      currentUserIds: updatedUsers,
      thumbnailUrl: world.thumbnailUrl,
      rooms: world.rooms,
      tags: world.tags,
      isVoiceEnabled: world.isVoiceEnabled,
      isTextEnabled: world.isTextEnabled,
      createdAt: world.createdAt,
    );

    _worlds[worldId] = updatedWorld;
    _worldController.add(updatedWorld);

    // 위치 업데이트 중지
    _positionUpdateTimer?.cancel();

    // 음성 채팅 퇴장
    await _leaveVoiceChat();

    debugPrint('[Metaverse] Left world: $worldId');
  }

  /// 아바타 이동
  Future<void> moveAvatar({
    required Vector3 position,
    Quaternion? rotation,
  }) async {
    if (_currentUserId == null) return;

    final avatar = _avatars[_currentUserId];
    if (avatar == null || !avatar.isOnline) return;

    final updated = Avatar(
      id: avatar.id,
      userId: avatar.userId,
      username: avatar.username,
      appearance: avatar.appearance,
      position: position,
      rotation: rotation ?? avatar.rotation,
      currentWorldId: avatar.currentWorldId,
      currentRoomId: avatar.currentRoomId,
      isOnline: avatar.isOnline,
      lastSeen: DateTime.now(),
    );

    _avatars[_currentUserId!] = updated;
    _avatarController.add(updated);

    debugPrint('[Metaverse] Avatar moved: $position');
  }

  /// 아바타 커스터마이징
  Future<void> customizeAvatar(AvatarAppearance appearance) async {
    if (_currentUserId == null) return;

    final avatar = _avatars[_currentUserId];
    if (avatar == null) return;

    final updated = Avatar(
      id: avatar.id,
      userId: avatar.userId,
      username: avatar.username,
      appearance: appearance,
      position: avatar.position,
      rotation: avatar.rotation,
      currentWorldId: avatar.currentWorldId,
      currentRoomId: avatar.currentRoomId,
      isOnline: avatar.isOnline,
      lastSeen: DateTime.now(),
    );

    _avatars[_currentUserId!] = updated;
    _avatarController.add(updated);

    await _saveAvatar(updated);

    debugPrint('[Metaverse] Avatar customized');
  }

  /// 위치 업데이트 시작
  void _startPositionUpdates() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _syncAvatarPosition();
    });
  }

  /// 아바타 위치 동기화
  Future<void> _syncAvatarPosition() async {
    if (_currentUserId == null) return;

    final avatar = _avatars[_currentUserId];
    if (avatar == null || !avatar.isOnline) return;

    // 네트워크로 위치 전송 (시뮬레이션)
    // 실제 환경에서는 WebSocket 사용

    _avatarController.add(avatar);
  }

  /// 음성 채팅 참가
  Future<void> _joinVoiceChat(String worldId) async {
    // 월드에 있는 다른 유저들에게 음성 참가 알림
    final world = _worlds[worldId];
    if (world == null) return;

    _voiceParticipants = world.currentUserIds.map((userId) {
      return VoiceParticipant(
        userId: userId,
        username: 'User $userId',
        volume: 1.0,
        isMuted: false,
        isSpeaking: false,
      );
    }).toList();

    debugPrint('[Metaverse] Joined voice chat: $worldId');
  }

  /// 음성 채팅 퇴장
  Future<void> _leaveVoiceChat() async {
    _voiceParticipants = [];

    debugPrint('[Metaverse] Left voice chat');
  }

  /// 음소거 토글
  Future<void> toggleMute() async {
    if (_currentUserId == null) return;

    final index = _voiceParticipants.indexWhere((p) => p.userId == _currentUserId);
    if (index == -1) return;

    final participant = _voiceParticipants[index];
    final updated = VoiceParticipant(
      userId: participant.userId,
      username: participant.username,
      volume: participant.volume,
      isMuted: !participant.isMuted,
      isSpeaking: participant.isSpeaking,
    );

    _voiceParticipants[index] = updated;
    _voiceController.add(updated);

    debugPrint('[Metaverse] Mute toggled: ${updated.isMuted}');
  }

  /// 이벤트 생성
  Future<MetaverseEvent> createEvent({
    required String title,
    required String description,
    required String worldId,
    required DateTime startTime,
    required DateTime endTime,
    String? roomId,
    String? thumbnailUrl,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';
    final event = MetaverseEvent(
      id: eventId,
      title: title,
      description: description,
      worldId: worldId,
      roomId: roomId,
      startTime: startTime,
      endTime: endTime,
      attendeeIds: [],
      organizerId: _currentUserId!,
      thumbnailUrl: thumbnailUrl ?? 'assets/thumbnails/$eventId.png',
      isLive: false,
    );

    _events[eventId] = event;
    _eventController.add(event);

    await _saveEvent(event);

    debugPrint('[Metaverse] Event created: $eventId');

    return event;
  }

  /// 이벤트 참가
  Future<void> joinEvent(String eventId) async {
    if (_currentUserId == null) return;

    final event = _events[eventId];
    if (event == null) return;

    final updated = MetaverseEvent(
      id: event.id,
      title: event.title,
      description: event.description,
      worldId: event.worldId,
      roomId: event.roomId,
      startTime: event.startTime,
      endTime: event.endTime,
      attendeeIds: [...event.attendeeIds, _currentUserId!],
      organizerId: event.organizerId,
      thumbnailUrl: event.thumbnailUrl,
      isLive: event.isLive,
    );

    _events[eventId] = updated;
    _eventController.add(updated);

    // 이벤트가 있는 월드로 자동 이동
    await joinWorld(event.worldId);

    debugPrint('[Metaverse] Joined event: $eventId');
  }

  /// 디지털 자산 생성 (NFT 발행)
  Future<DigitalAsset> mintAsset({
    required String name,
    required String description,
    required String type,
    required String imageUrl,
    required String modelUrl,
    int rarity = 1,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final assetId = 'asset_${DateTime.now().millisecondsSinceEpoch}';
    final asset = DigitalAsset(
      id: assetId,
      name: name,
      description: description,
      type: type,
      imageUrl: imageUrl,
      modelUrl: modelUrl,
      blockchainTokenId: 'token_$assetId',
      contractAddress: '0x0000000000000000000000000000000000000000',
      ownerUserId: _currentUserId!,
      rarity: rarity.clamp(1, 5),
      mintedAt: DateTime.now(),
    );

    _assets[assetId] = asset;

    await _saveAsset(asset);

    debugPrint('[Metaverse] Asset minted: $assetId');

    return asset;
  }

  /// 디지털 자산 장착
  Future<void> equipAsset(String assetId) async {
    if (_currentUserId == null) return;

    final asset = _assets[assetId];
    if (asset == null || asset.ownerUserId != _currentUserId) {
      throw Exception('Asset not found or not owned');
    }

    // 아바타에 장착 (실제로는 아바타 업데이트)
    debugPrint('[Metaverse] Asset equipped: $assetId');
  }

  /// 월드 목록 조회
  List<VirtualWorld> getWorlds({WorldType? type}) {
    var worlds = _worlds.values.toList();

    if (type != null) {
      worlds = worlds.where((w) => w.type == type).toList();
    }

    return worlds..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// 아바타 조회
  Avatar? getAvatar(String userId) {
    return _avatars[userId];
  }

  /// 현재 아바타
  Avatar? get currentAvatar => _currentUserId != null ? _avatars[_currentUserId!] : null;

  /// 이벤트 목록 조회
  List<MetaverseEvent> getEvents({bool? isLive}) {
    var events = _events.values.toList();

    if (isLive != null) {
      events = events.where((e) => e.isLive == isLive).toList();
    }

    return events..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// 디지털 자산 목록 조회
  List<DigitalAsset> getAssets({String? ownerUserId}) {
    var assets = _assets.values.toList();

    if (ownerUserId != null) {
      assets = assets.where((a) => a.ownerUserId == ownerUserId).toList();
    }

    return assets..sort((a, b) => b.mintedAt.compareTo(a.mintedAt));
  }

  /// 월드 저장
  Future<void> _saveWorld(VirtualWorld world) async {
    await _prefs?.setString(
      'metaverse_world_${world.id}',
      jsonEncode({
        'id': world.id,
        'name': world.name,
        'description': world.description,
        'type': world.type.name,
        'ownerId': world.ownerId,
      }),
    );
  }

  /// 아바타 저장
  Future<void> _saveAvatar(Avatar avatar) async {
    await _prefs?.setString(
      'metaverse_avatar_${avatar.userId}',
      jsonEncode({
        'id': avatar.id,
        'userId': avatar.userId,
        'username': avatar.username,
        'appearance': {
          'gender': avatar.appearance.gender,
          'skinColor': avatar.appearance.skinColor,
          'hairColor': avatar.appearance.hairColor,
          'hairStyle': avatar.appearance.hairStyle,
          'outfit': avatar.appearance.outfit,
        },
      }),
    );
  }

  /// 이벤트 저장
  Future<void> _saveEvent(MetaverseEvent event) async {
    await _prefs?.setString(
      'metaverse_event_${event.id}',
      jsonEncode({
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'worldId': event.worldId,
        'startTime': event.startTime.toIso8601String(),
        'endTime': event.endTime.toIso8601String(),
      }),
    );
  }

  /// 자산 저장
  Future<void> _saveAsset(DigitalAsset asset) async {
    await _prefs?.setString(
      'metaverse_asset_${asset.id}',
      jsonEncode({
        'id': asset.id,
        'name': asset.name,
        'description': asset.description,
        'type': asset.type,
        'ownerUserId': asset.ownerUserId,
        'rarity': asset.rarity,
      }),
    );
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    final totalUsers = _worlds.values
        .fold<int>(0, (sum, w) => sum + w.currentUsers);

    final typeDistribution = <WorldType, int>{};
    for (final type in WorldType.values) {
      typeDistribution[type] =
          _worlds.values.where((w) => w.type == type).length;
    }

    return {
      'totalWorlds': _worlds.length,
      'totalUsers': totalUsers,
      'totalAvatars': _avatars.length,
      'totalAssets': _assets.length,
      'totalEvents': _events.length,
      'typeDistribution': typeDistribution.map((k, v) => MapEntry(k.name, v)),
    };
  }

  void dispose() {
    _positionUpdateTimer?.cancel();
    _worldController.close();
    _avatarController.close();
    _voiceController.close();
    _eventController.close();
  }
}
