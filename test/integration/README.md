# Integration Tests

This directory contains comprehensive integration tests for the mg_common_game library. These tests verify that multiple systems work correctly together in real-world scenarios.

## Test Files

### 1. save_cloud_integration_test.dart
**Purpose**: Tests the integration between local save system and cloud synchronization.

**Scenarios Covered**:
- Local save then cloud sync workflow
- Cloud sync with incremental updates
- Conflict resolution (newer data wins)
- Save corruption recovery using cloud backup
- Multi-key save and sync
- Sync status transitions
- Data merge on sync conflict
- Edge cases: empty save data, large data payload, special characters in keys
- Real-world: complete game session save and restore

**Key Integration Points**:
- `LocalSaveSystem` + `CloudSaveManager`
- Save/load operations across local and cloud storage
- Conflict resolution strategies
- Data synchronization workflows

**Example Test**:
```dart
test('Local save then cloud sync workflow', () async {
  final playerData = {'level': 5, 'gold': 1000};
  await localSave.save('player_data', playerData);
  await cloudSave.save(playerData, syncImmediately: false);
  await cloudSave.sync();
  // Verify data consistency
});
```

---

### 2. battle_effect_integration_test.dart
**Purpose**: Tests combat mechanics with status effects and turn-based systems.

**Scenarios Covered**:
- Poison effect deals damage over turns
- Vulnerable effect increases incoming damage
- Weak effect reduces outgoing damage
- Strength effect increases attack power
- Block absorbs damage completely
- Burn effect ticks each turn
- Regeneration heals each turn
- Effect duration decays over turns
- Multiple effects stack and interact
- Critical hits deal increased damage
- Complete battle with effect management
- Edge cases: overkill damage, heal overflow, zero/negative damage, permanent effects
- Real-world: boss battle with phases, party vs multiple enemies

**Key Integration Points**:
- `BattleManagerBase` + `BattleEntity` + `BattleEffect`
- Turn-based combat flow
- Status effect application and decay
- Damage calculation with modifiers
- Victory/defeat conditions

**Example Test**:
```dart
test('Poison effect deals damage over turns', () async {
  battleManager.applyEffect(target: enemy, type: EffectType.poison, duration: 3, value: 5);
  enemy.onTurnStart(); // Process poison damage
  expect(enemy.currentHp, lessThan(initialHp));
});
```

---

### 3. progression_achievement_integration_test.dart
**Purpose**: Tests progression system integration with achievement unlocking.

**Scenarios Covered**:
- Level up triggers achievement unlock
- Multiple level ups unlock multiple achievements
- XP milestone achievement
- Quick learner achievement for consecutive level ups
- Hidden achievement revealed when unlocked
- Achievement progress tracking
- Achievement unlocks are idempotent
- Save and load progression with achievements
- Edge cases: exact XP requirements, massive XP gain, zero/negative XP
- Real-world: complete gameplay loop, achievement notification queue, achievement categories, prestige unlocks achievement, achievement rewards bonus XP, achievement completion percentage

**Key Integration Points**:
- `ProgressionManager` + `AchievementManager`
- Level-up callbacks triggering achievement checks
- XP accumulation and level progression
- Achievement unlock notifications
- Save/load state persistence

**Example Test**:
```dart
test('Level up triggers achievement unlock', () {
  progressionManager.onLevelUp = (newLevel) {
    if (newLevel == 2) achievementManager.unlock('first_level');
  };
  progressionManager.addXp(100);
  expect(achievementManager.isUnlocked('first_level'), isTrue);
});
```

---

### 4. idle_prestige_integration_test.dart
**Purpose**: Tests idle game mechanics with prestige system integration.

**Scenarios Covered**:
- Offline progress accumulates resources
- Prestige becomes available after earning enough resources
- Prestige resets resources but provides permanent bonus
- Prestige bonus multiplies idle production
- Offline progress with prestige bonus
- Multiple prestige cycles with increasing bonuses
- Offline progress capped at maximum hours
- Prestige calculation with different formulas (logarithmic, linear, square root, diminishing)
- Offline rewards with efficiency modifier
- Claim offline rewards with multiplier (ad bonus)
- Edge cases: prestige at exact minimum, prestige below minimum, no offline time, storage overflow prevention
- Real-world: first prestige tutorial flow, complete idle session with prestige, prestige progression curve, offline progress notification system, prestige milestone achievements, save and load complete state

