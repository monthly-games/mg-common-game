import 'package:flutter/material.dart';

/// Card rarity
enum CardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

/// Card type/class
enum CardType {
  attack,     // Damage dealing
  skill,      // Special abilities
  power,      // Permanent buffs
  status,     // Apply status effects
  defense,    // Block/armor
  heal,       // Restore HP
  draw,       // Draw more cards
  utility,    // Other effects
}

/// Card target type
enum CardTarget {
  self,
  singleEnemy,
  allEnemies,
  singleAlly,
  allAllies,
  random,
  none,
}

/// Card state
enum CardState {
  inDeck,
  inHand,
  inPlay,
  inDiscard,
  exhausted,
  removed,
}

/// Base card definition
class CardDefinition {
  final String id;
  final String name;
  final String description;
  final CardType type;
  final CardRarity rarity;
  final CardTarget target;
  final int cost;           // Mana/energy cost
  final int baseDamage;
  final int baseBlock;
  final int baseHeal;
  final int cardDraw;
  final List<String> statusEffects;
  final String? upgradeId;
  final bool exhausts;
  final bool ethereal;      // Discards at end of turn
  final bool innate;        // Starts in hand
  final String? artworkPath;

  const CardDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.rarity = CardRarity.common,
    this.target = CardTarget.singleEnemy,
    this.cost = 1,
    this.baseDamage = 0,
    this.baseBlock = 0,
    this.baseHeal = 0,
    this.cardDraw = 0,
    this.statusEffects = const [],
    this.upgradeId,
    this.exhausts = false,
    this.ethereal = false,
    this.innate = false,
    this.artworkPath,
  });

  /// Get rarity color
  Color get rarityColor {
    switch (rarity) {
      case CardRarity.common:
        return const Color(0xFF9E9E9E);
      case CardRarity.uncommon:
        return const Color(0xFF4CAF50);
      case CardRarity.rare:
        return const Color(0xFF2196F3);
      case CardRarity.epic:
        return const Color(0xFF9C27B0);
      case CardRarity.legendary:
        return const Color(0xFFFF9800);
      case CardRarity.mythic:
        return const Color(0xFFF44336);
    }
  }

  /// Get type icon
  IconData get typeIcon {
    switch (type) {
      case CardType.attack:
        return Icons.local_fire_department;
      case CardType.skill:
        return Icons.auto_fix_high;
      case CardType.power:
        return Icons.bolt;
      case CardType.status:
        return Icons.warning;
      case CardType.defense:
        return Icons.shield;
      case CardType.heal:
        return Icons.favorite;
      case CardType.draw:
        return Icons.add_box;
      case CardType.utility:
        return Icons.build;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'rarity': rarity.index,
      'target': target.index,
      'cost': cost,
      'baseDamage': baseDamage,
      'baseBlock': baseBlock,
      'baseHeal': baseHeal,
      'cardDraw': cardDraw,
      'statusEffects': statusEffects,
      'upgradeId': upgradeId,
      'exhausts': exhausts,
      'ethereal': ethereal,
      'innate': innate,
    };
  }
}

/// A card instance in game
class CardInstance {
  final String instanceId;
  final CardDefinition definition;
  CardState state;
  bool isUpgraded;
  int temporaryCostModifier;
  int temporaryDamageModifier;
  int temporaryBlockModifier;

  CardInstance({
    required this.instanceId,
    required this.definition,
    this.state = CardState.inDeck,
    this.isUpgraded = false,
    this.temporaryCostModifier = 0,
    this.temporaryDamageModifier = 0,
    this.temporaryBlockModifier = 0,
  });

  String get id => definition.id;
  String get name => definition.name;
  CardType get type => definition.type;
  CardRarity get rarity => definition.rarity;
  CardTarget get target => definition.target;

  int get cost => (definition.cost + temporaryCostModifier).clamp(0, 99);
  int get damage => definition.baseDamage + temporaryDamageModifier;
  int get block => definition.baseBlock + temporaryBlockModifier;
  int get heal => definition.baseHeal;
  int get cardDraw => definition.cardDraw;

  String get description {
    var desc = definition.description;
    desc = desc.replaceAll('{damage}', damage.toString());
    desc = desc.replaceAll('{block}', block.toString());
    desc = desc.replaceAll('{heal}', heal.toString());
    desc = desc.replaceAll('{draw}', cardDraw.toString());
    return desc;
  }

  void resetModifiers() {
    temporaryCostModifier = 0;
    temporaryDamageModifier = 0;
    temporaryBlockModifier = 0;
  }

  CardInstance copyWith({
    CardState? state,
    bool? isUpgraded,
    int? temporaryCostModifier,
    int? temporaryDamageModifier,
    int? temporaryBlockModifier,
  }) {
    return CardInstance(
      instanceId: instanceId,
      definition: definition,
      state: state ?? this.state,
      isUpgraded: isUpgraded ?? this.isUpgraded,
      temporaryCostModifier:
          temporaryCostModifier ?? this.temporaryCostModifier,
      temporaryDamageModifier:
          temporaryDamageModifier ?? this.temporaryDamageModifier,
      temporaryBlockModifier:
          temporaryBlockModifier ?? this.temporaryBlockModifier,
    );
  }

