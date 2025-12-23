import 'package:flame/cache.dart';
import 'package:flame_audio/flame_audio.dart';

class AssetManager {
  final Images _images;
  final AudioCache _audioCache;

  AssetManager({
    Images? images,
    AudioCache? audioCache,
  })  : _images = images ?? Images(),
        _audioCache = audioCache ?? FlameAudio.audioCache;

  Future<void> loadAllImages(List<String> fileNames) async {
    await _images.loadAll(fileNames);
  }

  Future<void> loadAllAudio(List<String> fileNames) async {
    await _audioCache.loadAll(fileNames);
  }
}
