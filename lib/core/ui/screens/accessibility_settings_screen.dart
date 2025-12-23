import 'package:flutter/material.dart';
import '../accessibility/accessibility_settings.dart';
import '../accessibility/colorblind_colors.dart';
import '../layout/mg_spacing.dart';

/// MG-Games 접근성 설정 화면
/// ACCESSIBILITY_GUIDE.md 기반
class MGAccessibilitySettingsScreen extends StatefulWidget {
  final MGAccessibilitySettings initialSettings;
  final void Function(MGAccessibilitySettings) onSettingsChanged;

  const MGAccessibilitySettingsScreen({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<MGAccessibilitySettingsScreen> createState() =>
      _MGAccessibilitySettingsScreenState();
}

class _MGAccessibilitySettingsScreenState
    extends State<MGAccessibilitySettingsScreen> {
  late MGAccessibilitySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _updateSettings(MGAccessibilitySettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('접근성 설정'),
      ),
      body: ListView(
        padding: MGSpacing.all(MGSpacing.md),
        children: [
          _buildPresetSection(),
          MGSpacing.vLg,
          _buildVisualSection(),
          MGSpacing.vLg,
          _buildAudioSection(),
          MGSpacing.vLg,
          _buildMotorSection(),
          MGSpacing.vLg,
          _buildCognitiveSection(),
          MGSpacing.vLg,
          _buildHapticSection(),
        ],
      ),
    );
  }

