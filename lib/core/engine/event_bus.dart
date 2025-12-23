import 'dart:async';
import 'package:injectable/injectable.dart';

/// A simple Event Bus for decoupled communication.
@singleton
class EventBus {
  final _controller = StreamController<dynamic>.broadcast();

  Stream<dynamic> get stream => _controller.stream;

  void fire(dynamic event) {
    _controller.add(event);
  }

  Stream<T> on<T>() {
    if (T == dynamic) {
      return stream.cast<T>();
    }
    return stream.where((event) => event is T).cast<T>();
  }

  void dispose() {
    _controller.close();
  }
}
