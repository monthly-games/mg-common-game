import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flame/cache.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:mg_common_game/core/engine/asset_manager.dart';

// Mocks
class MockImages extends Mock implements Images {}

class MockAudioCache extends Mock implements AudioCache {}

void main() {
  late AssetManager assetManager;
  late MockImages mockImages;
  late MockAudioCache mockAudioCache;

  setUp(() {
    mockImages = MockImages();
    mockAudioCache = MockAudioCache();

    // We can inject mocks if AssetManager allows,
    // or we might need to mock static singletons if the implementation uses them directly.
    // For testability, AssetManager should ideally accept these as dependencies.
    assetManager = AssetManager(
      images: mockImages,
      audioCache: mockAudioCache,
    );
  });

  group('AssetManager', () {
    test('loadAllImages triggers loading', () async {
      final assets = ['test.png', 'hero.png'];
      when(() => mockImages.loadAll(assets)).thenAnswer((_) async => []);

      await assetManager.loadAllImages(assets);

      verify(() => mockImages.loadAll(assets)).called(1);
    });

    // Mocking Static FlameAudio is harder unless wrapped.
    // Assuming AssetManager wraps functionality.
    test('loadAllAudio triggers loading', () async {
      final audios = ['bgm.mp3', 'sfx.wav'];
      when(() => mockAudioCache.loadAll(audios))
          .thenAnswer((_) async => []); // Returns List<Uri> in newer versions

      await assetManager.loadAllAudio(audios);

      verify(() => mockAudioCache.loadAll(audios)).called(1);
    });
  });
}