  Widget _buildPresetSection() {
    return _SettingsSection(
      title: '빠른 설정',
      children: [
        Wrap(
          spacing: MGSpacing.xs,
          runSpacing: MGSpacing.xs,
          children: [
            _PresetButton(
              label: '기본 설정',
              onPressed: () =>
                  _updateSettings(MGAccessibilitySettings.defaults),
            ),
            _PresetButton(
              label: '저시력',
              onPressed: () =>
                  _updateSettings(MGAccessibilitySettings.lowVision),
            ),
            _PresetButton(
              label: '청각 장애',
              onPressed: () => _updateSettings(MGAccessibilitySettings.deaf),
            ),
            _PresetButton(
              label: '운동 장애',
              onPressed: () =>
                  _updateSettings(MGAccessibilitySettings.motorImpaired),
            ),
            _PresetButton(
              label: '인지 장애',
              onPressed: () =>
                  _updateSettings(MGAccessibilitySettings.cognitiveImpaired),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisualSection() {
    return _SettingsSection(
      title: '시각 접근성',
      children: [
        // 색맹 모드
        SwitchListTile(
          title: const Text('색맹 모드'),
          subtitle: const Text('색상을 구분하기 쉽게 조정'),
          value: _settings.colorBlindModeEnabled,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(colorBlindModeEnabled: value),
          ),
        ),
        if (_settings.colorBlindModeEnabled)
          ListTile(
            title: const Text('색맹 유형'),
            trailing: DropdownButton<ColorBlindType>(
              value: _settings.colorBlindType,
              onChanged: (value) => _updateSettings(
                _settings.copyWith(colorBlindType: value),
              ),
              items: ColorBlindType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
            ),
          ),

        // 고대비 모드
        SwitchListTile(
          title: const Text('고대비 모드'),
          subtitle: const Text('텍스트와 배경의 대비를 높임'),
          value: _settings.highContrastEnabled,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(highContrastEnabled: value),
          ),
        ),

        // 텍스트 크기
        ListTile(
          title: const Text('텍스트 크기'),
          subtitle: Text(_settings.textScaleOption.displayName),
          trailing: DropdownButton<TextScaleOption>(
            value: _settings.textScaleOption,
            onChanged: (value) => _updateSettings(
              _settings.copyWith(textScaleOption: value),
            ),
            items: TextScaleOption.values.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option.displayName),
              );
            }).toList(),
          ),
        ),

        // 모션 줄이기
        SwitchListTile(
          title: const Text('모션 줄이기'),
          subtitle: const Text('애니메이션 효과 감소'),
          value: _settings.reduceMotion,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(reduceMotion: value),
          ),
        ),

        // 깜빡임 줄이기
        SwitchListTile(
          title: const Text('깜빡임 효과 줄이기'),
          subtitle: const Text('번쩍이는 효과 비활성화'),
          value: _settings.reduceFlashing,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(reduceFlashing: value),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSection() {
    return _SettingsSection(
      title: '청각 접근성',
      children: [
        // 자막
        SwitchListTile(
          title: const Text('자막'),
          subtitle: const Text('대화 및 효과음 자막 표시'),
          value: _settings.subtitlesEnabled,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(subtitlesEnabled: value),
          ),
        ),
        if (_settings.subtitlesEnabled) ...[
          ListTile(
            title: const Text('자막 크기'),
            trailing: DropdownButton<SubtitleSize>(
              value: _settings.subtitleSize,
              onChanged: (value) => _updateSettings(
                _settings.copyWith(subtitleSize: value),
              ),
              items: SubtitleSize.values.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size.displayName),
                );
              }).toList(),
            ),
          ),
          SwitchListTile(
            title: const Text('자막 배경'),
            subtitle: const Text('자막 가독성을 위한 배경 표시'),
            value: _settings.subtitleBackgroundEnabled,
            onChanged: (value) => _updateSettings(
              _settings.copyWith(subtitleBackgroundEnabled: value),
            ),
          ),
          SwitchListTile(
            title: const Text('화자 구분'),
            subtitle: const Text('누가 말하는지 표시'),
            value: _settings.speakerIndicatorEnabled,
            onChanged: (value) => _updateSettings(
              _settings.copyWith(speakerIndicatorEnabled: value),
            ),
          ),
        ],

        // 시각적 효과음
        SwitchListTile(
          title: const Text('시각적 효과음'),
          subtitle: const Text('소리를 시각적 효과로 표시'),
          value: _settings.visualSoundEffects,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(visualSoundEffects: value),
          ),
        ),
      ],
    );
  }

  Widget _buildMotorSection() {
    return _SettingsSection(
      title: '운동 접근성',
      children: [
        // 터치 영역 크기
        ListTile(
          title: const Text('터치 영역 크기'),
          subtitle: Text(_settings.touchAreaSize.displayName),
          trailing: DropdownButton<TouchAreaSize>(
            value: _settings.touchAreaSize,
            onChanged: (value) => _updateSettings(
              _settings.copyWith(touchAreaSize: value),
            ),
            items: TouchAreaSize.values.map((size) {
              return DropdownMenuItem(
                value: size,
                child: Text(size.displayName),
              );
            }).toList(),
          ),
        ),

        // 한손 모드
        SwitchListTile(
          title: const Text('한손 모드'),
          subtitle: const Text('한손으로 조작하기 쉽게 UI 배치'),
          value: _settings.oneHandedMode,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(oneHandedMode: value),
          ),
        ),
        if (_settings.oneHandedMode)
          SwitchListTile(
            title: const Text('오른손 사용'),
            subtitle: const Text('끄면 왼손 모드'),
            value: _settings.oneHandedModeRightHand,
            onChanged: (value) => _updateSettings(
              _settings.copyWith(oneHandedModeRightHand: value),
            ),
          ),

        // 길게 누르기 대체
        SwitchListTile(
          title: const Text('길게 누르기 대체'),
          subtitle: const Text('길게 누르기를 더블탭으로 대체'),
          value: _settings.replaceLongPress,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(replaceLongPress: value),
          ),
        ),

        // 드래그 대체
        SwitchListTile(
          title: const Text('드래그 대체'),
          subtitle: const Text('드래그를 탭으로 대체'),
          value: _settings.replaceDrag,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(replaceDrag: value),
          ),
        ),

        // 연속 탭 간격
        ListTile(
          title: const Text('연속 탭 간격'),
          subtitle: Text('${_settings.multiTapInterval}ms'),
          trailing: SizedBox(
            width: 150,
            child: Slider(
              value: _settings.multiTapInterval.toDouble(),
              min: 200,
              max: 600,
              divisions: 8,
              label: '${_settings.multiTapInterval}ms',
              onChanged: (value) => _updateSettings(
                _settings.copyWith(multiTapInterval: value.round()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCognitiveSection() {
    return _SettingsSection(
      title: '인지 접근성',
      children: [
        // QTE 타이밍 조절
        ListTile(
          title: const Text('QTE 타이밍'),
          subtitle: Text('${(_settings.qteTimingMultiplier * 100).round()}%'),
          trailing: SizedBox(
            width: 150,
            child: Slider(
              value: _settings.qteTimingMultiplier,
              min: 1.0,
              max: 3.0,
              divisions: 8,
              label: '${(_settings.qteTimingMultiplier * 100).round()}%',
              onChanged: (value) => _updateSettings(
                _settings.copyWith(qteTimingMultiplier: value),
              ),
            ),
          ),
        ),

        // 타이밍 허용 오차
        ListTile(
          title: const Text('타이밍 허용 오차'),
          subtitle:
              Text('${(_settings.timingToleranceMultiplier * 100).round()}%'),
          trailing: SizedBox(
            width: 150,
            child: Slider(
              value: _settings.timingToleranceMultiplier,
              min: 1.0,
              max: 3.0,
              divisions: 8,
              label: '${(_settings.timingToleranceMultiplier * 100).round()}%',
              onChanged: (value) => _updateSettings(
                _settings.copyWith(timingToleranceMultiplier: value),
              ),
            ),
          ),
        ),

        // 자동 일시정지
        SwitchListTile(
          title: const Text('자동 일시정지'),
          subtitle: const Text('입력 없을 시 게임 자동 일시정지'),
          value: _settings.autoPauseEnabled,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(autoPauseEnabled: value),
          ),
        ),

        // 단순화 UI
        SwitchListTile(
          title: const Text('단순화 UI'),
          subtitle: const Text('복잡한 UI 요소 간소화'),
          value: _settings.simplifiedUIEnabled,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(simplifiedUIEnabled: value),
          ),
        ),

        // 상세 튜토리얼
        SwitchListTile(
          title: const Text('상세 튜토리얼'),
          subtitle: const Text('더 자세한 설명 제공'),
          value: _settings.detailedTutorials,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(detailedTutorials: value),
          ),
        ),
      ],
    );
  }

  Widget _buildHapticSection() {
    return _SettingsSection(
      title: '진동 피드백',
      children: [
        SwitchListTile(
          title: const Text('진동 피드백'),
          subtitle: const Text('터치 반응 진동'),
          value: _settings.hapticFeedbackEnabled,
          onChanged: (value) => _updateSettings(
            _settings.copyWith(hapticFeedbackEnabled: value),
          ),
        ),
        if (_settings.hapticFeedbackEnabled)
          ListTile(
            title: const Text('진동 강도'),
            subtitle: Text('${(_settings.hapticIntensity * 100).round()}%'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: _settings.hapticIntensity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_settings.hapticIntensity * 100).round()}%',
                onChanged: (value) => _updateSettings(
                  _settings.copyWith(hapticIntensity: value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 설정 섹션 위젯
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MGSpacing.md,
            vertical: MGSpacing.xs,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

/// 프리셋 버튼
class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PresetButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
