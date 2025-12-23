import 'package:flame/components.dart';
import 'package:flame_spine/flame_spine.dart';
import 'package:flutter/foundation.dart';

/// A wrapper component for Spine animations in Flame.
/// Simplifies loading from assets and provides basic animation control.
class SpineActorComponent extends PositionComponent {
  final String assetName;
  final String animationName;
  final bool loop;
  final double scaleFactor;

  SpineComponent? _spineComponent;

  SpineActorComponent({
    required this.assetName,
    this.animationName = 'idle',
    this.loop = true,
    this.scaleFactor = 0.5,
    super.position,
    super.size,
    super.anchor,
  });

  @override
  Future<void> onLoad() async {
    try {
      // Assuming assets are in assets/spine/
      // format: assets/spine/{assetName}/{assetName}.atlas
      _spineComponent = await SpineComponent.fromAssets(
        atlasFile: 'spine/$assetName/$assetName.atlas',
        skeletonFile: 'spine/$assetName/$assetName.json',
        scale: Vector2.all(scaleFactor),
      );

      _spineComponent!.animationState.setAnimation(0, animationName, loop);

      // Center the spine component within this wrapper
      _spineComponent!.anchor = Anchor.center;

      add(_spineComponent!);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading spine asset $assetName: $e');
      }
    }
  }

  void playAnimation(String name, {bool loop = false}) {
    _spineComponent?.animationState.setAnimation(0, name, loop);
  }
}
