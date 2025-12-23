import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class VirtualJoystick extends StatefulWidget {
  final void Function(Offset) onInput;
  final double size;
  final double knobSize;
  final Color baseColor;
  final Color knobColor;

  const VirtualJoystick({
    super.key,
    required this.onInput,
    this.size = 160,
    this.knobSize = 60,
    this.baseColor = const Color(0x88000000), // Semi-transparent black
    this.knobColor = AppColors.primary,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knobPosition = Offset.zero;

  void _updatePosition(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = localPosition - center;
    final distance = delta.distance;
    final radius = (widget.size - widget.knobSize) / 2;

    Offset newPos = delta;
    if (distance > radius) {
      newPos = Offset.fromDirection(delta.direction, radius);
    }

    setState(() {
      _knobPosition = newPos;
    });

    // Normalize input (-1.0 to 1.0)
    final normalized = Offset(
      newPos.dx / radius,
      newPos.dy / radius,
    );
    widget.onInput(normalized);
  }

  void _reset() {
    setState(() {
      _knobPosition = Offset.zero;
    });
    widget.onInput(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.baseColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withOpacity(0.5), width: 2),
      ),
      child: GestureDetector(
        onPanStart: (details) => _updatePosition(details.localPosition),
        onPanUpdate: (details) => _updatePosition(details.localPosition),
        onPanEnd: (_) => _reset(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Knob
            Transform.translate(
              offset: _knobPosition,
              child: Container(
                width: widget.knobSize,
                height: widget.knobSize,
                decoration: BoxDecoration(
                  color: widget.knobColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
