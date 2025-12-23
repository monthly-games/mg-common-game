import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';
import 'package:mg_common_game/core/engine/game_manager.dart';

import 'package:mocktail/mocktail.dart';
import 'package:mg_common_game/core/systems/save_system.dart';

class MockSaveSystem extends Mock implements SaveSystem {}

void main() {
  group('EventBus', () {
    test('fires and receives events', () async {
      final bus = EventBus();
      expectLater(bus.on<int>(), emits(42));
      bus.fire(42);
    });

    test('updates filtered types', () async {
      final bus = EventBus();
      final stream = bus.on<String>();

      expectLater(stream, emits('hello'));

      bus.fire(123); // Should be ignored
      bus.fire('hello');
    });
  });

  group('GameManager', () {
    late EventBus bus;
    late MockSaveSystem mockSaveSystem;
    late GameManager gm;

    setUp(() {
      bus = EventBus();
      mockSaveSystem = MockSaveSystem();
      // Stub load to return null by default
      when(() => mockSaveSystem.load(any())).thenAnswer((_) async => null);
      when(() => mockSaveSystem.save(any(), any())).thenAnswer((_) async {});

      gm = GameManager(bus, mockSaveSystem);
    });

    test('initial state is initializing', () {
      expect(gm.state, GameState.initializing);
    });

    test('initialize transitions to running', () async {
      await gm.initialize();
      expect(gm.state, GameState.running);
      verify(() => mockSaveSystem.load('common_game_state')).called(1);
    });

    test('pause works only when running', () async {
      await gm.initialize(); // to running
      gm.pause();
      expect(gm.state, GameState.paused);
      verify(() => mockSaveSystem.save(any(), any())).called(1);

      gm.resume(); // to running
      gm.stop(); // to stopped
      gm.pause(); // should fail (stay stopped)
      expect(gm.state, GameState.stopped);
    });

    test('emits state change events', () async {
      expectLater(
        bus.on<GameStateChangedEvent>(),
        emits(predicate<GameStateChangedEvent>(
            (e) => e.current == GameState.running)),
      );
      await gm.initialize();
    });
  });
}
