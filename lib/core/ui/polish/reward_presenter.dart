import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../accessibility/accessibility_settings.dart';
import 'polish_sounds.dart';

/// 보상 아이템 정보
class RewardItem {
  final String id;
  final String name;
  final String? iconPath;
  final IconData? icon;
  final int count;
  final RewardRarity rarity;
  final Color? customColor;

  const RewardItem({
    required this.id,
    required this.name,
    this.iconPath,
    this.icon,
    this.count = 1,
    this.rarity = RewardRarity.common,
    this.customColor,
  });
}

/// 보상 희귀도
enum RewardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// 희귀도별 설정
class RarityConfig {
  final Color color;
  final Color glowColor;
  final double glowIntensity;
  final Duration animationDuration;
  final bool showParticles;
  final bool showShockwave;
  final String sound;

  const RarityConfig({
    required this.color,
    required this.glowColor,
    this.glowIntensity = 1.0,
    this.animationDuration = const Duration(milliseconds: 500),
    this.showParticles = false,
    this.showShockwave = false,
    this.sound = PolishSounds.itemGet,
  });

  static RarityConfig getConfig(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.common:
        return const RarityConfig(
          color: Colors.white,
          glowColor: Colors.white24,
          glowIntensity: 0.3,
          animationDuration: Duration(milliseconds: 400),
          sound: PolishSounds.itemGet,
        );
      case RewardRarity.uncommon:
        return const RarityConfig(
          color: Colors.green,
          glowColor: Colors.greenAccent,
          glowIntensity: 0.5,
          animationDuration: Duration(milliseconds: 450),
          sound: PolishSounds.itemGet,
        );
      case RewardRarity.rare:
        return const RarityConfig(
          color: Colors.blue,
          glowColor: Colors.blueAccent,
          glowIntensity: 0.7,
          animationDuration: Duration(milliseconds: 500),
          showParticles: true,
          sound: PolishSounds.chestOpen,
        );
      case RewardRarity.epic:
        return const RarityConfig(
          color: Colors.purple,
          glowColor: Colors.purpleAccent,
          glowIntensity: 0.9,
          animationDuration: Duration(milliseconds: 600),
          showParticles: true,
          showShockwave: true,
          sound: PolishSounds.chestOpen,
        );
      case RewardRarity.legendary:
        return const RarityConfig(
          color: Colors.orange,
          glowColor: Colors.orangeAccent,
          glowIntensity: 1.0,
          animationDuration: Duration(milliseconds: 800),
          showParticles: true,
          showShockwave: true,
          sound: PolishSounds.legendary,
        );
    }
  }
}

/// 단일 보상 아이템 프레젠터
class MGRewardItemPresenter extends StatefulWidget {
  final RewardItem item;
  final Duration delay;
  final VoidCallback? onComplete;
  final bool autoPlay;
  final bool showName;
  final bool showCount;
  final double size;

  const MGRewardItemPresenter({
    super.key,
    required this.item,
    this.delay = Duration.zero,
    this.onComplete,
    this.autoPlay = true,
    this.showName = true,
    this.showCount = true,
    this.size = 80,
  });

  @override
  State<MGRewardItemPresenter> createState() => _MGRewardItemPresenterState();
}

