
class Recipe {
  final String id;
  final Map<String, int> inputs;
  final Map<String, int> outputs;
  final int durationSeconds;

  Recipe({
    required this.id,
    required this.inputs,
    required this.outputs,
    required this.durationSeconds,
  });
}