**Key Integration Points**:
- `IdleManager` + `PrestigeManager` + `OfflineProgressManager`
- Resource production and accumulation
- Offline time calculation and rewards
- Prestige point calculation and bonuses
- Production multipliers from prestige

**Example Test**:
```dart
test('Prestige bonus multiplies idle production', () {
  prestigeManager.fromJson({'prestigePoints': 10}); // 10% bonus
  idleManager.setGlobalModifier(prestigeManager.prestigeBonus);
  final production = goldResource.calculateProduction(Duration(hours: 1));
  expect(production, 110); // 100 * 1.1
});
```

---

## Running the Tests

### Run all integration tests:
```bash
flutter test test/integration/
```

### Run a specific integration test:
```bash
flutter test test/integration/save_cloud_integration_test.dart
flutter test test/integration/battle_effect_integration_test.dart
flutter test test/integration/progression_achievement_integration_test.dart
flutter test test/integration/idle_prestige_integration_test.dart
```

### Run with coverage:
```bash
flutter test --coverage test/integration/
```

---

## Test Structure

Each integration test follows this pattern:

```dart
void main() {
  group('System Integration Tests', () {
    late SystemA systemA;
    late SystemB systemB;

    setUp(() async {
      // Initialize systems
      // Setup test data
    });

    tearDown() {
      // Clean up
    });

    test('Basic integration scenario', () {
      // Test basic interaction
    });

    test('Complex workflow', () {
      // Test complex multi-step workflow
    });

    test('Edge case: ...', () {
      // Test edge cases
    });

    test('Real-world: ...', () {
      // Test realistic game scenarios
    });
  });
}
```

---

## Key Testing Principles

### 1. Real-World Scenarios
Tests simulate actual game usage patterns:
- Complete gameplay loops
- Multi-step workflows
- Typical player actions

### 2. Edge Case Coverage
Tests verify system behavior at boundaries:
- Zero/negative values
- Maximum values
- Empty states
- Overflow conditions

### 3. Integration Focus
Tests verify systems working together:
- Data flow between systems
- Event propagation
- State synchronization
- Callback integration

### 4. Idempotency
Tests verify operations can be repeated safely:
- Achievement unlocking
- Save operations
- State updates

---

## Common Test Patterns

### Pattern 1: Event-Driven Integration
```dart
systemA.onEvent = (data) {
  systemB.handleEvent(data);
};
systemA.triggerEvent();
expect(systemB.wasHandled, isTrue);
```

### Pattern 2: State Synchronization
```dart
systemA.updateState(data);
final stateA = systemA.save();
systemB.load(stateA);
expect(systemB.state, equals(systemA.state));
```

### Pattern 3: Progressive Workflow
```dart
for (int step = 0; step < 10; step++) {
  systemA.performStep();
  if (systemA.reachedMilestone(step)) {
    systemB.triggerReward();
  }
}
expect(systemB.rewardCount, greaterThan(0));
```

---

## Adding New Integration Tests

When adding new integration tests:

1. **Identify Integration Points**: Determine which systems need to work together
2. **Define Scenarios**: List real-world use cases and workflows
3. **Include Edge Cases**: Think about boundary conditions and error cases
4. **Test State Persistence**: Verify save/load functionality works correctly
5. **Document Clearly**: Add comments explaining what each test verifies

### Template for New Tests:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/...';

/// Integration test for SystemA + SystemB
/// Tests scenarios where [describe integration]
void main() {
  group('SystemA + SystemB Integration Tests', () {
    late SystemA systemA;
    late SystemB systemB;

    setUp(() async {
      // Initialize systems
    });

    test('Basic integration', () {
      // Test basic scenario
    });

    test('Real-world: complete workflow', () {
      // Test realistic usage
    });

    test('Edge case: boundary condition', () {
      // Test edge case
    });
  });
}
```

---

## Coverage Goals

Integration tests aim for:
- ✅ All major system interactions covered
- ✅ Common workflows tested end-to-end
- ✅ Edge cases and error conditions handled
- ✅ Real-world scenarios validated
- ✅ State persistence verified

---

## Related Documentation

- [Unit Tests](../unit/README.md)
- [System Tests](../systems/README.md)
- [Feature Tests](../features/README.md)
- [API Documentation](../../docs/api/)

---

## Continuous Integration

These integration tests run automatically on:
- Pull requests
- Main branch commits
- Release builds

Failed integration tests block deployment to ensure system reliability.
