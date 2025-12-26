import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// MG Games 이미지 유틸리티
/// 이미지 로딩, 캐싱, 효과 적용 등
class MGImageUtils {
  MGImageUtils._();

  static final Map<String, ui.Image> _imageCache = {};

  /// 에셋 이미지 로드 (캐싱 포함)
  static Future<ui.Image> loadAssetImage(String assetPath) async {
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath]!;
    }

    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;

    _imageCache[assetPath] = image;
    return image;
  }

  /// 캐시 클리어
  static void clearCache() {
    for (final image in _imageCache.values) {
      image.dispose();
    }
    _imageCache.clear();
  }

  /// 특정 이미지 캐시 제거
  static void removeFromCache(String assetPath) {
    _imageCache[assetPath]?.dispose();
    _imageCache.remove(assetPath);
  }

  /// 이미지에 색상 오버레이 적용
  static ColorFilter colorOverlay(Color color, [BlendMode mode = BlendMode.srcATop]) {
    return ColorFilter.mode(color, mode);
  }

  /// 그레이스케일 필터
  static const ColorFilter grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  /// 세피아 필터
  static const ColorFilter sepia = ColorFilter.matrix(<double>[
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  /// 반전 필터
  static const ColorFilter invert = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ]);

  /// 밝기 조절 필터
  static ColorFilter brightness(double value) {
    final v = (value * 255).clamp(-255, 255).toDouble();
    return ColorFilter.matrix(<double>[
      1, 0, 0, 0, v,
      0, 1, 0, 0, v,
      0, 0, 1, 0, v,
      0, 0, 0, 1, 0,
    ]);
  }

  /// 대비 조절 필터
  static ColorFilter contrast(double value) {
    final f = (value + 1) * 128;
    final t = 128 * (1 - value);
    return ColorFilter.matrix(<double>[
      f / 128, 0, 0, 0, t,
      0, f / 128, 0, 0, t,
      0, 0, f / 128, 0, t,
      0, 0, 0, 1, 0,
    ]);
  }

  /// 채도 조절 필터
  static ColorFilter saturation(double value) {
    final s = value + 1;
    final sr = (1 - s) * 0.3086;
    final sg = (1 - s) * 0.6094;
    final sb = (1 - s) * 0.0820;
    return ColorFilter.matrix(<double>[
      sr + s, sg, sb, 0, 0,
      sr, sg + s, sb, 0, 0,
      sr, sg, sb + s, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }
}

/// 투명 배경 이미지 위젯 (에셋 로드 최적화)
class MGTransparentImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final ColorFilter? colorFilter;
  final Widget? placeholder;
  final Widget? errorWidget;

  const MGTransparentImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode,
    this.colorFilter,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode ?? (color != null ? BlendMode.srcIn : null),
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade800,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return colorFilter != null
              ? ColorFiltered(colorFilter: colorFilter!, child: child)
              : child;
        }
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade900,
            );
      },
    );
  }
}

/// 실루엣 이미지 (색상만 표시)
class MGSilhouetteImage extends StatelessWidget {
  final String assetPath;
  final Color color;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MGSilhouetteImage({
    super.key,
    required this.assetPath,
    this.color = Colors.black,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return MGTransparentImage(
      assetPath: assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: BlendMode.srcIn,
    );
  }
}

/// 글로우 이미지 (외곽선 발광 효과)
class MGGlowImage extends StatelessWidget {
  final String assetPath;
  final Color glowColor;
  final double glowRadius;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MGGlowImage({
    super.key,
    required this.assetPath,
    this.glowColor = Colors.white,
    this.glowRadius = 10.0,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 글로우 레이어 (블러 처리된 실루엣)
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: glowRadius,
            sigmaY: glowRadius,
          ),
          child: MGSilhouetteImage(
            assetPath: assetPath,
            color: glowColor,
            width: width,
            height: height,
            fit: fit,
          ),
        ),
        // 원본 이미지
        MGTransparentImage(
          assetPath: assetPath,
          width: width,
          height: height,
          fit: fit,
        ),
      ],
    );
  }
}

/// 아웃라인 이미지 (외곽선만)
class MGOutlineImage extends StatelessWidget {
  final String assetPath;
  final Color outlineColor;
  final double outlineWidth;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MGOutlineImage({
    super.key,
    required this.assetPath,
    this.outlineColor = Colors.white,
    this.outlineWidth = 2.0,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final offsets = [
      Offset(-outlineWidth, 0),
      Offset(outlineWidth, 0),
      Offset(0, -outlineWidth),
      Offset(0, outlineWidth),
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        // 외곽선 레이어들
        for (final offset in offsets)
          Transform.translate(
            offset: offset,
            child: MGSilhouetteImage(
              assetPath: assetPath,
              color: outlineColor,
              width: width,
              height: height,
              fit: fit,
            ),
          ),
        // 원본 이미지
        MGTransparentImage(
          assetPath: assetPath,
          width: width,
          height: height,
          fit: fit,
        ),
      ],
    );
  }
}

