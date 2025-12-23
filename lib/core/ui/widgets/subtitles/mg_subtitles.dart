import 'package:flutter/material.dart';
import '../../accessibility/accessibility_settings.dart';

/// MG-Games 자막 위젯
/// ACCESSIBILITY_GUIDE.md 기반

/// 자막 표시 위젯
class MGSubtitle extends StatelessWidget {
  final String text;
  final String? speaker;
  final Color? speakerColor;
  final SubtitleSize? size;
  final bool showBackground;
  final TextAlign textAlign;

  const MGSubtitle({
    super.key,
    required this.text,
    this.speaker,
    this.speakerColor,
    this.size,
    this.showBackground = true,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    final effectiveSize = size ?? settings.subtitleSize;
    final effectiveShowBackground =
        showBackground && settings.subtitleBackgroundEnabled;
    final showSpeaker = speaker != null && settings.speakerIndicatorEnabled;

    Widget subtitleContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (showSpeaker)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              speaker!,
              style: TextStyle(
                color: speakerColor ?? Colors.cyan,
                fontSize: effectiveSize.fontSize * 0.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: effectiveSize.fontSize,
            fontWeight: FontWeight.w500,
            shadows: effectiveShowBackground
                ? null
                : const [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black,
                    ),
                  ],
          ),
          textAlign: textAlign,
        ),
      ],
    );

    if (effectiveShowBackground) {
      subtitleContent = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: subtitleContent,
      );
    }

    return subtitleContent;
  }
}

/// 자막 오버레이 위젯
class MGSubtitleOverlay extends StatelessWidget {
  final Widget child;
  final String? currentSubtitle;
  final String? speaker;
  final Color? speakerColor;
  final bool visible;
  final Alignment alignment;
  final EdgeInsets padding;

  const MGSubtitleOverlay({
    super.key,
    required this.child,
    this.currentSubtitle,
    this.speaker,
    this.speakerColor,
    this.visible = true,
    this.alignment = Alignment.bottomCenter,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);

    if (!settings.subtitlesEnabled || !visible || currentSubtitle == null) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: SafeArea(
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: padding,
                child: MGSubtitle(
                  text: currentSubtitle!,
                  speaker: speaker,
                  speakerColor: speakerColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 자막 컨트롤러
class MGSubtitleController extends ChangeNotifier {
  String? _currentText;
  String? _currentSpeaker;
  Color? _speakerColor;
  bool _isVisible = true;
  final List<SubtitleEntry> _queue = [];

  String? get currentText => _currentText;
  String? get currentSpeaker => _currentSpeaker;
  Color? get speakerColor => _speakerColor;
  bool get isVisible => _isVisible;

  /// 자막 표시
  void show({
    required String text,
    String? speaker,
    Color? speakerColor,
    Duration? duration,
  }) {
    _currentText = text;
    _currentSpeaker = speaker;
    _speakerColor = speakerColor;
    _isVisible = true;
    notifyListeners();

    if (duration != null) {
      Future.delayed(duration, hide);
    }
  }

  /// 자막 숨기기
  void hide() {
    _isVisible = false;
    notifyListeners();
  }

  /// 자막 지우기
  void clear() {
    _currentText = null;
    _currentSpeaker = null;
    _speakerColor = null;
    _isVisible = false;
    notifyListeners();
  }

  /// 큐에 자막 추가
  void queue(SubtitleEntry entry) {
    _queue.add(entry);
    if (_queue.length == 1) {
      _playNext();
    }
  }

  void _playNext() {
    if (_queue.isEmpty) {
      clear();
      return;
    }

    final entry = _queue.first;
    show(
      text: entry.text,
      speaker: entry.speaker,
      speakerColor: entry.speakerColor,
    );

    Future.delayed(entry.duration, () {
      _queue.removeAt(0);
      _playNext();
    });
  }

  /// 큐 비우기
  void clearQueue() {
    _queue.clear();
    clear();
  }
}

/// 자막 항목
class SubtitleEntry {
  final String text;
  final String? speaker;
  final Color? speakerColor;
  final Duration duration;

  const SubtitleEntry({
    required this.text,
    this.speaker,
    this.speakerColor,
    this.duration = const Duration(seconds: 3),
  });
}

/// 자막 컨트롤러 빌더
class MGSubtitleBuilder extends StatelessWidget {
  final MGSubtitleController controller;
  final Widget Function(
    BuildContext context,
    String? text,
    String? speaker,
    Color? speakerColor,
    bool isVisible,
  ) builder;

  const MGSubtitleBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return builder(
          context,
          controller.currentText,
          controller.currentSpeaker,
          controller.speakerColor,
          controller.isVisible,
        );
      },
    );
  }
}

/// 효과음 자막 (청각 장애 지원)
class MGSoundSubtitle extends StatelessWidget {
  final String sound;
  final IconData? icon;
  final Color? color;

  const MGSoundSubtitle({
    super.key,
    required this.sound,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);

    if (!settings.visualSoundEffects) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: color ?? Colors.white70),
          if (icon != null) const SizedBox(width: 6),
          Text(
            '[$sound]',
            style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// 화자별 색상 맵
class MGSpeakerColors {
  MGSpeakerColors._();

  static const Map<String, Color> defaultColors = {
    '플레이어': Colors.cyan,
    '나레이터': Colors.white,
    'NPC': Colors.lightGreen,
    '적': Colors.red,
    '보스': Colors.purple,
    '시스템': Colors.yellow,
  };

  static Color getColor(String speaker, [Map<String, Color>? customColors]) {
    if (customColors != null && customColors.containsKey(speaker)) {
      return customColors[speaker]!;
    }
    if (defaultColors.containsKey(speaker)) {
      return defaultColors[speaker]!;
    }
    // 해시 기반 색상 생성
    final hash = speaker.hashCode;
    return HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.7, 0.7).toColor();
  }
}