class _MGRewardItemPresenterState extends State<MGRewardItemPresenter>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  late AnimationController _shockwaveController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shockwaveAnimation;

  late RarityConfig _config;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _config = RarityConfig.getConfig(widget.item.rarity);

    _mainController = AnimationController(
      duration: _config.animationDuration,
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shockwaveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _setupAnimations();

    if (widget.autoPlay) {
      _startWithDelay();
    }
  }

  void _setupAnimations() {
    // 메인 스케일 (팝인)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 0.9),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    ));

    // 페이드인
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // 바운스 (획득 후)
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // 글로우 펄스
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // 쇼크웨이브
    _shockwaveAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _shockwaveController, curve: Curves.easeOut),
    );
  }

  void _startWithDelay() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (mounted) {
      play();
    }
  }

  void play() {
    if (_started) return;
    _started = true;

    // 햅틱 피드백
    if (widget.item.rarity.index >= RewardRarity.rare.index) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _mainController.forward();

    // 레어 이상은 글로우 애니메이션
    if (widget.item.rarity.index >= RewardRarity.rare.index) {
      _mainController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _glowController.repeat(reverse: true);
        }
      });
    }

    // 에픽 이상은 쇼크웨이브
    if (_config.showShockwave) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _shockwaveController.forward();
      });
    }

    // 완료 콜백
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    _shockwaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    final color = widget.item.customColor ?? _config.color;

    if (settings.reduceMotion) {
      return _buildStaticItem(color);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainController,
        _glowController,
        _shockwaveController,
      ]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 쇼크웨이브
            if (_config.showShockwave && _shockwaveController.isAnimating)
              Transform.scale(
                scale: _shockwaveAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(
                        (1.0 - _shockwaveAnimation.value / 2).clamp(0.0, 1.0),
                      ),
                      width: 3,
                    ),
                  ),
                ),
              ),

            // 글로우 배경
            if (widget.item.rarity.index >= RewardRarity.rare.index)
              Container(
                width: widget.size * 1.5,
                height: widget.size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _config.glowColor.withOpacity(
                        _glowAnimation.value * _config.glowIntensity * 0.5,
                      ),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

            // 메인 아이템
            Transform.scale(
              scale: _scaleAnimation.value *
                     (_glowController.isAnimating ? _bounceAnimation.value : 1.0),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: _buildItemContent(color),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStaticItem(Color color) {
    return _buildItemContent(color);
  }

  Widget _buildItemContent(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘/이미지
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black45,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: widget.item.icon != null
                ? Icon(widget.item.icon, size: widget.size * 0.5, color: color)
                : widget.item.iconPath != null
                    ? Image.asset(
                        widget.item.iconPath!,
                        width: widget.size * 0.6,
                        height: widget.size * 0.6,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.card_giftcard,
                          size: widget.size * 0.5,
                          color: color,
                        ),
                      )
                    : Icon(
                        Icons.card_giftcard,
                        size: widget.size * 0.5,
                        color: color,
                      ),
          ),
        ),

        if (widget.showName || widget.showCount) const SizedBox(height: 8),

        // 이름
        if (widget.showName)
          Text(
            widget.item.name,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

        // 수량
        if (widget.showCount && widget.item.count > 1)
          Text(
            'x${widget.item.count}',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

/// 다중 보상 프레젠터 (상자 열기 등)
class MGRewardPresenter extends StatefulWidget {
  final List<RewardItem> items;
  final Duration staggerDelay;
  final VoidCallback? onAllComplete;
  final bool showSequentially;
  final int itemsPerRow;
  final double itemSize;

  const MGRewardPresenter({
    super.key,
    required this.items,
    this.staggerDelay = const Duration(milliseconds: 150),
    this.onAllComplete,
    this.showSequentially = true,
    this.itemsPerRow = 4,
    this.itemSize = 80,
  });

  @override
  State<MGRewardPresenter> createState() => _MGRewardPresenterState();
}

class _MGRewardPresenterState extends State<MGRewardPresenter> {
  int _completedCount = 0;

  void _onItemComplete() {
    _completedCount++;
    if (_completedCount >= widget.items.length) {
      widget.onAllComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 희귀도순 정렬 (높은 희귀도가 먼저)
    final sortedItems = List<RewardItem>.from(widget.items)
      ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < sortedItems.length; i++)
          MGRewardItemPresenter(
            item: sortedItems[i],
            delay: widget.showSequentially
                ? widget.staggerDelay * i
                : Duration.zero,
            onComplete: _onItemComplete,
            size: widget.itemSize,
          ),
      ],
    );
  }
}

/// 상자 열기 연출
class MGChestOpenPresenter extends StatefulWidget {
  final List<RewardItem> rewards;
  final String? chestImagePath;
  final VoidCallback? onComplete;

  const MGChestOpenPresenter({
    super.key,
    required this.rewards,
    this.chestImagePath,
    this.onComplete,
  });

  @override
  State<MGChestOpenPresenter> createState() => _MGChestOpenPresenterState();
}

