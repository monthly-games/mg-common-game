class CardBase {
  final String id;
  final int cost;
  // Type, Rarity, etc. can be added here

  CardBase({
    required this.id,
    this.cost = 0,
  });
}
