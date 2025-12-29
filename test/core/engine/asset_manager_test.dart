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

    test('loadAllImages with empty list', () async {
      when(() => mockImages.loadAll([])).thenAnswer((_) async => []);

      await assetManager.loadAllImages([]);

      verify(() => mockImages.loadAll([])).called(1);
    });

    test('loadAllAudio with empty list', () async {
      when(() => mockAudioCache.loadAll([])).thenAnswer((_) async => []);

      await assetManager.loadAllAudio([]);

      verify(() => mockAudioCache.loadAll([])).called(1);
    });

    test('loadAllImages with single file', () async {
      final assets = ['single.png'];
      when(() => mockImages.loadAll(assets)).thenAnswer((_) async => []);

      await assetManager.loadAllImages(assets);

      verify(() => mockImages.loadAll(assets)).called(1);
    });

    test('loadAllAudio with single file', () async {
      final audios = ['single.mp3'];
      when(() => mockAudioCache.loadAll(audios)).thenAnswer((_) async => []);

      await assetManager.loadAllAudio(audios);

      verify(() => mockAudioCache.loadAll(audios)).called(1);
    });
  });

  group('AssetManager Constructor', () {
    test('default constructor creates instance', () {
      // 기본 생성자 - Images와 AudioCache를 내부적으로 생성
      // FlameAudio.audioCache는 static이므로 mock 없이 테스트
      expect(() => AssetManager(), returnsNormally);
    });

    test('custom images and audioCache injection', () {
      final customImages = MockImages();
      final customAudioCache = MockAudioCache();

      final manager = AssetManager(
        images: customImages,
        audioCache: customAudioCache,
      );

      expect(manager, isNotNull);
    });

    test('only images injection', () {
      final customImages = MockImages();

      final manager = AssetManager(images: customImages);

      expect(manager, isNotNull);
    });

    test('only audioCache injection', () {
      final customAudioCache = MockAudioCache();

      final manager = AssetManager(audioCache: customAudioCache);

      expect(manager, isNotNull);
    });
  });
}
