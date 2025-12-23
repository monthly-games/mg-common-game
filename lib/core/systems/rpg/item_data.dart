class ItemData {
  final String id;
  final String name;
  final String description;
  final int maxStack;
  final Map<String, dynamic> customData;

  ItemData({
    required this.id,
    required this.name,
    this.description = '',
    this.maxStack = 99,
    this.customData = const {},
  });
}
