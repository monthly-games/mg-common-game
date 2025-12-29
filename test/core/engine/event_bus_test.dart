import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';

// Test event classes
class TestEvent {
  final String message;
  TestEvent(this.message);
}

class AnotherEvent {
  final int value;
  AnotherEvent(this.value);
}

class SubTestEvent extends TestEvent {
  SubTestEvent(super.message);
}

void main() {
  group('EventBus', () {
    late EventBus eventBus;

    setUp(() {
      eventBus = EventBus();
    });

    tearDown(() {
      eventBus.dispose();
    });

    group('stream', () {
      test('returns a broadcast stream', () {
        expect(eventBus.stream, isA<Stream<dynamic>>());
        expect(eventBus.stream.isBroadcast, isTrue);
      });

      test('allows multiple listeners', () async {
        final received1 = <dynamic>[];
        final received2 = <dynamic>[];

        eventBus.stream.listen(received1.add);
        eventBus.stream.listen(received2.add);

        eventBus.fire('event1');
        eventBus.fire('event2');

        await Future.delayed(Duration.zero);

        expect(received1, ['event1', 'event2']);
        expect(received2, ['event1', 'event2']);
      });
    });

    group('fire', () {
      test('emits event to stream', () async {
        final events = <dynamic>[];
        eventBus.stream.listen(events.add);

        eventBus.fire('test');

        await Future.delayed(Duration.zero);
        expect(events, ['test']);
      });

      test('emits typed event', () async {
        final events = <dynamic>[];
        eventBus.stream.listen(events.add);

        final testEvent = TestEvent('hello');
        eventBus.fire(testEvent);

        await Future.delayed(Duration.zero);
        expect(events.length, 1);
        expect(events.first, isA<TestEvent>());
        expect((events.first as TestEvent).message, 'hello');
      });

      test('emits multiple events in order', () async {
        final events = <dynamic>[];
        eventBus.stream.listen(events.add);

        eventBus.fire(1);
        eventBus.fire(2);
        eventBus.fire(3);

        await Future.delayed(Duration.zero);
        expect(events, [1, 2, 3]);
      });

      test('emits null event', () async {
        final events = <dynamic>[];
        eventBus.stream.listen(events.add);

        eventBus.fire(null);

        await Future.delayed(Duration.zero);
        expect(events, [null]);
      });

      test('emits various types of events', () async {
        final events = <dynamic>[];
        eventBus.stream.listen(events.add);

        eventBus.fire('string');
        eventBus.fire(42);
        eventBus.fire(3.14);
        eventBus.fire(true);
        eventBus.fire([1, 2, 3]);
        eventBus.fire({'key': 'value'});

        await Future.delayed(Duration.zero);
        expect(events.length, 6);
        expect(events[0], 'string');
        expect(events[1], 42);
        expect(events[2], 3.14);
        expect(events[3], true);
        expect(events[4], [1, 2, 3]);
        expect(events[5], {'key': 'value'});
      });
    });

    group('on<T>', () {
      test('filters events by type', () async {
        final testEvents = <TestEvent>[];
        eventBus.on<TestEvent>().listen(testEvents.add);

        eventBus.fire(TestEvent('first'));
        eventBus.fire(AnotherEvent(1));
        eventBus.fire(TestEvent('second'));
        eventBus.fire('string event');

        await Future.delayed(Duration.zero);
        expect(testEvents.length, 2);
        expect(testEvents[0].message, 'first');
        expect(testEvents[1].message, 'second');
      });

      test('returns empty stream when no matching events', () async {
        final testEvents = <TestEvent>[];
        eventBus.on<TestEvent>().listen(testEvents.add);

        eventBus.fire(AnotherEvent(1));
        eventBus.fire('string');
        eventBus.fire(123);

        await Future.delayed(Duration.zero);
        expect(testEvents, isEmpty);
      });

      test('on<dynamic> returns all events', () async {
        final events = <dynamic>[];
        eventBus.on<dynamic>().listen(events.add);

        eventBus.fire(TestEvent('test'));
        eventBus.fire(AnotherEvent(42));
        eventBus.fire('string');

        await Future.delayed(Duration.zero);
        expect(events.length, 3);
      });

      test('filters by specific primitive type', () async {
        final stringEvents = <String>[];
        final intEvents = <int>[];

        eventBus.on<String>().listen(stringEvents.add);
        eventBus.on<int>().listen(intEvents.add);

        eventBus.fire('hello');
        eventBus.fire(42);
        eventBus.fire('world');
        eventBus.fire(100);
        eventBus.fire(3.14);

        await Future.delayed(Duration.zero);
        expect(stringEvents, ['hello', 'world']);
        expect(intEvents, [42, 100]);
      });

      test('includes subclass events when filtering by parent type', () async {
        final testEvents = <TestEvent>[];
        eventBus.on<TestEvent>().listen(testEvents.add);

        eventBus.fire(TestEvent('parent'));
        eventBus.fire(SubTestEvent('child'));

        await Future.delayed(Duration.zero);
        expect(testEvents.length, 2);
        expect(testEvents[0].message, 'parent');
        expect(testEvents[1].message, 'child');
      });

      test('multiple type subscriptions work independently', () async {
        final testEvents = <TestEvent>[];
        final anotherEvents = <AnotherEvent>[];

        eventBus.on<TestEvent>().listen(testEvents.add);
        eventBus.on<AnotherEvent>().listen(anotherEvents.add);

        eventBus.fire(TestEvent('test1'));
        eventBus.fire(AnotherEvent(1));
        eventBus.fire(TestEvent('test2'));
        eventBus.fire(AnotherEvent(2));

        await Future.delayed(Duration.zero);
        expect(testEvents.length, 2);
        expect(anotherEvents.length, 2);
      });
    });

    group('subscription cancellation', () {
      test('can cancel subscription', () async {
        final events = <dynamic>[];
        final subscription = eventBus.stream.listen(events.add);

        eventBus.fire('before');
        await Future.delayed(Duration.zero);

        await subscription.cancel();

        eventBus.fire('after');
        await Future.delayed(Duration.zero);

        expect(events, ['before']);
      });

      test('can cancel typed subscription', () async {
        final events = <TestEvent>[];
        final subscription = eventBus.on<TestEvent>().listen(events.add);

        eventBus.fire(TestEvent('before'));
        await Future.delayed(Duration.zero);

        await subscription.cancel();

        eventBus.fire(TestEvent('after'));
        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events[0].message, 'before');
      });

      test('other subscriptions continue after one is cancelled', () async {
        final events1 = <dynamic>[];
        final events2 = <dynamic>[];

        final sub1 = eventBus.stream.listen(events1.add);
        eventBus.stream.listen(events2.add);

        eventBus.fire('first');
        await Future.delayed(Duration.zero);

        await sub1.cancel();

        eventBus.fire('second');
        await Future.delayed(Duration.zero);

        expect(events1, ['first']);
        expect(events2, ['first', 'second']);
      });
    });

    group('dispose', () {
      test('closes the stream controller', () async {
        final events = <dynamic>[];
        bool isDone = false;

        eventBus.stream.listen(
          events.add,
          onDone: () => isDone = true,
        );

        eventBus.fire('before dispose');
        await Future.delayed(Duration.zero);

        eventBus.dispose();
        await Future.delayed(Duration.zero);

        expect(isDone, isTrue);
        expect(events, ['before dispose']);
      });

      test('calling fire after dispose throws error', () async {
        eventBus.dispose();
        await Future.delayed(Duration.zero);

        expect(() => eventBus.fire('after dispose'), throwsStateError);
      });

      test('calling dispose multiple times is safe', () async {
        eventBus.dispose();
        await Future.delayed(Duration.zero);

        // Second dispose should not throw
        expect(() => eventBus.dispose(), returnsNormally);
      });
    });

    group('edge cases', () {
      test('no listeners - fire does not throw', () {
        expect(() => eventBus.fire('no listeners'), returnsNormally);
      });

      test('subscribing after fire does not receive past events', () async {
        eventBus.fire('past event');

        final events = <dynamic>[];
        eventBus.stream.listen(events.add);

        eventBus.fire('future event');
        await Future.delayed(Duration.zero);

        expect(events, ['future event']);
      });

      test('high volume of events', () async {
        final events = <int>[];
        eventBus.on<int>().listen(events.add);

        for (int i = 0; i < 1000; i++) {
          eventBus.fire(i);
        }

        await Future.delayed(Duration.zero);
        expect(events.length, 1000);
        expect(events.first, 0);
        expect(events.last, 999);
      });

      test('concurrent subscriptions and fires', () async {
        final events1 = <int>[];
        final events2 = <int>[];
        final events3 = <int>[];

        eventBus.on<int>().listen(events1.add);

        eventBus.fire(1);

        eventBus.on<int>().listen(events2.add);

        eventBus.fire(2);

        eventBus.on<int>().listen(events3.add);

        eventBus.fire(3);

        await Future.delayed(Duration.zero);

        expect(events1, [1, 2, 3]);
        expect(events2, [2, 3]);
        expect(events3, [3]);
      });

      test('empty string event', () async {
        final events = <String>[];
        eventBus.on<String>().listen(events.add);

        eventBus.fire('');

        await Future.delayed(Duration.zero);
        expect(events, ['']);
      });

      test('zero value event', () async {
        final events = <int>[];
        eventBus.on<int>().listen(events.add);

        eventBus.fire(0);

        await Future.delayed(Duration.zero);
        expect(events, [0]);
      });

      test('negative value event', () async {
        final events = <int>[];
        eventBus.on<int>().listen(events.add);

        eventBus.fire(-1);
        eventBus.fire(-100);

        await Future.delayed(Duration.zero);
        expect(events, [-1, -100]);
      });
    });

    group('stream transformations', () {
      test('can use stream operators with on<T>', () async {
        final events = <TestEvent>[];

        eventBus
            .on<TestEvent>()
            .where((e) => e.message.startsWith('filter'))
            .listen(events.add);

        eventBus.fire(TestEvent('filter-yes'));
        eventBus.fire(TestEvent('no-filter'));
        eventBus.fire(TestEvent('filter-also'));

        await Future.delayed(Duration.zero);
        expect(events.length, 2);
        expect(events[0].message, 'filter-yes');
        expect(events[1].message, 'filter-also');
      });

      test('can map events', () async {
        final messages = <String>[];

        eventBus.on<TestEvent>().map((e) => e.message).listen(messages.add);

        eventBus.fire(TestEvent('hello'));
        eventBus.fire(TestEvent('world'));

        await Future.delayed(Duration.zero);
        expect(messages, ['hello', 'world']);
      });

      test('can take limited events', () async {
        final events = <int>[];

        eventBus.on<int>().take(3).listen(events.add);

        for (int i = 0; i < 10; i++) {
          eventBus.fire(i);
        }

        await Future.delayed(Duration.zero);
        expect(events, [0, 1, 2]);
      });
    });

    group('async event handling', () {
      test('listener can handle events asynchronously', () async {
        final events = <String>[];
        final completer = Completer<void>();

        eventBus.on<String>().listen((event) async {
          await Future.delayed(const Duration(milliseconds: 10));
          events.add(event);
          if (events.length == 2) {
            completer.complete();
          }
        });

        eventBus.fire('first');
        eventBus.fire('second');

        await completer.future;
        expect(events, ['first', 'second']);
      });

      test('awaiting first event with firstWhere', () async {
        Future.delayed(const Duration(milliseconds: 10), () {
          eventBus.fire(TestEvent('target'));
        });

        final event = await eventBus.on<TestEvent>().first;
        expect(event.message, 'target');
      });
    });

    group('error handling in listeners', () {
      test('error in one listener does not affect others', () async {
        final events1 = <String>[];
        final events2 = <String>[];
        final errors = <Object>[];

        // Use runZonedGuarded to catch and ignore the exception
        runZonedGuarded(() {
          eventBus.on<String>().listen(
            (event) {
              if (event == 'error') {
                throw Exception('Test error');
              }
              events1.add(event);
            },
            onError: (e) => errors.add(e),
          );
        }, (error, stack) {
          // Caught expected error - do nothing
        });

        eventBus.on<String>().listen(events2.add);

        eventBus.fire('first');
        eventBus.fire('error');
        eventBus.fire('second');

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events1, ['first', 'second']);
        expect(events2, ['first', 'error', 'second']);
      });
    });
  });
}
