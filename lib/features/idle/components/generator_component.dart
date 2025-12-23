import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

class GeneratorComponent extends Component {
  final Timer _timer;
  final VoidCallback _onTick;

  GeneratorComponent({
    required double period,
    required VoidCallback onTick,
    bool autoStart = true,
  })  : _onTick = onTick,
        _timer = Timer(period, repeat: true, autoStart: autoStart);

  @override
  void update(double dt) {
    _timer.update(dt);
    if (_timer.finished) {
      _onTick();
      // Timer with repeat=true doesn't need manual reset, but we check finished just in case
      // actually Timer callback is handled if we passed it to constructor?
      // Flame Timer constructor `onTick` is nullable.
      // Let's use the update cycle check or the callback.
      // Re-implementing correctly:
    }
  }
}

// Better implementation using standard TimerComponent
class SimpleGenerator extends TimerComponent {
  SimpleGenerator({
    required double period,
    required VoidCallback onTick,
    bool autoStart = true,
  }) : super(
          period: period,
          repeat: true,
          autoStart: autoStart,
          onTick: onTick,
        );
}
