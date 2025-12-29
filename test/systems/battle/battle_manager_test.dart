import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/battle/battle.dart';

void main() {
  group('BattleEntity', () {
    test('기본 생성', () {
      final entity = BattleEntity(
        id: 'hero_001',
        name: 'Hero',
        maxHp: 100,
        baseAttack: 20,
        baseDefense: 10,
      );

      expect(entity.id, 'hero_001');
      expect(entity.name, 'Hero');
      expect(entity.currentHp, 100);
      expect(entity.maxHp, 100);
      expect(entity.baseAttack, 20);
      expect(entity.baseDefense, 10);
      expect(entity.isAlive, true);
    });

    test('HP 퍼센트 계산', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
        currentHp: 50,
      );

      expect(entity.hpPercent, 0.5);
    });

    test('데미지 받기', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
      );

      entity.takeDamage(30);

      expect(entity.currentHp, 70);
    });

    test('데미지 - 방어력 적용', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
        baseDefense: 10,
      );

      // 방어력 10, 공격력 30이면 실제 데미지 20
      entity.takeDamage(30);

      expect(entity.currentHp, 80);
    });

    test('HP가 0 이하로 내려가지 않음', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
      );

      entity.takeDamage(200);

      expect(entity.currentHp, 0);
      expect(entity.isAlive, false);
    });

    test('회복', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
        currentHp: 50,
      );

      final healed = entity.heal(30);

      expect(healed, 30);
      expect(entity.currentHp, 80);
    });

    test('회복 - 최대 HP 초과 불가', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
        currentHp: 90,
      );

      final healed = entity.heal(50);

      expect(healed, 10); // 실제 회복량
      expect(entity.currentHp, 100);
    });

    test('블록 추가', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
      );

      entity.addBlock(20);
      expect(entity.block, 20);

      entity.addBlock(10);
      expect(entity.block, 30);
    });

    test('블록으로 데미지 흡수', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
      );

      entity.addBlock(20);
      entity.takeDamage(15);

      expect(entity.block, 5); // 20 - 15 = 5
      expect(entity.currentHp, 100); // 데미지 없음
    });

    test('블록 초과 데미지', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
      );

      entity.addBlock(10);
      entity.takeDamage(30);

      expect(entity.block, 0);
      expect(entity.currentHp, 80); // 100 - (30 - 10) = 80
    });

    test('블록 리셋', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
      );

      entity.addBlock(20);
      entity.resetBlock();

      expect(entity.block, 0);
    });

    test('공격력 수정', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
        baseAttack: 10,
      );

      entity.modifyAttack(5);
      expect(entity.baseAttack, 15);

      entity.modifyAttack(-3);
      expect(entity.baseAttack, 12);
    });

    test('리셋', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
      );

      entity.takeDamage(70);
      expect(entity.currentHp, 30);

      entity.reset();
      expect(entity.currentHp, 100);
    });
  });

  group('BattleEffect', () {
    test('기본 생성', () {
      final effect = BattleEffect(
        type: EffectType.poison,
        duration: 3,
        value: 5,
      );

      expect(effect.type, EffectType.poison);
      expect(effect.duration, 3);
      expect(effect.value, 5);
    });

    test('영구 효과', () {
      final permanent = BattleEffect(
        type: EffectType.strength,
        duration: 999,
        value: 10,
      );

      expect(permanent.isPermanent, true);
    });

    test('copyWith', () {
      final original = BattleEffect(
        type: EffectType.poison,
        duration: 3,
        value: 5,
      );

      final modified = original.copyWith(duration: 5);

      expect(modified.duration, 5);
      expect(modified.value, 5);
    });
  });

  group('Effectable Entity', () {
    late BattleEntity entity;

    setUp(() {
      entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
        baseAttack: 10,
      );
    });

    test('효과 적용', () {
      final poison = BattleEffect(
        type: EffectType.poison,
        duration: 3,
        value: 5,
      );

      entity.applyEffect(poison);

      expect(entity.hasEffect(EffectType.poison), true);
      expect(entity.getEffectValue(EffectType.poison), 5);
    });

    test('효과 스태킹', () {
      entity.applyEffect(BattleEffect(
        type: EffectType.strength,
        duration: 2,
        value: 3,
      ));

      entity.applyEffect(BattleEffect(
        type: EffectType.strength,
        duration: 2,
        value: 2,
      ));

      expect(entity.getEffectValue(EffectType.strength), 5); // 3 + 2
    });

    test('효과 제거', () {
      entity.applyEffect(BattleEffect(
        type: EffectType.weak,
        duration: 2,
        value: 0,
      ));

      expect(entity.hasEffect(EffectType.weak), true);

      entity.removeEffect(EffectType.weak);

      expect(entity.hasEffect(EffectType.weak), false);
    });

    test('효과 감소 (턴 종료)', () {
      entity.applyEffect(BattleEffect(
        type: EffectType.poison,
        duration: 2,
        value: 5,
      ));

      entity.decayEffects();
      expect(entity.effects.first.duration, 1);

      entity.decayEffects();
      expect(entity.hasEffect(EffectType.poison), false); // 만료
    });

    test('취약 효과 - 피해 증가', () {
      entity.applyEffect(BattleEffect(
        type: EffectType.vulnerable,
        duration: 2,
        value: 0,
      ));

      entity.takeDamage(20);

      // 20 * 1.5 = 30 damage
      expect(entity.currentHp, 70);
    });
  });

  group('AttackResult', () {
    test('기본 생성', () {
      const result = AttackResult(damage: 15);

      expect(result.damage, 15);
      expect(result.isCritical, false);
      expect(result.isBlocked, false);
    });

    test('크리티컬 히트', () {
      const result = AttackResult(damage: 30, isCritical: true);

      expect(result.isCritical, true);
    });

    test('블록된 데미지', () {
      const result = AttackResult(
        damage: 20,
        isBlocked: true,
        blockedAmount: 10,
      );

      expect(result.actualDamage, 10);
    });
  });

  group('HealResult', () {
    test('기본 생성', () {
      const result = HealResult(amount: 20);

      expect(result.amount, 20);
      expect(result.overheal, 0);
    });

    test('오버힐', () {
      const result = HealResult(amount: 20, overheal: 5);

      expect(result.amount, 20);
      expect(result.overheal, 5);
    });
  });

  group('TurnPhase', () {
    test('모든 단계 정의', () {
      expect(TurnPhase.values.length, 5);
      expect(TurnPhase.playerStart, isNotNull);
      expect(TurnPhase.playerAction, isNotNull);
      expect(TurnPhase.enemyAction, isNotNull);
      expect(TurnPhase.victory, isNotNull);
      expect(TurnPhase.defeat, isNotNull);
    });
  });

  group('BattleState', () {
    test('모든 상태 정의', () {
      expect(BattleState.values.length, 4);
      expect(BattleState.playerTurn, isNotNull);
      expect(BattleState.enemyTurn, isNotNull);
      expect(BattleState.win, isNotNull);
      expect(BattleState.loss, isNotNull);
    });
  });

  group('EffectType', () {
    test('모든 효과 타입 정의', () {
      expect(EffectType.values.length, greaterThanOrEqualTo(8));
      expect(EffectType.weak, isNotNull);
      expect(EffectType.vulnerable, isNotNull);
      expect(EffectType.strength, isNotNull);
      expect(EffectType.poison, isNotNull);
      expect(EffectType.burn, isNotNull);
      expect(EffectType.stun, isNotNull);
    });
  });

  group('Turn Processing', () {
    test('턴 시작 - 블록 리셋 및 DoT 처리', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
        baseAttack: 10,
      );

      entity.addBlock(20);
      entity.applyEffect(BattleEffect(
        type: EffectType.poison,
        duration: 3,
        value: 5,
      ));

      entity.onTurnStart();

      expect(entity.block, 0); // 블록 리셋
      expect(entity.currentHp, 95); // 독 데미지 5
    });

    test('턴 종료 - 효과 감소', () {
      final entity = BattleEntity(
        id: 'hero',
        name: 'Hero',
        maxHp: 100,
        baseAttack: 10,
      );

      entity.applyEffect(BattleEffect(
        type: EffectType.strength,
        duration: 2,
        value: 5,
      ));

      entity.onTurnEnd();

      expect(entity.effects.first.duration, 1);
    });
  });

  group('BattleEntityFactory', () {
    test('플레이어 생성', () {
      final player = BattleEntityFactory.player(
        name: 'Hero',
        maxHp: 120,
        baseAttack: 15,
      );

      expect(player.id, 'player');
      expect(player.name, 'Hero');
      expect(player.maxHp, 120);
      expect(player.baseAttack, 15);
    });

    test('적 생성', () {
      final enemy = BattleEntityFactory.enemy(
        id: 'goblin_001',
        name: 'Goblin',
        maxHp: 50,
        baseAttack: 8,
      );

      expect(enemy.id, 'goblin_001');
      expect(enemy.name, 'Goblin');
      expect(enemy.maxHp, 50);
      expect(enemy.baseAttack, 8);
    });
  });
}
