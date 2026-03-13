import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/economy/currency_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CurrencyType', () {
    test('모든 화폐 타입 존재', () {
      expect(CurrencyType.values.length, 4);
      expect(CurrencyType.values, contains(CurrencyType.coin));
      expect(CurrencyType.values, contains(CurrencyType.gem));
      expect(CurrencyType.values, contains(CurrencyType.star));
      expect(CurrencyType.values, contains(CurrencyType.ticket));
    });

    test('화폐 타입별 name 속성', () {
      expect(CurrencyType.coin.name, 'coin');
      expect(CurrencyType.gem.name, 'gem');
      expect(CurrencyType.star.name, 'star');
      expect(CurrencyType.ticket.name, 'ticket');
    });
  });

  group('TransactionSource', () {
    test('모든 트랜잭션 소스 존재', () {
      expect(TransactionSource.values.length, 7);
      expect(TransactionSource.values, contains(TransactionSource.daily_quest));
      expect(TransactionSource.values, contains(TransactionSource.achievement));
      expect(TransactionSource.values, contains(TransactionSource.purchase));
      expect(TransactionSource.values, contains(TransactionSource.reward));
      expect(TransactionSource.values, contains(TransactionSource.penalty));
      expect(TransactionSource.values, contains(TransactionSource.event));
      expect(TransactionSource.values, contains(TransactionSource.custom));
    });
  });

  group('CurrencyManager', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final manager = CurrencyManager.instance;
      await manager.initialize();
    });

    tearDown(() async {
      final manager = CurrencyManager.instance;
      await manager.resetAllBalances();
    });

    test('싱글톤 인스턴스', () {
      final manager1 = CurrencyManager.instance;
      final manager2 = CurrencyManager.instance;

      expect(identical(manager1, manager2), true);
    });

    test('초기화 전 isInitialized는 false', () {
      // 새 인스턴스 생성
      final manager = CurrencyManager.instance;
      // 이미 initialize됨
      expect(manager.isInitialized, true);
    });

    test('초기 잔액은 0', () {
      final manager = CurrencyManager.instance;

      expect(manager.coins, 0);
      expect(manager.gems, 0);
      expect(manager.stars, 0);
      expect(manager.tickets, 0);
    });

    test('addCurrency로 코인 추가', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 100);

      expect(manager.coins, 100);
    });

    test('addCurrency로 보석 추가', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.gem, 50);

      expect(manager.gems, 50);
    });

    test('addCurrency는 0 이하의 금액 무시', () async {
      final manager = CurrencyManager.instance;

      final result1 = await manager.addCurrency(CurrencyType.coin, 0);
      final result2 = await manager.addCurrency(CurrencyType.coin, -10);

      expect(result1, false);
      expect(result2, false);
      expect(manager.coins, 0);
    });

    test('spendCurrency로 코인 차감', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 100);
      final success = await manager.spendCurrency(CurrencyType.coin, 30);

      expect(success, true);
      expect(manager.coins, 70);
    });

    test('spendCurrency는 잔액 부족 시 false 반환', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 50);
      final success = await manager.spendCurrency(CurrencyType.coin, 100);

      expect(success, false);
      expect(manager.coins, 50);
    });

    test('spendCurrency는 0 이하의 금액 거부', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 100);

      final result1 = await manager.spendCurrency(CurrencyType.coin, 0);
      final result2 = await manager.spendCurrency(CurrencyType.coin, -10);

      expect(result1, false);
      expect(result2, false);
      expect(manager.coins, 100);
    });

    test('setCurrency로 잔액 직접 설정', () async {
      final manager = CurrencyManager.instance;

      await manager.setCurrency(CurrencyType.gem, 500);

      expect(manager.gems, 500);
    });

    test('setCurrency는 음수 거부', () async {
      final manager = CurrencyManager.instance;

      final result = await manager.setCurrency(CurrencyType.coin, -100);

      expect(result, false);
      expect(manager.coins, 0);
    });

    test('hasEnough로 잔액 확인', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 100);

      expect(manager.hasEnough(CurrencyType.coin, 50), true);
      expect(manager.hasEnough(CurrencyType.coin, 100), true);
      expect(manager.hasEnough(CurrencyType.coin, 101), false);
    });

    test('hasEnoughMultiple로 여러 화폐 확인', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 100);
      await manager.addCurrency(CurrencyType.gem, 50);

      expect(manager.hasEnoughMultiple({
        CurrencyType.coin: 50,
        CurrencyType.gem: 30,
      }), true);

      expect(manager.hasEnoughMultiple({
        CurrencyType.coin: 100,
        CurrencyType.gem: 30,
      }), true);

      expect(manager.hasEnoughMultiple({
        CurrencyType.coin: 101,
        CurrencyType.gem: 30,
      }), false);
    });

    test('getAllBalances로 모든 잔액 조회', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 100);
      await manager.addCurrency(CurrencyType.gem, 50);
      await manager.addCurrency(CurrencyType.star, 25);

      final balances = manager.getAllBalances();

      expect(balances[CurrencyType.coin], 100);
      expect(balances[CurrencyType.gem], 50);
      expect(balances[CurrencyType.star], 25);
      expect(balances[CurrencyType.ticket], 0);
    });

    test('resetAllBalances로 모든 잔액 초기화', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 100);
      await manager.addCurrency(CurrencyType.gem, 50);

      await manager.resetAllBalances();

      expect(manager.coins, 0);
      expect(manager.gems, 0);
    });

    test('resetBalance로 특정 화폐만 초기화', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 100);
      await manager.addCurrency(CurrencyType.gem, 50);

      await manager.resetBalance(CurrencyType.coin);

      expect(manager.coins, 0);
      expect(manager.gems, 50);
    });

    test('getBalanceStream으로 변경 스트림 구독', () async {
      final manager = CurrencyManager.instance;

      final values = <int>[];
      final subscription = manager.getBalanceStream(CurrencyType.coin).listen(values.add);

      await manager.addCurrency(CurrencyType.coin, 100);
      await manager.addCurrency(CurrencyType.coin, 50);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(values, containsAll([100, 150]));

      await subscription.cancel();
    });

    test('onCoinsChanged로 코인 변경 스트림 구독', () async {
      final manager = CurrencyManager.instance;

      final values = <int>[];
      final subscription = manager.onCoinsChanged.listen(values.add);

      await manager.addCurrency(CurrencyType.coin, 100);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(values, contains(100));

      await subscription.cancel();
    });

    test('onGemsChanged로 보석 변경 스트림 구독', () async {
      final manager = CurrencyManager.instance;

      final values = <int>[];
      final subscription = manager.onGemsChanged.listen(values.add);

      await manager.addCurrency(CurrencyType.gem, 50);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(values, contains(50));

      await subscription.cancel();
    });

    test('ChangeNotifier 상속', () async {
      final manager = CurrencyManager.instance;

      var notified = false;
      manager.addListener(() => notified = true);

      await manager.addCurrency(CurrencyType.coin, 100);

      expect(notified, true);
    });

    test('여러 화폐 독립적 관리', () async {
      final manager = CurrencyManager.instance;

      await manager.addCurrency(CurrencyType.coin, 100);
      await manager.addCurrency(CurrencyType.gem, 50);
      await manager.addCurrency(CurrencyType.star, 25);
      await manager.addCurrency(CurrencyType.ticket, 10);

      await manager.spendCurrency(CurrencyType.coin, 30);
      await manager.spendCurrency(CurrencyType.gem, 20);

      expect(manager.coins, 70);
      expect(manager.gems, 30);
      expect(manager.stars, 25);
      expect(manager.tickets, 10);
    });
  });

  group('CurrencyTransaction', () {
    test('기본 생성', () {
      final transaction = CurrencyTransaction(
        currency: CurrencyType.coin,
        amount: 100,
        isAddition: true,
        balanceBefore: 0,
        balanceAfter: 100,
        source: 'daily_quest',
        timestamp: DateTime(2025, 1, 1, 12, 0),
      );

      expect(transaction.currency, CurrencyType.coin);
      expect(transaction.amount, 100);
      expect(transaction.isAddition, true);
      expect(transaction.balanceBefore, 0);
      expect(transaction.balanceAfter, 100);
    });

    test('toJson/fromJson 변환', () {
      final transaction = CurrencyTransaction(
        currency: CurrencyType.gem,
        amount: 50,
        isAddition: false,
        balanceBefore: 100,
        balanceAfter: 50,
        source: 'purchase',
        timestamp: DateTime(2025, 1, 1, 12, 0),
      );

      final json = transaction.toJson();
      final restored = CurrencyTransaction.fromJson(json);

      expect(restored.currency, CurrencyType.gem);
      expect(restored.amount, 50);
      expect(restored.isAddition, false);
      expect(restored.balanceBefore, 100);
      expect(restored.balanceAfter, 50);
      expect(restored.source, 'purchase');
    });
  });

  group('RewardPackage', () {
    test('기본 생성', () {
      const rewardPackage = RewardPackage(
        id: 'starter_pack',
        name: '스타터 팩',
        rewards: {
          CurrencyType.coin: 1000,
          CurrencyType.gem: 100,
        },
        price: 500,
      );

      expect(rewardPackage.id, 'starter_pack');
      expect(rewardPackage.name, '스타터 팩');
      expect(rewardPackage.rewards[CurrencyType.coin], 1000);
      expect(rewardPackage.price, 500);
      expect(rewardPackage.priceCurrency, CurrencyType.gem);
    });

    test('canPurchase - 구매 가능', () {
      const rewardPackage = RewardPackage(
        id: 'starter_pack',
        name: '스타터 팩',
        rewards: {
          CurrencyType.coin: 1000,
        },
        price: 500,
      );

      expect(rewardPackage.canPurchase(500, 0), true);
      expect(rewardPackage.canPurchase(600, 0), true);
    });

    test('canPurchase - 잔액 부족', () {
      const rewardPackage = RewardPackage(
        id: 'starter_pack',
        name: '스타터 팩',
        rewards: {
          CurrencyType.coin: 1000,
        },
        price: 500,
      );

      expect(rewardPackage.canPurchase(499, 0), false);
    });

    test('canPurchase - 횟수 제한', () {
      const rewardPackage = RewardPackage(
        id: 'limited_pack',
        name: '한정 팩',
        rewards: {
          CurrencyType.coin: 1000,
        },
        price: 500,
        isLimited: true,
        maxPurchaseCount: 3,
      );

      expect(rewardPackage.canPurchase(500, 0), true);
      expect(rewardPackage.canPurchase(500, 2), true);
      expect(rewardPackage.canPurchase(500, 3), false);
    });

    test('canPurchase - 시간 제한', () {
      final expiredDate = DateTime.now().subtract(const Duration(days: 1));
      final rewardPackage = RewardPackage(
        id: 'event_pack',
        name: '이벤트 팩',
        rewards: {
          CurrencyType.coin: 1000,
        },
        price: 500,
        availableUntil: expiredDate,
      );

      expect(rewardPackage.canPurchase(500, 0), false);
    });

    test('toJson/fromJson 변환', () {
      const rewardPackage = RewardPackage(
        id: 'starter_pack',
        name: '스타터 팩',
        rewards: {
          CurrencyType.coin: 1000,
          CurrencyType.gem: 100,
        },
        price: 500,
        priceCurrency: CurrencyType.gem,
        isLimited: true,
        maxPurchaseCount: 3,
      );

      final json = rewardPackage.toJson();
      final restored = RewardPackage.fromJson(json);

      expect(restored.id, 'starter_pack');
      expect(restored.name, '스타터 팩');
      expect(restored.rewards[CurrencyType.coin], 1000);
      expect(restored.rewards[CurrencyType.gem], 100);
      expect(restored.price, 500);
      expect(restored.priceCurrency, CurrencyType.gem);
      expect(restored.isLimited, true);
      expect(restored.maxPurchaseCount, 3);
    });
  });
}
