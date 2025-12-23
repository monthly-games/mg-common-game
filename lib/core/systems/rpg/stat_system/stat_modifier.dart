enum StatModType {
  flat, // Add directly to base
  percentAdd, // Sum up, then multiply (Base + Flat) * (1 + Sum%)
  percentMult, // Multiply at the end
}

class StatModifier {
  final double value;
  final StatModType type;
  final Object? source;

  StatModifier(this.value, this.type, [this.source]);
}
