import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// 프로그레스 쇼케이스 페이지
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  double _progressValue = 0.6;
  double _hpValue = 75;
  double _expValue = 450;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로그레스')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('선형 프로그레스'),
          MGLinearProgress(value: _progressValue),
          MGSpacing.vMd,
          MGLinearProgress(
            value: _progressValue,
            showLabel: true,
            label: '다운로드',
          ),
          MGSpacing.vMd,
          Slider(
            value: _progressValue,
            onChanged: (v) => setState(() => _progressValue = v),
          ),
          MGSpacing.vLg,
          _buildSection('HP 바'),
          MGHpBar(
            current: _hpValue,
            max: 100,
            showLabel: true,
            showNumbers: true,
          ),
          MGSpacing.vMd,
          Row(
            children: [
              const Text('HP: '),
              Expanded(
                child: Slider(
                  value: _hpValue,
                  min: 0,
                  max: 100,
                  onChanged: (v) => setState(() => _hpValue = v),
                ),
              ),
            ],
          ),
          MGSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: MGHpBar(
                  current: 80,
                  max: 100,
                  height: 8,
                ),
              ),
              MGSpacing.hMd,
              Expanded(
                child: MGHpBar(
                  current: 25,
                  max: 100,
                  height: 8,
                ),
              ),
              MGSpacing.hMd,
              Expanded(
                child: MGHpBar(
                  current: 10,
                  max: 100,
                  height: 8,
                ),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('경험치 바'),
          MGExpBar(
            current: _expValue,
            max: 1000,
            level: 15,
          ),
          MGSpacing.vMd,
          Slider(
            value: _expValue,
            min: 0,
            max: 1000,
            onChanged: (v) => setState(() => _expValue = v),
          ),
          MGSpacing.vLg,
          _buildSection('원형 프로그레스'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MGCircularProgress(
                value: 0.75,
                showPercent: true,
              ),
              MGCircularProgress(
                value: 0.5,
                center: const Icon(Icons.star),
              ),
              MGTimerProgress(
                value: 0.3,
                child: const Text('30s'),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('자원 바'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MGResourceBar(
                icon: Icons.monetization_on,
                value: '12,500',
                iconColor: MGColors.gold,
              ),
              MGResourceBar(
                icon: Icons.diamond,
                value: '350',
                iconColor: MGColors.gem,
              ),
              MGResourceBar(
                icon: Icons.bolt,
                value: '50/100',
                iconColor: MGColors.energy,
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('타이머 프로그레스 (경고)'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MGTimerProgress(
                value: 0.8,
                child: const Text('OK'),
              ),
              MGTimerProgress(
                value: 0.9,
                child: const Text('!'),
              ),
              MGTimerProgress(
                value: 0.95,
                child: const Text('!!'),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
