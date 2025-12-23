import 'package:mg_common_game/features/deck/logic/card_base.dart';

class DeckManager {
  List<CardBase> _drawPile = [];
  List<CardBase> _hand = [];
  List<CardBase> _discardPile = [];

  final int maxHandSize;

  DeckManager({
    required List<CardBase> initialDeck,
    this.maxHandSize = 10,
  }) {
    _drawPile = List.from(initialDeck);
    shuffle(); // Usually start shuffled
  }

  List<CardBase> get drawPile => List.unmodifiable(_drawPile);
  List<CardBase> get hand => List.unmodifiable(_hand);
  List<CardBase> get discardPile => List.unmodifiable(_discardPile);

  void shuffle() {
    _drawPile.shuffle();
  }

  void draw(int count) {
    for (int i = 0; i < count; i++) {
      if (_hand.length >= maxHandSize) break;

      if (_drawPile.isEmpty) {
        if (_discardPile.isEmpty) break; // No cards left
        _reshuffleDiscard();
      }

      if (_drawPile.isNotEmpty) {
        final card = _drawPile.removeLast();
        _hand.add(card);
      }
    }
  }

  void play(CardBase card) {
    if (_hand.contains(card)) {
      _hand.remove(card);
      _discardPile.add(card);
    }
  }

  void discardHand() {
    _discardPile.addAll(_hand);
    _hand.clear();
  }

  void _reshuffleDiscard() {
    _drawPile.addAll(_discardPile);
    _discardPile.clear();
    shuffle();
  }

  // Debug/Cheat methods
  void addCardToDiscard(CardBase card) => _discardPile.add(card);
}
