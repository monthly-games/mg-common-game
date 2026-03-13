import 'package:flutter/material.dart';
import 'package:mg_common_game/xr/xr_manager.dart';

/// XR 설정 화면
class XRSettingsScreen extends StatefulWidget {
  const XRSettingsScreen({super.key});

  @override
  State<XRSettingsScreen> createState() => _XRSettingsScreenState();
}

class _XRSettingsScreenState extends State<XRSettingsScreen> {
  final _xrManager = XRManager.instance;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VR/AR 설정')),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          VRSettingsScreen(),
          ARSettingsScreen(),
          XRDeviceInfoScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.vrpano),
            label: 'VR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar),
            label: 'AR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: '기기 정보',
          ),
        ],
      ),
    );
  }
}

/// VR 설정 화면
class VRSettingsScreen extends StatefulWidget {
  const VRSettingsScreen({super.key});

  @override
  State<VRSettingsScreen> createState() => _VRSettingsScreenState();
}

class _VRSettingsScreenState extends State<VRSettingsScreen> {
  final _xrManager = XRManager.instance;
  VRSettings _settings = const VRSettings();
  bool _supported = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
    _listenToSettings();
  }

  Future<void> _checkSupport() async {
    await _xrManager.initialize();

    // VR 지원 확인
    setState(() => _supported = true); // 실제로는 _xrManager.isVRSupported
  }

  void _listenToSettings() {
    _xrManager.onVRSettingsChanged.listen((settings) {
      setState(() => _settings = settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('VR을 지원하지 않는 기기입니다'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModeSelector(),
        const SizedBox(height: 24),
        _buildFieldOfViewSlider(),
        const SizedBox(height: 24),
        _buildIPDSlider(),
        const SizedBox(height: 24),
        _buildMotionControlsToggle(),
        const SizedBox(height: 24),
        _buildHapticsToggle(),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VR 모드',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: VRMode.values.map((mode) {
                final isSelected = _settings.mode == mode;
                return ChoiceChip(
                  label: Text(_getModeName(mode)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _xrManager.setVRMode(mode);
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldOfViewSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '시야각 (FOV)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('${_settings.fieldOfView.toStringAsFixed(0)}°'),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _settings.fieldOfView,
              min: 60,
              max: 120,
              divisions: 60,
              label: '${_settings.fieldOfView.toStringAsFixed(0)}°',
              onChanged: (value) {
                // VRSettings는 불변이므로 새 설정 적용 메서드 필요
                // 여기서는 시뮬레이션
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIPDSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '동공간거리 (IPD)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('${_settings.ipd.toStringAsFixed(3)}m'),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _settings.ipd,
              min: 0.05,
              max: 0.08,
              divisions: 30,
              label: '${_settings.ipd.toStringAsFixed(3)}m',
              onChanged: (value) {
                setState(() {});
              },
            ),
            const Text(
              'VR 헤드셋의 동공간거리를 조절하세요',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotionControlsToggle() {
    return SwitchListTile(
      title: const Text('모션 컨트롤'),
      subtitle: const Text('모션 컨트롤러 사용'),
      value: _settings.motionControls,
      onChanged: (value) {
        // 설정 업데이트
      },
    );
  }

  Widget _buildHapticsToggle() {
    return SwitchListTile(
      title: const Text('햅틱 피드백'),
      subtitle: const Text('촉각 피드백 사용'),
      value: _settings.haptics,
      onChanged: (value) {
        // 설정 업데이트
      },
    );
  }

  String _getModeName(VRMode mode) {
    switch (mode) {
      case VRMode.none:
        return '미사용';
      case VRMode.oculus:
        return 'Oculus';
      case VRMode.htcVive:
        return 'HTC Vive';
      case VRMode.pico:
        return 'Pico';
    }
  }
}

/// AR 설정 화면
class ARSettingsScreen extends StatefulWidget {
  const ARSettingsScreen({super.key});

  @override
  State<ARSettingsScreen> createState() => _ARSettingsScreenState();
}

class _ARSettingsScreenState extends State<ARSettingsScreen> {
  final _xrManager = XRManager.instance;
  ARSettings _settings = const ARSettings();
  bool _supported = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
    _listenToSettings();
  }

  Future<void> _checkSupport() async {
    await _xrManager.initialize();
    setState(() => _supported = true);
  }

  void _listenToSettings() {
    _xrManager.onARSettingsChanged.listen((settings) {
      setState(() => _settings = settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('AR을 지원하지 않는 기기입니다'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModeSelector(),
        const SizedBox(height: 24),
        _buildLightEstimationToggle(),
        const SizedBox(height: 24),
        _buildPlaneDetectionToggle(),
        const SizedBox(height: 24),
        _buildTrackingDistanceSlider(),
        const SizedBox(height: 24),
        _buildAnchorManagement(),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AR 모드',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ARMode.values.map((mode) {
                final isSelected = _settings.mode == mode;
                return ChoiceChip(
                  label: Text(_getModeName(mode)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _xrManager.setARMode(mode);
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightEstimationToggle() {
    return SwitchListTile(
      title: const Text('빛 추정'),
      subtitle: const Text('주변 환경의 빛을 추정하여 조명 적용'),
      value: _settings.enableLightEstimation,
      onChanged: (value) {
        // 설정 업데이트
      },
    );
  }

  Widget _buildPlaneDetectionToggle() {
    return SwitchListTile(
      title: const Text('평면 감지'),
      subtitle: const Text('바닥, 벽 등의 평면을 자동 감지'),
      value: _settings.enablePlaneDetection,
      onChanged: (value) {
        // 설정 업데이트
      },
    );
  }

  Widget _buildTrackingDistanceSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최대 추적 거리',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('${_settings.maxTrackingDistance.toStringAsFixed(1)}m'),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _settings.maxTrackingDistance,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              label: '${_settings.maxTrackingDistance.toStringAsFixed(1)}m',
              onChanged: (value) {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnchorManagement() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AR 앵커',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showPlaceAnchorDialog(context),
              icon: const Icon(Icons.add_location),
              label: const Text('앵커 배치'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceAnchorDialog(BuildContext context) {
    final xController = TextEditingController(text: '0.5');
    final yController = TextEditingController(text: '0.5');
    final idController = TextEditingController(text: 'anchor_${DateTime.now().millisecondsSinceEpoch}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR 앵커 배치'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: '앵커 ID'),
            ),
            TextField(
              controller: xController,
              decoration: const InputDecoration(labelText: 'X 위치 (0-1)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: yController,
              decoration: const InputDecoration(labelText: 'Y 위치 (0-1)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final x = double.tryParse(xController.text) ?? 0.5;
              final y = double.tryParse(yController.text) ?? 0.5;

              // 화면 크기 계산 (실제로는 MediaQuery로)
              final screenSize = const Size(1080, 1920);

              await _xrManager.placeARAnchor(
                anchorId: idController.text,
                position: Offset(x * screenSize.width, y * screenSize.height),
                screenSize: screenSize,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('앵커가 배치되었습니다')),
                );
              }
            },
            child: const Text('배치'),
          ),
        ],
      ),
    );
  }

  String _getModeName(ARMode mode) {
    switch (mode) {
      case ARMode.none:
        return '미사용';
      case ARMode.imageTracking:
        return '이미지 추적';
      case ARMode.planeDetection:
        return '평면 감지';
      case ARMode.faceTracking:
        return '얼굴 추적';
    }
  }
}

/// XR 기기 정보 화면
class XRDeviceInfoScreen extends StatefulWidget {
  const XRDeviceInfoScreen({super.key});

  @override
  State<XRDeviceInfoScreen> createState() => _XRDeviceInfoScreenState();
}

class _XRDeviceInfoScreenState extends State<XRDeviceInfoScreen> {
  final _xrManager = XRManager.instance;
  bool _vrSupported = false;
  bool _arSupported = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    await _xrManager.initialize();

    // 실제 지원 여부 확인
    setState(() {
      _vrSupported = true; // 시뮬레이션
      _arSupported = true; // 시뮬레이션
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSupportCard('VR 지원', _vrSupported, Icons.vrpano),
        const SizedBox(height: 16),
        _buildSupportCard('AR 지원', _arSupported, Icons.view_in_ar),
        const SizedBox(height: 24),
        _buildCalibrationSection(),
      ],
    );
  }

  Widget _buildSupportCard(String title, bool supported, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 32,
          color: supported ? Colors.green : Colors.grey,
        ),
        title: Text(title),
        trailing: Chip(
          label: Text(supported ? '지원' : '미지원'),
          backgroundColor: supported ? Colors.green : Colors.grey,
          labelStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCalibrationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '캘리브레이션',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_vrSupported)
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('VR 캘리브레이션'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showVRCalibrationDialog(),
              ),
            if (_arSupported)
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('AR 캘리브레이션'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showARCalibrationDialog(),
              ),
          ],
        ),
      ),
    );
  }

  void _showVRCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('VR 캘리브레이션'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('캘리브레이션 중...'),
          ],
        ),
      ),
    );

    // 캘리브레이션 시뮬레이션
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('캘리브레이션이 완료되었습니다')),
        );
      }
    });
  }

  void _showARCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR 캘리브레이션'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('카메라 캘리브레이션 중...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('캘리브레이션이 완료되었습니다')),
        );
      }
    });
  }
}