class _MGChestOpenPresenterState extends State<MGChestOpenPresenter>
    with TickerProviderStateMixin {
  late AnimationController _chestController;
  late AnimationController _lightController;
  late Animation<double> _chestShake;
  late Animation<double> _chestOpen;
  late Animation<double> _lightBurst;

  bool _showRewards = false;

  @override
  void initState() {
    super.initState();

    _chestController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _lightController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 상자 흔들림
    _chestShake = TweenSequence<double>([
      for (int i = 0; i < 6; i++) ...[
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: (i % 2 == 0 ? 1 : -1) * (5 - i * 0.5)),
          weight: 1,
        ),
      ],
    ]).animate(CurvedAnimation(
      parent: _chestController,
      curve: const Interval(0.0, 0.5),
    ));

    // 상자 열기 (스케일)
    _chestOpen = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(
      parent: _chestController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInBack),
    ));

    // 빛 효과
    _lightBurst = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lightController, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    _chestController.forward();

    _chestController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        _lightController.forward();
        setState(() => _showRewards = true);
      }
    });
  }

  @override
  void dispose() {
    _chestController.dispose();
    _lightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 빛 효과
        AnimatedBuilder(
          animation: _lightController,
          builder: (context, _) {
            return Container(
              width: 300 * _lightBurst.value,
              height: 300 * _lightBurst.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.yellow.withOpacity(0.6 * (1 - _lightBurst.value)),
                    Colors.orange.withOpacity(0.3 * (1 - _lightBurst.value)),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),

        // 상자 또는 보상
        if (!_showRewards)
          AnimatedBuilder(
            animation: _chestController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_chestShake.value, 0),
                child: Transform.scale(
                  scale: _chestOpen.value,
                  child: child,
                ),
              );
            },
            child: _buildChest(),
          )
        else
          MGRewardPresenter(
            items: widget.rewards,
            onAllComplete: widget.onComplete,
          ),
      ],
    );
  }

  Widget _buildChest() {
    if (widget.chestImagePath != null) {
      return Image.asset(
        widget.chestImagePath!,
        width: 120,
        height: 120,
        errorBuilder: (_, __, ___) => _buildDefaultChest(),
      );
    }
    return _buildDefaultChest();
  }

  Widget _buildDefaultChest() {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.brown.shade700,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.lock_open,
        color: Colors.amber,
        size: 40,
      ),
    );
  }
}

/// 코인/재화 획득 연출 (숫자 카운트업)
class MGCurrencyGainPresenter extends StatefulWidget {
  final int amount;
  final String currencyName;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const MGCurrencyGainPresenter({
    super.key,
    required this.amount,
    this.currencyName = '',
    this.icon = Icons.monetization_on,
    this.color = Colors.amber,
    this.duration = const Duration(milliseconds: 1500),
    this.onComplete,
  });

  @override
  State<MGCurrencyGainPresenter> createState() => _MGCurrencyGainPresenterState();
}

class _MGCurrencyGainPresenterState extends State<MGCurrencyGainPresenter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _countAnimation = Tween<double>(begin: 0, end: widget.amount.toDouble())
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 80),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 40),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+${_countAnimation.value.toInt()}',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.currencyName.isNotEmpty)
                    Text(
                      widget.currencyName,
                      style: TextStyle(
                        color: widget.color.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 레벨업 연출
class MGLevelUpPresenter extends StatefulWidget {
  final int newLevel;
  final VoidCallback? onComplete;

  const MGLevelUpPresenter({
    super.key,
    required this.newLevel,
    this.onComplete,
  });

  @override
  State<MGLevelUpPresenter> createState() => _MGLevelUpPresenterState();
}

class _MGLevelUpPresenterState extends State<MGLevelUpPresenter>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_mainController);

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    HapticFeedback.heavyImpact();
    _mainController.forward();
    _glowController.repeat(reverse: true);

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _glowController]),
      builder: (context, _) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LEVEL UP 텍스트
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(
                            _glowAnimation.value * 0.6,
                          ),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Colors.orange,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 레벨 숫자
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Text(
                      'Lv.${widget.newLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
