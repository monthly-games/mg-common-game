import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 카드 타입
enum CardType {
  minion,      // 미니언
  spell,       // 주문
  weapon,      // 무기
  hero,        // 영웅
  location,    // 장소
}

/// 카드 등급
enum CardRarity {
  common,      // 일반
  rare,        // 레어
  epic,        // 에픽
  legendary,   // 전설
}

/// 카드 진영
enum CardFaction {
  neutral,     // 중립
  alliance,    // 얼라이언스
  horde,       // 호드
  monster,     // 몬스터
}

/// 카드 상태
enum CardState {
  inDeck,      // 덱 안
  inHand,      // 手札
  inPlay,      // 필드
  inGraveyard, // 묘지
  inBurn,      // 번듭
  exiled,      // 추방
}

/// 카드
class Card {
  final String id;
  final String name;
  final String description;
  final CardType type;
  final CardRarity rarity;
  final CardFaction faction;
  final int cost;
  final int attack;
  final int health;
  final String? imageUrl;
  final List<CardAbility> abilities;
  final List<String> keywords;
  CardState state;
  int? currentAttack;
  int? currentHealth;
  bool? isSummoningSick;
  bool? isExhausted;

  Card({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.faction,
    required this.cost,
    this.attack = 0,
    this.health = 0,
    this.imageUrl,
    this.abilities = const [],
    this.keywords = const [],
    this.state = CardState.inDeck,
    this.currentAttack,
    this.currentHealth,
    this.isSummoningSick,
    this.isExhausted,
  });

  /// 전투 가능 여부
  bool get canAttack =>
      state == CardState.inPlay &&
      (isSummoningSick == false || keywords.contains('charge')) &&
      (isExhausted == false) &&
      (currentAttack ?? attack) > 0;

  /// 생존 여부
  bool get isAlive =>
      state == CardState.inPlay &&
      (currentHealth ?? health) > 0;

  Card copyWith({
    CardState? state,
    int? currentAttack,
    int? currentHealth,
    bool? isSummoningSick,
    bool? isExhausted,
  }) {
    return Card(
      id: id,
      name: name,
      description: description,
      type: type,
      rarity: rarity,
      faction: faction,
      cost: cost,
      attack: attack,
      health: health,
      imageUrl: imageUrl,
      abilities: abilities,
      keywords: keywords,
      state: state ?? this.state,
      currentAttack: currentAttack ?? this.currentAttack,
      currentHealth: currentHealth ?? this.currentHealth,
      isSummoningSick: isSummoningSick ?? this.isSummoningSick,
      isExhausted: isExhausted ?? this.isExhausted,
    );
  }
}

/// 카드 능력
class CardAbility {
  final String id;
  final String name;
  final String description;
  final AbilityType type;
  final AbilityTrigger trigger;
  final Map<String, dynamic> parameters;

  const CardAbility({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.trigger,
    this.parameters = const {},
  });
}

/// 능력 타입
enum AbilityType {
  buff,          // 버프
  debuff,        // 디버프
  damage,        // 데미지
  heal,          // 힐
  draw,          // 드로우
  summon,        // 소환
  destroy,       // 파괴
  silence,       // 침묵
  bounce,        // 반환
  transform,     // 변형
}

/// 능력 발동 타이밍
enum AbilityTrigger {
  onPlay,        // 플레이 시
  onDeath,       // 죽을 때
  onAttack,      // 공격 시
  onDamaged,     // 데미지 받을 때
  onTurnStart,   // 턴 시작 시
  onTurnEnd,     // 턴 종료 시
  passive,       // 패시브
}

/// 카드 덱
class CardDeck {
  final String id;
  final String name;
  final List<Card> cards;
  final CardFaction? faction;
  final String? heroId;
  final DateTime createdAt;

  const CardDeck({
    required this.id,
    required this.name,
    required this.cards,
    this.faction,
    this.heroId,
    required this.createdAt,
  });

