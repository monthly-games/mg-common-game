import 'dart:async';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';

class ResourceLoader {
  static final ResourceLoader _instance = ResourceLoader._internal();
  factory ResourceLoader() => _instance;
  ResourceLoader._internal();

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  Stream<double> get onProgress => _progressController.stream;

  Future<void> loadAssets({
    List<String> images = const [],
    List<String> audio = const [],
  }) async {
    int total = images.length + audio.length;
    int current = 0;

    _progressController.add(0.0);

    // Load Images
    for (final image in images) {
      await Flame.images.load(image);
      current++;
      _progressController.add(current / total);
    }

    // Load Audio
    for (final track in audio) {
      await FlameAudio.audioCache.load(track);
      current++;
      _progressController.add(current / total);
    }

    // Ensure 1.0 is sent
    _progressController.add(1.0);
  }
}
