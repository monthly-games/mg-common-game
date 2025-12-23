import 'package:flame/components.dart';
import 'package:mg_common_game/core/ui/spine_actor_component.dart';

class BattleEntity extends PositionComponent {
  final String id;
  final bool isPlayer;
  double hp;
  final double maxHp;

  late final SpineActorComponent _visual;

  BattleEntity({
    required this.id,
    required String assetName,
    required this.isPlayer,
    this.hp = 100,
    this.maxHp = 100,
    super.position,
  }) {
    // Flip enemy to face left
    _visual = SpineActorComponent(
      assetName: assetName,
      scaleFactor: 0.5,
    );
    if (!isPlayer) {
      _visual.scale.x = -0.5; // simple flip
    }
  }

  @override
  Future<void> onLoad() async {
    await add(_visual);
  }

  void playAttack() {
    print('$id attacks!');
    // If we had a specific animation:
    // _visual.playAnimation('attack');
  }

  void takeDamage(double amount) {
    hp -= amount;
    print('$id took $amount damage. HP: $hp');
    // _visual.playAnimation('hit');
    if (hp <= 0) {
      die();
    }
  }

  void die() {
    print('$id died!');
    // _visual.playAnimation('die');
    removeFromParent();
  }
}