  @override
  String toString() => 'CardInstance($name, $state)';
}

/// Player deck
class Deck {
  final String id;
  final String name;
  final List<CardInstance> cards;
  final int maxSize;

  Deck({
    required this.id,
    required this.name,
    List<CardInstance>? cards,
    this.maxSize = 40,
  }) : cards = cards ?? [];

  int get size => cards.length;
  bool get isFull => size >= maxSize;

  void addCard(CardInstance card) {
    if (!isFull) {
      cards.add(card);
    }
  }

  void removeCard(String instanceId) {
    cards.removeWhere((c) => c.instanceId == instanceId);
  }

  CardInstance? getCard(String instanceId) {
    try {
      return cards.firstWhere((c) => c.instanceId == instanceId);
    } catch (e) {
      return null;
    }
  }

  /// Get cards by type
  List<CardInstance> getCardsByType(CardType type) {
    return cards.where((c) => c.type == type).toList();
  }

  /// Get cards by rarity
  List<CardInstance> getCardsByRarity(CardRarity rarity) {
    return cards.where((c) => c.rarity == rarity).toList();
  }

  /// Shuffle the deck
  void shuffle() {
    cards.shuffle();
  }

  /// Reset all card states to inDeck
  void reset() {
    for (final card in cards) {
      card.state = CardState.inDeck;
      card.resetModifiers();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cards': cards.map((c) => c.definition.id).toList(),
      'maxSize': maxSize,
    };
  }
}

/// Card battle state
class CardBattleState {
  List<CardInstance> drawPile;
  List<CardInstance> hand;
  List<CardInstance> discardPile;
  List<CardInstance> exhaustPile;
  int currentEnergy;
  int maxEnergy;
  int currentBlock;
  int cardsPlayedThisTurn;

  CardBattleState({
    List<CardInstance>? drawPile,
    List<CardInstance>? hand,
    List<CardInstance>? discardPile,
    List<CardInstance>? exhaustPile,
    this.currentEnergy = 3,
    this.maxEnergy = 3,
    this.currentBlock = 0,
    this.cardsPlayedThisTurn = 0,
  })  : drawPile = drawPile ?? [],
        hand = hand ?? [],
        discardPile = discardPile ?? [],
        exhaustPile = exhaustPile ?? [];

  bool canPlayCard(CardInstance card) {
    return currentEnergy >= card.cost;
  }

  void playCard(CardInstance card) {
    if (!canPlayCard(card)) return;

    currentEnergy -= card.cost;
    hand.remove(card);
    cardsPlayedThisTurn++;

    if (card.definition.exhausts) {
      card.state = CardState.exhausted;
      exhaustPile.add(card);
    } else {
      card.state = CardState.inDiscard;
      discardPile.add(card);
    }
  }

  void drawCard() {
    if (drawPile.isEmpty) {
      shuffleDiscardIntoDraw();
    }

    if (drawPile.isNotEmpty) {
      final card = drawPile.removeLast();
      card.state = CardState.inHand;
      hand.add(card);
    }
  }

  void drawCards(int count) {
    for (int i = 0; i < count; i++) {
      drawCard();
    }
  }

  void shuffleDiscardIntoDraw() {
    for (final card in discardPile) {
      card.state = CardState.inDeck;
    }
    drawPile.addAll(discardPile);
    discardPile.clear();
    drawPile.shuffle();
  }

  void endTurn() {
    // Discard hand (except ethereal which are exhausted)
    for (final card in [...hand]) {
      if (card.definition.ethereal) {
        card.state = CardState.exhausted;
        exhaustPile.add(card);
      } else {
        card.state = CardState.inDiscard;
        discardPile.add(card);
      }
    }
    hand.clear();

    // Reset block
    currentBlock = 0;
    cardsPlayedThisTurn = 0;
  }

  void startTurn() {
    currentEnergy = maxEnergy;

    // Draw hand
    drawCards(5);

    // Draw innate cards first (if not already implemented)
  }

  void reset(Deck deck) {
    drawPile = List.from(deck.cards);
    hand.clear();
    discardPile.clear();
    exhaustPile.clear();

    for (final card in drawPile) {
      card.state = CardState.inDeck;
      card.resetModifiers();
    }

    drawPile.shuffle();
    currentEnergy = maxEnergy;
    currentBlock = 0;
    cardsPlayedThisTurn = 0;
  }
}

/// Common starter cards
class StarterCards {
  static CardDefinition strike = const CardDefinition(
    id: 'strike',
    name: 'Strike',
    description: 'Deal {damage} damage.',
    type: CardType.attack,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    cost: 1,
    baseDamage: 6,
  );

  static CardDefinition defend = const CardDefinition(
    id: 'defend',
    name: 'Defend',
    description: 'Gain {block} block.',
    type: CardType.defense,
    rarity: CardRarity.common,
    target: CardTarget.self,
    cost: 1,
    baseBlock: 5,
  );

  static CardDefinition bash = const CardDefinition(
    id: 'bash',
    name: 'Bash',
    description: 'Deal {damage} damage. Apply 2 Vulnerable.',
    type: CardType.attack,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    cost: 2,
    baseDamage: 8,
    statusEffects: ['vulnerable:2'],
  );

  static List<CardDefinition> get all => [strike, defend, bash];
}
