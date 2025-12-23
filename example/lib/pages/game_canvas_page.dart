import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// 게임 캔버스 쇼케이스 페이지
class GameCanvasPage extends StatefulWidget {
  const GameCanvasPage({super.key});

  @override
  State<GameCanvasPage> createState() => _GameCanvasPageState();
}

class _GameCanvasPageState extends State<GameCanvasPage> {
  bool _showPauseMenu = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게임 캔버스')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('타워 디펜스 HUD'),
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: MGTowerDefenseCanvas(
                gameContent: _buildGameArea(),
                waveInfo: _buildWaveInfo(),
                resourceBar: _buildResourceBar(),
                towerSelection: _buildTowerSelection(),
                speedControl: _buildSpeedControl(),
                pauseMenu: _showPauseMenu ? _buildPauseMenu() : null,
              ),
            ),
          ),
          MGSpacing.vMd,
          MGButton.secondary(
            label: _showPauseMenu ? '일시정지 메뉴 숨기기' : '일시정지 메뉴 표시',
            onPressed: () => setState(() => _showPauseMenu = !_showPauseMenu),
          ),
          MGSpacing.vLg,
          _buildSection('기본 게임 캔버스'),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: MGGameCanvas(
                gameContent: _buildGameArea(),
                topHud: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHudBox('점수: 12,500'),
                    _buildHudBox('Lv.15'),
                  ],
                ),
                bottomHud: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.inventory_2),
                    _buildActionButton(Icons.map),
                    _buildActionButton(Icons.settings),
                  ],
                ),
              ),
            ),
          ),
          MGSpacing.vLg,
          _buildSection('HUD 위치'),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: MGFreeformCanvas(
                gameContent: _buildGameArea(),
                hudElements: [
                  MGHudElement(
                    position: HudPosition.topLeft,
                    child: _buildHudBox('좌상'),
                  ),
                  MGHudElement(
                    position: HudPosition.topCenter,
                    child: _buildHudBox('중앙상'),
                  ),
                  MGHudElement(
                    position: HudPosition.topRight,
                    child: _buildHudBox('우상'),
                  ),
                  MGHudElement(
                    position: HudPosition.bottomLeft,
                    child: _buildHudBox('좌하'),
                  ),
                  MGHudElement(
                    position: HudPosition.bottomCenter,
                    child: _buildHudBox('중앙하'),
                  ),
                  MGHudElement(
                    position: HudPosition.bottomRight,
                    child: _buildHudBox('우하'),
                  ),
                ],
              ),
            ),
          ),
          MGSpacing.vLg,
          _buildSection('Safe Area 유틸리티'),
          Text('현재 화면 패딩:'),
          MGSpacing.vSm,
          Builder(
            builder: (context) {
              final padding = MediaQuery.of(context).padding;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top: ${padding.top.toStringAsFixed(1)}'),
                  Text('Bottom: ${padding.bottom.toStringAsFixed(1)}'),
                  Text('Left: ${padding.left.toStringAsFixed(1)}'),
                  Text('Right: ${padding.right.toStringAsFixed(1)}'),
                ],
              );
            },
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

  Widget _buildGameArea() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[800]!,
            Colors.green[600]!,
          ],
        ),
      ),
      child: const Center(
        child: Text(
          '게임 영역',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildWaveInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waves, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Wave 5/20',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MGResourceBar(
          icon: Icons.monetization_on,
          value: '1,250',
          iconColor: MGColors.gold,
        ),
        MGSpacing.hXs,
        MGResourceBar(
          icon: Icons.favorite,
          value: '20',
          iconColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildTowerSelection() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTowerButton('🏰', '기본', 100),
          _buildTowerButton('🔥', '화염', 200),
          _buildTowerButton('❄️', '얼음', 200),
          _buildTowerButton('⚡', '전기', 300),
          _buildTowerButton('☠️', '독', 250),
        ],
      ),
    );
  }

  Widget _buildTowerButton(String emoji, String name, int cost) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Text(
            '$cost',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControl() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fast_forward, color: Colors.white, size: 20),
          SizedBox(height: 4),
          Text(
            '2x',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseMenu() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '일시정지',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => _showPauseMenu = false),
                child: const Text('계속하기'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {},
                child: const Text('설정'),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('종료'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHudBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
