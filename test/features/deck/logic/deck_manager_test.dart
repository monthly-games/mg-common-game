import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/features/deck/logic/card_base.dart';
import 'package:mg_common_game/features/deck/logic/deck_manager.dart';

void main() {
  group('DeckManager', () {
    test('Draw moves cards from DrawPile to Hand', () {
      final deck = [
        CardBase(id: 'c1', cost: 1),
        CardBase(id: 'c2', cost: 1),
        CardBase(id: 'c3', cost: 1),
      ];
      final manager = DeckManager(initialDeck: deck);

      expect(manager.drawPile.length, 3);
      expect(manager.hand.length, 0);

      manager.draw(2);

      expect(manager.drawPile.length, 1);
      expect(manager.hand.length, 2);
    });

    test('Reshfuffles discard pile when draw pile is empty', () {
      final c1 = CardBase(id: 'c1', cost: 1);
      final c2 = CardBase(id: 'c2', cost: 1);

      final manager = DeckManager(initialDeck: [c1]);

      manager.draw(1); // Hand: [c1], Draw: []
      manager.play(c1); // Hand: [], Discard: [c1]

      expect(manager.drawPile.isEmpty, true);
      expect(manager.discardPile.length, 1);

      // Draw should trigger reshuffle
      manager.draw(1);

      expect(manager.hand.length, 1);
      expect(manager.hand.first.id, 'c1');
      expect(manager.discardPile.isEmpty, true);
    });

    test('DiscardHand moves all hand to discard', () {
      final deck = [CardBase(id: 'c1'), CardBase(id: 'c2')];
      final manager = DeckManager(initialDeck: deck);
      manager.draw(2);

      expect(manager.hand.length, 2);

      manager.discardHand();

      expect(manager.hand.isEmpty, true);
      expect(manager.discardPile.length, 2);
    });
  });
}
