import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/ab_test/ab_test.dart';

void main() {
  group('ExperimentVariant', () {
    test('기본 생성', () {
      const variant = ExperimentVariant(
        id: 'control',
        name: 'Control Group',
        isControl: true,
      );

      expect(variant.id, 'control');
      expect(variant.name, 'Control Group');
      expect(variant.isControl, true);
      expect(variant.weight, 1.0);
    });

    test('파라미터와 가중치', () {
      const variant = ExperimentVariant(
        id: 'treatment',
        name: 'Treatment',
        parameters: {'buttonColor': 'red', 'fontSize': 16},
        weight: 2.0,
      );

      expect(variant.parameters['buttonColor'], 'red');
      expect(variant.parameters['fontSize'], 16);
      expect(variant.weight, 2.0);
    });

    test('JSON 직렬화', () {
      const variant = ExperimentVariant(
        id: 'test',
        name: 'Test',
        parameters: {'key': 'value'},
        weight: 1.5,
        isControl: true,
      );

      final json = variant.toJson();
      final restored = ExperimentVariant.fromJson(json);

      expect(restored.id, variant.id);
      expect(restored.name, variant.name);
      expect(restored.parameters, variant.parameters);
      expect(restored.weight, variant.weight);
      expect(restored.isControl, variant.isControl);
    });

    test('toString', () {
      const variant = ExperimentVariant(
        id: 'test',
        name: 'Test',
        weight: 1.5,
      );

      expect(variant.toString(), contains('test'));
      expect(variant.toString(), contains('Test'));
    });
  });

  group('ExperimentConfig', () {
    test('기본 생성', () {
      const config = ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
          ExperimentVariant(id: 'treatment', name: 'Treatment'),
        ],
      );

      expect(config.id, 'exp1');
      expect(config.name, 'Experiment 1');
      expect(config.variants.length, 2);
      expect(config.status, ExperimentStatus.draft);
    });

    test('controlVariant', () {
      const config = ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
          ExperimentVariant(id: 'treatment', name: 'Treatment'),
        ],
      );

      expect(config.controlVariant?.id, 'control');
    });

    test('totalWeight', () {
      const config = ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'a', name: 'A', weight: 1.0),
          ExperimentVariant(id: 'b', name: 'B', weight: 2.0),
          ExperimentVariant(id: 'c', name: 'C', weight: 1.5),
        ],
      );

      expect(config.totalWeight, 4.5);
    });

    test('isActive - draft', () {
      const config = ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [],
        status: ExperimentStatus.draft,
      );

      expect(config.isActive, false);
    });

    test('isActive - running', () {
      final config = ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: const [],
        status: ExperimentStatus.running,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1)),
      );

      expect(config.isActive, true);
    });

    test('isActive - 시작 전', () {
      final config = ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: const [],
        status: ExperimentStatus.running,
        startDate: DateTime.now().add(const Duration(days: 1)),
      );

      expect(config.isActive, false);
    });

    test('isActive - 종료 후', () {
      final config = ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: const [],
        status: ExperimentStatus.running,
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(config.isActive, false);
    });

    test('JSON 직렬화', () {
      final config = ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        description: 'Test experiment',
        variants: const [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
        allocationStrategy: AllocationStrategy.random,
        trafficPercentage: 50.0,
      );

      final json = config.toJson();
      final restored = ExperimentConfig.fromJson(json);

      expect(restored.id, config.id);
      expect(restored.name, config.name);
      expect(restored.description, config.description);
      expect(restored.status, config.status);
      expect(restored.allocationStrategy, config.allocationStrategy);
      expect(restored.trafficPercentage, config.trafficPercentage);
    });

    test('copyWith', () {
      const config = ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [],
        status: ExperimentStatus.draft,
      );

      final updated = config.copyWith(status: ExperimentStatus.running);

      expect(updated.status, ExperimentStatus.running);
      expect(updated.id, config.id);
    });
  });

  group('UserExperimentAssignment', () {
    test('JSON 직렬화', () {
      final assignment = UserExperimentAssignment(
        odId: 'user1',
        experimentId: 'exp1',
        variantId: 'control',
        assignedAt: DateTime(2024, 1, 1),
        isInTraffic: true,
      );

      final json = assignment.toJson();
      final restored = UserExperimentAssignment.fromJson(json);

      expect(restored.odId, assignment.odId);
      expect(restored.experimentId, assignment.experimentId);
      expect(restored.variantId, assignment.variantId);
      expect(restored.isInTraffic, assignment.isInTraffic);
    });
  });

  group('ExperimentEvent', () {
    test('JSON 직렬화', () {
      final event = ExperimentEvent(
        experimentId: 'exp1',
        variantId: 'control',
        eventName: 'button_click',
        eventData: {'count': 1},
        timestamp: DateTime(2024, 1, 1),
        odId: 'user1',
      );

      final json = event.toJson();
      final restored = ExperimentEvent.fromJson(json);

      expect(restored.experimentId, event.experimentId);
      expect(restored.variantId, event.variantId);
      expect(restored.eventName, event.eventName);
      expect(restored.eventData, event.eventData);
    });
  });

  group('VariantMetrics', () {
    test('기본 생성 및 JSON', () {
      const metrics = VariantMetrics(
        variantId: 'control',
        participants: 1000,
        conversions: 50,
        conversionRate: 0.05,
        customMetrics: {'avgTime': 120.5},
      );

      final json = metrics.toJson();
      final restored = VariantMetrics.fromJson(json);

      expect(restored.variantId, metrics.variantId);
      expect(restored.participants, metrics.participants);
      expect(restored.conversions, metrics.conversions);
      expect(restored.conversionRate, metrics.conversionRate);
      expect(restored.customMetrics['avgTime'], 120.5);
    });
  });

  group('SimpleABTest', () {
    test('getRandomVariant', () {
      final test = SimpleABTest(
        testId: 'test1',
        variants: ['A', 'B', 'C'],
        seed: 42,
      );

      final variants = <String>{};
      for (int i = 0; i < 100; i++) {
        variants.add(test.getRandomVariant());
      }

      expect(variants, containsAll(['A', 'B', 'C']));
    });

    test('getVariantForUser - 일관성', () {
      final test = SimpleABTest(
        testId: 'test1',
        variants: ['A', 'B'],
      );

      final variant1 = test.getVariantForUser('user123');
      final variant2 = test.getVariantForUser('user123');
      final variant3 = test.getVariantForUser('user456');

      expect(variant1, variant2); // 같은 유저는 같은 변형
      // 다른 유저는 다를 수 있음 (해시에 따라)
      expect(['A', 'B'], contains(variant3));
    });

    test('getWeightedVariant', () {
      final test = SimpleABTest(
        testId: 'test1',
        variants: ['A', 'B'],
        seed: 42,
      );

      final counts = <String, int>{'A': 0, 'B': 0};

      for (int i = 0; i < 1000; i++) {
        final variant = test.getWeightedVariant({'A': 1.0, 'B': 9.0});
        counts[variant] = counts[variant]! + 1;
      }

      // B가 A보다 훨씬 많아야 함 (9:1 비율)
      expect(counts['B']! > counts['A']! * 5, true);
    });
  });

  group('ABTestManager', () {
    late ABTestManager manager;

    setUp(() {
      manager = ABTestManager(randomSeed: 42);
      manager.setUser('user123');
    });

    tearDown(() {
      manager.dispose();
    });

    test('유저 설정', () {
      expect(manager.currentUserId, 'user123');
    });

    test('유저 변경 시 할당 클리어', () async {
      manager.registerExperiment(ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: const [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
          ExperimentVariant(id: 'treatment', name: 'Treatment'),
        ],
        status: ExperimentStatus.running,
      ));

      await manager.getVariant('exp1');
      expect(manager.getVariantSync('exp1'), isNotNull);

      manager.setUser('user456');
      expect(manager.getVariantSync('exp1'), 'control'); // 캐시 클리어됨
    });

    test('실험 등록', () {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [],
      ));

      expect(manager.experimentIds, contains('exp1'));
    });

    test('여러 실험 등록', () {
      manager.registerExperiments([
        const ExperimentConfig(id: 'exp1', name: 'Exp1', variants: []),
        const ExperimentConfig(id: 'exp2', name: 'Exp2', variants: []),
      ]);

      expect(manager.experimentIds.length, 2);
    });

    test('실험 제거', () {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [],
      ));

      manager.removeExperiment('exp1');
      expect(manager.getExperiment('exp1'), isNull);
    });

    test('활성 실험 필터링', () {
      manager.registerExperiments([
        const ExperimentConfig(
          id: 'active',
          name: 'Active',
          variants: [],
          status: ExperimentStatus.running,
        ),
        const ExperimentConfig(
          id: 'draft',
          name: 'Draft',
          variants: [],
          status: ExperimentStatus.draft,
        ),
      ]);

      expect(manager.activeExperiments.length, 1);
      expect(manager.activeExperiments.first.id, 'active');
    });

    test('변형 할당 - 미등록 실험', () async {
      final variant = await manager.getVariant('nonexistent');
      expect(variant, isNull);
    });

    test('변형 할당 - 비활성 실험', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.draft,
      ));

      final variant = await manager.getVariant('exp1');
      expect(variant, 'control'); // 컨트롤 그룹 반환
    });

    test('변형 할당 - 활성 실험', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
          ExperimentVariant(id: 'treatment', name: 'Treatment'),
        ],
        status: ExperimentStatus.running,
      ));

      final variant = await manager.getVariant('exp1');
      expect(['control', 'treatment'], contains(variant));
    });

    test('변형 할당 - 캐시 사용', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
          ExperimentVariant(id: 'treatment', name: 'Treatment'),
        ],
        status: ExperimentStatus.running,
      ));

      final variant1 = await manager.getVariant('exp1');
      final variant2 = await manager.getVariant('exp1');

      expect(variant1, variant2); // 캐시에서 동일한 값
    });

    test('변형 할당 - 유저 ID 해시 일관성', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'a', name: 'A'),
          ExperimentVariant(id: 'b', name: 'B'),
        ],
        status: ExperimentStatus.running,
        allocationStrategy: AllocationStrategy.userIdHash,
      ));

      // 같은 유저는 같은 변형
      final manager2 = ABTestManager();
      manager2.setUser('user123');
      manager2.registerExperiment(manager.getExperiment('exp1')!);

      final variant1 = await manager.getVariant('exp1');
      final variant2 = await manager2.getVariant('exp1');

      expect(variant1, variant2);

      manager2.dispose();
    });

    test('getVariantSync', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
      ));

      // 할당 전 - 컨트롤 반환
      expect(manager.getVariantSync('exp1'), 'control');

      // 할당 후 - 할당된 값 반환
      await manager.getVariant('exp1');
      expect(manager.getVariantSync('exp1'), isNotNull);
    });

    test('getParameter', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(
            id: 'control',
            name: 'Control',
            isControl: true,
            parameters: {'buttonColor': 'blue', 'fontSize': 14},
          ),
        ],
        status: ExperimentStatus.running,
      ));

      await manager.getVariant('exp1');

      expect(manager.getParameter<String>('exp1', 'buttonColor'), 'blue');
      expect(manager.getParameter<int>('exp1', 'fontSize'), 14);
      expect(manager.getParameter<String>('exp1', 'nonexistent'), isNull);
    });

    test('isVariant', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
      ));

      await manager.getVariant('exp1');

      expect(manager.isVariant('exp1', 'control'), true);
      expect(manager.isVariant('exp1', 'treatment'), false);
    });

    test('isControl', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
      ));

      await manager.getVariant('exp1');

      expect(manager.isControl('exp1'), true);
    });

    test('오버라이드', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
          ExperimentVariant(id: 'treatment', name: 'Treatment'),
        ],
        status: ExperimentStatus.running,
      ));

      manager.setOverride('exp1', 'treatment');

      final variant = await manager.getVariant('exp1');
      expect(variant, 'treatment');
      expect(manager.overrideCount, 1);
    });

    test('오버라이드 제거', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
      ));

      manager.setOverride('exp1', 'treatment');
      manager.removeOverride('exp1');

      expect(manager.overrideCount, 0);
    });

    test('모든 오버라이드 클리어', () {
      manager.setOverride('exp1', 'a');
      manager.setOverride('exp2', 'b');

      manager.clearOverrides();

      expect(manager.overrideCount, 0);
    });

    test('이벤트 추적', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
      ));

      await manager.getVariant('exp1');
      await manager.trackEvent('exp1', 'button_click', eventData: {'count': 1});

      expect(manager.trackedEventCount, 1);

      final events = manager.getTrackedEvents(experimentId: 'exp1');
      expect(events.length, 1);
      expect(events.first.eventName, 'button_click');
    });

    test('전환 이벤트 추적', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
      ));

      await manager.getVariant('exp1');
      await manager.trackConversion('exp1');

      final events = manager.getTrackedEvents();
      expect(events.first.eventName, 'conversion');
    });

    test('모든 실험에 이벤트 추적', () async {
      manager.registerExperiments([
        const ExperimentConfig(
          id: 'exp1',
          name: 'Exp1',
          variants: [ExperimentVariant(id: 'a', name: 'A', isControl: true)],
          status: ExperimentStatus.running,
        ),
        const ExperimentConfig(
          id: 'exp2',
          name: 'Exp2',
          variants: [ExperimentVariant(id: 'b', name: 'B', isControl: true)],
          status: ExperimentStatus.running,
        ),
      ]);

      await manager.getVariant('exp1');
      await manager.getVariant('exp2');
      await manager.trackEventForAllExperiments('purchase');

      expect(manager.trackedEventCount, 2);
    });

    test('추적 이벤트 클리어', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
      ));

      await manager.getVariant('exp1');
      await manager.trackEvent('exp1', 'test');

      manager.clearTrackedEvents();

      expect(manager.trackedEventCount, 0);
    });

    test('JSON 저장/복원', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
      ));

      await manager.getVariant('exp1');
      manager.setOverride('exp2', 'treatment');

      final json = manager.toJson();

      final newManager = ABTestManager();
      newManager.fromJson(json);

      expect(newManager.currentUserId, 'user123');
      expect(newManager.overrides['exp2'], 'treatment');

      newManager.dispose();
    });

    test('전체 클리어', () async {
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [],
        status: ExperimentStatus.running,
      ));

      manager.setOverride('exp1', 'a');

      manager.clear();

      expect(manager.currentUserId, isNull);
      expect(manager.experimentIds, isEmpty);
      expect(manager.overrideCount, 0);
    });

    test('ChangeNotifier 동작', () async {
      int notifyCount = 0;
      manager.addListener(() => notifyCount++);

      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
      ));

      await manager.getVariant('exp1');

      expect(notifyCount, greaterThan(0));
    });
  });

  group('ABTestManager - 트래픽 비율', () {
    test('100% 트래픽', () async {
      final manager = ABTestManager(randomSeed: 42);
      manager.setUser('user123');
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
          ExperimentVariant(id: 'treatment', name: 'Treatment'),
        ],
        status: ExperimentStatus.running,
        trafficPercentage: 100.0,
      ));

      final variant = await manager.getVariant('exp1');
      expect(variant, isNotNull);

      manager.dispose();
    });

    test('0% 트래픽', () async {
      final manager = ABTestManager(randomSeed: 42);
      manager.setUser('user123');
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
        ],
        status: ExperimentStatus.running,
        trafficPercentage: 0.0,
      ));

      final variant = await manager.getVariant('exp1');
      expect(variant, isNull); // 트래픽 외부

      manager.dispose();
    });
  });

  group('ABTestManager - 가중치 기반 할당', () {
    test('가중치에 따른 분포', () async {
      final counts = <String, int>{'a': 0, 'b': 0, 'c': 0};

      for (int i = 0; i < 300; i++) {
        final manager = ABTestManager(randomSeed: i);
        manager.setUser('user$i');
        manager.registerExperiment(const ExperimentConfig(
          id: 'exp1',
          name: 'Experiment 1',
          variants: [
            ExperimentVariant(id: 'a', name: 'A', weight: 1.0),
            ExperimentVariant(id: 'b', name: 'B', weight: 2.0),
            ExperimentVariant(id: 'c', name: 'C', weight: 1.0),
          ],
          status: ExperimentStatus.running,
          allocationStrategy: AllocationStrategy.random,
        ));

        final variant = await manager.getVariant('exp1');
        if (variant != null) {
          counts[variant] = counts[variant]! + 1;
        }

        manager.dispose();
      }

      // B가 가장 많아야 함 (2배 가중치)
      expect(counts['b']! > counts['a']!, true);
      expect(counts['b']! > counts['c']!, true);
    });
  });

  group('ABTestManager - 백엔드 콜백', () {
    late ABTestManager manager;

    setUp(() {
      manager = ABTestManager(randomSeed: 42);
      manager.setUser('user123');
      manager.registerExperiment(const ExperimentConfig(
        id: 'exp1',
        name: 'Experiment 1',
        variants: [
          ExperimentVariant(id: 'control', name: 'Control', isControl: true),
          ExperimentVariant(id: 'treatment', name: 'Treatment'),
        ],
        status: ExperimentStatus.running,
      ));
    });

    tearDown(() {
      manager.dispose();
    });

    test('기존 할당 조회 콜백', () async {
      manager.onFetchAssignment = (experimentId) async {
        return UserExperimentAssignment(
          odId: 'user123',
          experimentId: experimentId,
          variantId: 'treatment',
          assignedAt: DateTime.now(),
        );
      };

      final variant = await manager.getVariant('exp1');
      expect(variant, 'treatment');
    });

    test('할당 저장 콜백', () async {
      String? savedVariant;

      manager.onSaveAssignment = (experimentId, variantId) async {
        savedVariant = variantId;
      };

      await manager.getVariant('exp1');
      expect(savedVariant, isNotNull);
    });

    test('이벤트 추적 콜백', () async {
      ExperimentEvent? trackedEvent;

      manager.onTrackEvent = (event) async {
        trackedEvent = event;
      };

      await manager.getVariant('exp1');
      await manager.trackEvent('exp1', 'click');

      expect(trackedEvent, isNotNull);
      expect(trackedEvent!.eventName, 'click');
    });

    test('실험 목록 조회 콜백', () async {
      manager.onFetchExperiments = () async {
        return [
          const ExperimentConfig(
            id: 'remote_exp',
            name: 'Remote Experiment',
            variants: [
              ExperimentVariant(id: 'a', name: 'A', isControl: true),
            ],
            status: ExperimentStatus.running,
          ),
        ];
      };

      await manager.fetchExperiments();

      expect(manager.experimentIds, contains('remote_exp'));
    });
  });
}