/// 펄스 글로우 이미지 (애니메이션)
class MGPulseGlowImage extends StatefulWidget {
  final String assetPath;
  final Color glowColor;
  final double minGlow;
  final double maxGlow;
  final Duration duration;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MGPulseGlowImage({
    super.key,
    required this.assetPath,
    this.glowColor = Colors.white,
    this.minGlow = 5.0,
    this.maxGlow = 15.0,
    this.duration = const Duration(milliseconds: 1000),
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  State<MGPulseGlowImage> createState() => _MGPulseGlowImageState();
}

class _MGPulseGlowImageState extends State<MGPulseGlowImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minGlow,
      end: widget.maxGlow,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return MGGlowImage(
          assetPath: widget.assetPath,
          glowColor: widget.glowColor,
          glowRadius: _animation.value,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }
}

/// 셰이더 마스크 이미지 (그라데이션 페이드)
class MGFadeImage extends StatelessWidget {
  final String assetPath;
  final FadeDirection direction;
  final double fadeRatio;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MGFadeImage({
    super.key,
    required this.assetPath,
    this.direction = FadeDirection.bottom,
    this.fadeRatio = 0.3,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    Alignment begin, end;

    switch (direction) {
      case FadeDirection.top:
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        break;
      case FadeDirection.bottom:
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
        break;
      case FadeDirection.left:
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        break;
      case FadeDirection.right:
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
        break;
    }

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: begin,
          end: end,
          colors: const [Colors.transparent, Colors.white],
          stops: [0.0, fadeRatio],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: MGTransparentImage(
        assetPath: assetPath,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}

enum FadeDirection { top, bottom, left, right }

/// 스프라이트 시트 유틸리티
class MGSpriteSheet {
  final String assetPath;
  final int columns;
  final int rows;
  final double frameWidth;
  final double frameHeight;

  const MGSpriteSheet({
    required this.assetPath,
    required this.columns,
    required this.rows,
    required this.frameWidth,
    required this.frameHeight,
  });

  int get totalFrames => columns * rows;

  /// 특정 프레임의 Rect 반환
  Rect getFrameRect(int frameIndex) {
    final col = frameIndex % columns;
    final row = frameIndex ~/ columns;
    return Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );
  }
}

/// 스프라이트 시트 애니메이션 위젯
class MGSpriteAnimation extends StatefulWidget {
  final MGSpriteSheet spriteSheet;
  final Duration frameDuration;
  final bool loop;
  final int? startFrame;
  final int? endFrame;
  final VoidCallback? onComplete;
  final double? width;
  final double? height;

  const MGSpriteAnimation({
    super.key,
    required this.spriteSheet,
    this.frameDuration = const Duration(milliseconds: 100),
    this.loop = true,
    this.startFrame,
    this.endFrame,
    this.onComplete,
    this.width,
    this.height,
  });

  @override
  State<MGSpriteAnimation> createState() => _MGSpriteAnimationState();
}

class _MGSpriteAnimationState extends State<MGSpriteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentFrame = 0;

  int get _startFrame => widget.startFrame ?? 0;
  int get _endFrame => widget.endFrame ?? widget.spriteSheet.totalFrames - 1;
  int get _frameCount => _endFrame - _startFrame + 1;

  @override
  void initState() {
    super.initState();
    _currentFrame = _startFrame;

    _controller = AnimationController(
      duration: widget.frameDuration * _frameCount,
      vsync: this,
    );

    _controller.addListener(() {
      final frame = (_controller.value * _frameCount).floor();
      final newFrame = (_startFrame + frame).clamp(_startFrame, _endFrame);
      if (newFrame != _currentFrame) {
        setState(() => _currentFrame = newFrame);
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.loop) {
          _controller.reset();
          _controller.forward();
        } else {
          widget.onComplete?.call();
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rect = widget.spriteSheet.getFrameRect(_currentFrame);

    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        widthFactor: 1 / widget.spriteSheet.columns,
        heightFactor: 1 / widget.spriteSheet.rows,
        child: Transform.translate(
          offset: Offset(-rect.left, -rect.top),
          child: Image.asset(
            widget.spriteSheet.assetPath,
            width: widget.width != null
                ? widget.width! * widget.spriteSheet.columns
                : null,
            height: widget.height != null
                ? widget.height! * widget.spriteSheet.rows
                : null,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