  /// 덱 유효성 체크
  bool get isValid => cards.length >= 30 && cards.length <= 40;

  /// 카드 개수 확인
  int getCardCount(String cardId) {
    return cards.where((c) => c.id == cardId).length;
  }

  Card copy() {
    return CardDeck(
      id: id,
      name: name,
      cards: cards.map((c) => c.copyWith()).toList(),
      faction: faction,
      heroId: heroId,
      createdAt: createdAt,
    ) as Card;
  }
}

/// 플레이어
class CardPlayer {
  final String id;
  final String username;
  final Card? hero;
  final List<Card> hand;
  final List<Card> deck;
  final List<Card> field;
  final List<Card> graveyard;
  final List<Card> burn;
  int mana;
  final int maxMana;
  int health;

  const CardPlayer({
    required this.id,
    required this.username,
    this.hero,
    this.hand = const [],
    this.deck = const [],
    this.field = const [],
    this.graveyard = const [],
    this.burn = const [],
    this.mana = 0,
    this.maxMana = 0,
    this.health = 30,
  });

  /// 마나 충분 여부
  bool hasMana(int cost) => mana >= cost;

  /// 덱 드로우
  Card? drawCard() {
    if (deck.isEmpty) return null;
    final card = deck.removeLast();
    return card.copyWith(state: CardState.inHand);
  }
}

/// 게임 상태
class CardGameState {
  final String id;
  final CardPlayer player1;
  final CardPlayer player2;
  final int turn;
  final String currentPlayerId;
  final List<String> actionHistory;
  final DateTime startTime;
  final bool isGameOver;
  final String? winnerId;

  const CardGameState({
    required this.id,
    required this.player1,
    required this.player2,
    required this.turn,
    required this.currentPlayerId,
    this.actionHistory = const [],
    required this.startTime,
    this.isGameOver = false,
    this.winnerId,
  });

  /// 현재 플레이어
  CardPlayer get currentPlayer =>
      currentPlayerId == player1.id ? player1 : player2;

  /// 상대 플레이어
  CardPlayer get opponentPlayer =>
      currentPlayerId == player1.id ? player2 : player1;
}

/// 카드 게임 관리자
class CardGameManager {
  static final CardGameManager _instance = CardGameManager._();
  static CardGameManager get instance => _instance;

  CardGameManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, Card> _cards = {};
  final Map<String, CardDeck> _decks = {};
  CardGameState? _currentGame;

  final StreamController<CardGameState> _gameController =
      StreamController<CardGameState>.broadcast();
  final StreamController<Card> _cardController =
      StreamController<Card>.broadcast();

  Stream<CardGameState> get onGameUpdate => _gameController.stream;
  Stream<Card> get onCardAction => _cardController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 카드 로드
    _loadCards();

    // 덱 로드
    _loadDecks();

    debugPrint('[CardGame] Initialized');
  }

  void _loadCards() {
    // 기본 카드 로드
    _cards['minion_1'] = Card(
      id: 'minion_1',
      name: '용사',
      description: '충성스러운 용사',
      type: CardType.minion,
      rarity: CardRarity.common,
      faction: CardFaction.neutral,
      cost: 2,
      attack: 2,
      health: 3,
    );

    _cards['spell_1'] = Card(
      id: 'spell_1',
      name: '화염구',
      description: '대상에게 4 데미지',
      type: CardType.spell,
      rarity: CardRarity.common,
      faction: CardFaction.neutral,
      cost: 3,
      abilities: [
        const CardAbility(
          id: 'fireball_damage',
          name: '화염구',
          description: '4 데미지',
          type: AbilityType.damage,
          trigger: AbilityTrigger.onPlay,
          parameters: {'damage': 4},
        ),
      ],
    );

    _cards['legendary_1'] = Card(
      id: 'legendary_1',
      name: '전설의 영웅',
      description: '전설의 영웅입니다. 전장에 나올 때 다른 하수인 2개를 소환합니다.',
      type: CardType.minion,
      rarity: CardRarity.legendary,
      faction: CardFaction.neutral,
      cost: 8,
      attack: 7,
      health: 7,
      abilities: [
        const CardAbility(
          id: 'summon_2_minions',
          name: '영혼의 소환',
          description: '하수인 2개 소환',
          type: AbilityType.summon,
          trigger: AbilityTrigger.onPlay,
          parameters: {'count': 2},
        ),
      ],
      keywords: ['charge', 'divine_shield'],
    );
  }

  void _loadDecks() {
    final deckCards = [
      _cards['minion_1']!,
      _cards['minion_1']!,
      _cards['minion_1']!,
      _cards['spell_1']!,
      _cards['spell_1']!,
      _cards['legendary_1']!,
    ];

    _decks['default'] = CardDeck(
      id: 'default',
      name: '기본 덱',
      cards: deckCards,
      faction: CardFaction.neutral,
      createdAt: DateTime.now(),
    );
  }

  /// 덱 생성
  Future<CardDeck> createDeck({
    required String name,
    required List<String> cardIds,
    CardFaction? faction,
  }) async {
    final cards = cardIds.map((id) => _cards[id]!.copyWith()).toList();

    final deck = CardDeck(
      id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      cards: cards,
      faction: faction,
      createdAt: DateTime.now(),
    );

    _decks[deck.id] = deck;

    await _saveDeck(deck);

    debugPrint('[CardGame] Deck created: ${deck.name}');
    return deck;
  }

  Future<void> _saveDeck(CardDeck deck) async {
    await _prefs?.setString('deck_${deck.id}', jsonEncode({
      'id': deck.id,
      'name': deck.name,
      'cardIds': deck.cards.map((c) => c.id).toList(),
      'faction': deck.faction?.name,
    }));
  }

  /// 덱 수정
  Future<void> updateDeck({
    required String deckId,
    List<String>? cardIds,
    String? name,
  }) async {
    final deck = _decks[deckId];
    if (deck == null) return;

    final updated = CardDeck(
      id: deck.id,
      name: name ?? deck.name,
      cards: cardIds != null
          ? cardIds.map((id) => _cards[id]!.copyWith()).toList()
          : deck.cards,
      faction: deck.faction,
      heroId: deck.heroId,
      createdAt: deck.createdAt,
    );

    _decks[deckId] = updated;
    await _saveDeck(updated);

    debugPrint('[CardGame] Deck updated: $deckId');
  }

  /// 덱 삭제
  Future<void> deleteDeck(String deckId) async {
    _decks.remove(deckId);
    await _prefs?.remove('deck_$deckId');
    debugPrint('[CardGame] Deck deleted: $deckId');
  }

  /// 게임 시작
  Future<CardGameState> startGame({
    required String player1Id,
    required String player1DeckId,
    required String player2Id,
    required String player2DeckId,
  }) async {
    final deck1 = _decks[player1DeckId];
    final deck2 = _decks[player2DeckId];

    if (deck1 == null || deck2 == null) {
      throw Exception('Deck not found');
    }

    // 플레이어 생성
    final player1 = _createPlayer(player1Id, 'Player 1', deck1);
    final player2 = _createPlayer(player2Id, 'Player 2', deck2);

    // 시작 카드 드로우
    for (int i = 0; i < 3; i++) {
      player1.hand.add(player1.drawCard()!);
      player2.hand.add(player2.drawCard()!);
    }

    // 게임 상태 생성
    final game = CardGameState(
      id: 'game_${DateTime.now().millisecondsSinceEpoch}',
      player1: player1,
      player2: player2,
      turn: 1,
      currentPlayerId: player1Id,
      startTime: DateTime.now(),
    );

    _currentGame = game;
    _gameController.add(game);

    debugPrint('[CardGame] Game started: ${game.id}');
    return game;
  }

  CardPlayer _createPlayer(String id, String username, CardDeck deck) {
    final random = Random();

    // 덱 셔플
    final deckCards = List<Card>.from(deck.cards)..shuffle(random);

    // 카드 상태 설정
    for (var card in deckCards) {
      card.state = CardState.inDeck;
    }

    return CardPlayer(
      id: id,
      username: username,
      deck: deckCards,
      hand: [],
      field: [],
      graveyard: [],
      burn: [],
      mana: 1,
      maxMana: 1,
      health: 30,
    );
  }

  /// 카드 플레이
  Future<void> playCard({
    required String gameId,
    required String playerId,
    required String cardId,
    String? targetId,
  }) async {
    final game = _currentGame;
    if (game == null) return;

    final player = game.currentPlayerId == playerId
        ? game.player1
        : game.player2;

    final cardIndex = player.hand.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = player.hand[cardIndex];

    // 마나 체크
    if (!player.hasMana(card.cost)) {
      debugPrint('[CardGame] Not enough mana');
      return;
    }

    // 카드 플레이
    player.hand.removeAt(cardIndex);
    player.mana -= card.cost;

    if (card.type == CardType.minion) {
      // 미니언 플레이
      card.state = CardState.inPlay;
      card.isSummoningSick = true;
      player.field.add(card);

      // 능력 발동
      _triggerAbilities(game, player, card, AbilityTrigger.onPlay);
    } else if (card.type == CardType.spell) {
      // 주문 사용
      _executeSpell(game, player, card, targetId);
      player.graveyard.add(card);
    }

    _cardController.add(card);
    _gameController.add(game);

    debugPrint('[CardGame] Card played: $cardId');
  }

  /// 주문 실행
  void _executeSpell(
    CardGameState game,
    CardPlayer player,
    Card card,
    String? targetId,
  ) {
    for (final ability in card.abilities) {
      switch (ability.type) {
        case AbilityType.damage:
          final damage = ability.parameters['damage'] as int;
          if (targetId != null) {
            _dealDamage(game, targetId, damage);
          }
          break;
        case AbilityType.draw:
          final count = ability.parameters['count'] as int? ?? 1;
          for (int i = 0; i < count; i++) {
            final drawnCard = player.drawCard();
            if (drawnCard != null) {
              player.hand.add(drawnCard);
            }
          }
          break;
        default:
          break;
      }
    }
  }

  /// 데미지 처리
  void _dealDamage(CardGameState game, String targetId, int damage) {
    // 플레이어 찾기
    final targetPlayer = [game.player1, game.player2]
        .firstWhere((p) => p.id == targetId, orElse: () => game.player1);

    if (targetPlayer.id == targetId) {
      targetPlayer.health -= damage;
      if (targetPlayer.health <= 0) {
        _endGame(game, game.currentPlayerId);
      }
      return;
    }

    // 하수인 찾기
    final targetMinion = [...game.player1.field, ...game.player2.field]
        .firstWhere((m) => m.id == targetId, orElse: () => game.player1.field.first);

    if (targetMinion.id == targetId) {
      targetMinion.currentHealth = (targetMinion.currentHealth ?? targetMinion.health) - damage;
      if ((targetMinion.currentHealth ?? 0) <= 0) {
        _destroyMinion(game, targetMinion);
      }
    }
  }

  /// 하수인 파괴
  void _destroyMinion(CardGameState game, Card minion) {
    final player = game.player1.field.contains(minion)
        ? game.player1
        : game.player2;

    player.field.remove(minion);
    player.graveyard.add(minion);
    minion.state = CardState.inGraveyard;

    _triggerAbilities(game, player, minion, AbilityTrigger.onDeath);
  }

  /// 능력 발동
  void _triggerAbilities(
    CardGameState game,
    CardPlayer player,
    Card card,
    AbilityTrigger trigger,
  ) {
    for (final ability in card.abilities) {
      if (ability.trigger == trigger) {
        switch (ability.type) {
          case AbilityType.buff:
            final attack = ability.parameters['attack'] as int? ?? 0;
            final health = ability.parameters['health'] as int? ?? 0;
            // 버프 로직
            break;
          case AbilityType.summon:
            final count = ability.parameters['count'] as int? ?? 1;
            for (int i = 0; i < count; i++) {
              final summoned = _cards['minion_1']!.copyWith(
                state: CardState.inPlay,
              );
              player.field.add(summoned);
            }
            break;
          default:
            break;
        }
      }
    }
  }

  /// 공격
  Future<void> attack({
    required String gameId,
    required String playerId,
    required String attackerId,
    required String targetId,
  }) async {
    final game = _currentGame;
    if (game == null) return;

    final player = game.currentPlayerId == playerId
        ? game.player1
        : game.player2;

    final attacker = player.field.firstWhere((c) => c.id == attackerId);
    if (!attacker.canAttack) return;

    attacker.isExhausted = true;

    final opponent = game.currentPlayerId == playerId
        ? game.player2
        : game.player1;

    // 하수인 공격
    final targetMinion = opponent.field.firstWhere(
      (c) => c.id == targetId,
      orElse: () => opponent.field.first,
    );

    if (targetMinion.id == targetId) {
      final attackerDamage = attacker.currentAttack ?? attacker.attack;
      final targetDamage = targetMinion.currentAttack ?? targetMinion.attack;

      attacker.currentHealth = (attacker.currentHealth ?? attacker.health) - targetDamage;
      targetMinion.currentHealth = (targetMinion.currentHealth ?? targetMinion.health) - attackerDamage;

      if ((attacker.currentHealth ?? 0) <= 0) {
        _destroyMinion(game, attacker);
      }
      if ((targetMinion.currentHealth ?? 0) <= 0) {
        _destroyMinion(game, targetMinion);
      }
    } else {
      // 영웅 공격
      final damage = attacker.currentAttack ?? attacker.attack;
      opponent.health -= damage;

      if (opponent.health <= 0) {
        _endGame(game, playerId);
      }
    }

    _gameController.add(game);

    debugPrint('[CardGame] Attack: $attackerId -> $targetId');
  }

  /// 턴 종료
  Future<void> endTurn({
    required String gameId,
    required String playerId,
  }) async {
    final game = _currentGame;
    if (game == null) return;

    // 다음 플레이어
    final nextPlayerId = game.currentPlayerId == game.player1.id
        ? game.player2.id
        : game.player1.id;

    final updated = CardGameState(
      id: game.id,
      player1: game.player1,
      player2: game.player2,
      turn: game.currentPlayerId == game.player2.id ? game.turn + 1 : game.turn,
      currentPlayerId: nextPlayerId,
      actionHistory: [...game.actionHistory, 'end_turn:$playerId'],
      startTime: game.startTime,
      isGameOver: game.isGameOver,
      winnerId: game.winnerId,
    );

    _currentGame = updated;
    _gameController.add(updated);

    debugPrint('[CardGame] Turn ended: $playerId');
  }

  /// 게임 종료
  void _endGame(CardGameState game, String winnerId) {
    final updated = CardGameState(
      id: game.id,
      player1: game.player1,
      player2: game.player2,
      turn: game.turn,
      currentPlayerId: game.currentPlayerId,
      actionHistory: game.actionHistory,
      startTime: game.startTime,
      isGameOver: true,
      winnerId: winnerId,
    );

    _currentGame = updated;
    _gameController.add(updated);

    debugPrint('[CardGame] Game over: $winnerId wins!');
  }

  /// 카드 조회
  Card? getCard(String cardId) {
    return _cards[cardId];
  }

  /// 덱 조회
  CardDeck? getDeck(String deckId) {
    return _decks[deckId];
  }

  /// 모든 덱 조회
  List<CardDeck> getDecks() {
    return _decks.values.toList();
  }

  void dispose() {
    _gameController.close();
    _cardController.close();
  }
}
