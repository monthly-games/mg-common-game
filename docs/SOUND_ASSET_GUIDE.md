# MG Games Sound Asset Guide

## 개요

이 문서는 `PolishSounds` 클래스에 정의된 사운드 에셋을 준비하는 가이드입니다.

## 필요한 사운드 파일 목록

### 1. UI/터치 사운드 (6개)

| 파일명 | 용도 | 권장 길이 | 특징 |
|--------|------|-----------|------|
| `sfx/ui_tap.mp3` | 일반 버튼 터치 | 0.1-0.2초 | 가볍고 깔끔한 클릭 |
| `sfx/ui_tap_heavy.mp3` | 중요 버튼 터치 | 0.1-0.3초 | 약간 무거운 클릭 |
| `sfx/ui_swipe.mp3` | 스와이프 제스처 | 0.2-0.3초 | 쓱 하는 소리 |
| `sfx/ui_toggle.mp3` | 토글 스위치 | 0.1-0.2초 | 딸깍 소리 |
| `sfx/ui_error.mp3` | 에러/불가 액션 | 0.2-0.4초 | 부정적 피드백 |
| `sfx/ui_success.mp3` | 성공/완료 | 0.3-0.5초 | 긍정적 피드백 |

### 2. 보상/획득 사운드 (6개)

| 파일명 | 용도 | 권장 길이 | 특징 |
|--------|------|-----------|------|
| `sfx/coin_drop.mp3` | 코인 하나 획득 | 0.1-0.2초 | 짤랑 소리 |
| `sfx/coin_stack.mp3` | 다량 코인 획득 | 0.3-0.5초 | 여러 코인 쌓이는 소리 |
| `sfx/item_get.mp3` | 일반 아이템 획득 | 0.3-0.5초 | 획득 효과음 |
| `sfx/chest_open.mp3` | 상자 열기 | 0.5-1.0초 | 열리는 + 반짝임 |
| `sfx/legendary_drop.mp3` | 레전더리 획득 | 1.0-2.0초 | 드라마틱한 효과 |
| `sfx/level_up.mp3` | 레벨업 | 1.0-1.5초 | 상승감 있는 효과 |

### 3. 전투 사운드 (9개)

| 파일명 | 용도 | 권장 길이 | 특징 |
|--------|------|-----------|------|
| `sfx/hit.mp3` | 일반 타격 | 0.1-0.2초 | 기본 타격음 |
| `sfx/hit_critical.mp3` | 크리티컬 타격 | 0.2-0.4초 | 강렬한 타격 |
| `sfx/hit_weak.mp3` | 약한 타격 | 0.1-0.2초 | 둔한 타격 |
| `sfx/miss.mp3` | 빗나감 | 0.2-0.3초 | 휙 소리 |
| `sfx/block.mp3` | 방어 | 0.2-0.3초 | 막는 소리 |
| `sfx/heal.mp3` | 회복 | 0.3-0.5초 | 치유 효과 |
| `sfx/buff.mp3` | 버프 적용 | 0.3-0.5초 | 상승 효과 |
| `sfx/debuff.mp3` | 디버프 적용 | 0.3-0.5초 | 하락 효과 |
| `sfx/death.mp3` | 캐릭터 사망 | 0.5-1.0초 | 사망 효과 |

### 4. 콤보 사운드 (5개)

| 파일명 | 용도 | 권장 길이 | 특징 |
|--------|------|-----------|------|
| `sfx/combo_1.mp3` | 콤보 1-4 | 0.2-0.3초 | 기본 콤보 |
| `sfx/combo_2.mp3` | 콤보 5-9 | 0.2-0.3초 | 피치 약간 높음 |
| `sfx/combo_3.mp3` | 콤보 10-19 | 0.3-0.4초 | 피치 더 높음 |
| `sfx/combo_max.mp3` | 콤보 20+ | 0.4-0.5초 | 최대 콤보 효과 |
| `sfx/combo_break.mp3` | 콤보 끊김 | 0.3-0.5초 | 부정적 효과 |

### 5. 특수 연출 사운드 (5개)

| 파일명 | 용도 | 권장 길이 | 특징 |
|--------|------|-----------|------|
| `sfx/explosion.mp3` | 폭발 | 0.5-1.0초 | 폭발음 |
| `sfx/magic.mp3` | 마법 시전 | 0.3-0.8초 | 마법 효과 |
| `sfx/ultimate.mp3` | 궁극기 | 1.0-2.0초 | 강력한 스킬 |
| `sfx/victory.mp3` | 승리 | 1.5-3.0초 | 승리 팡파레 |
| `sfx/defeat.mp3` | 패배 | 1.0-2.0초 | 패배 효과 |

---

## 무료 사운드 소스

### 추천 사이트

1. **Freesound.org** (CC0/CC-BY)
   - https://freesound.org
   - 다양한 라이선스, 검색 용이
   - UI 사운드, 게임 효과음 풍부

2. **OpenGameArt.org** (CC0/CC-BY)
   - https://opengameart.org/art-search-advanced?keys=&field_art_type_tid%5B%5D=13
   - 게임 전용 에셋
   - 패키지로 제공되는 경우 많음

3. **Kenney.nl** (CC0)
   - https://kenney.nl/assets?q=audio
   - 고품질 무료 에셋
   - UI, 효과음 패키지 제공

4. **Mixkit** (무료 라이선스)
   - https://mixkit.co/free-sound-effects/game/
   - 상업용 무료
   - 게임 카테고리 별도

5. **Zapsplat** (무료/프리미엄)
   - https://www.zapsplat.com/sound-effect-categories/
   - 방대한 라이브러리
   - 무료 계정으로 다운로드

### 추천 검색어

| 카테고리 | 검색어 |
|----------|--------|
| UI | `ui click`, `button press`, `menu select`, `notification` |
| 코인 | `coin`, `money`, `gold collect`, `treasure` |
| 타격 | `punch`, `hit`, `impact`, `whoosh` |
| 마법 | `magic`, `spell`, `power up`, `enchant` |
| 폭발 | `explosion`, `blast`, `boom` |
| 승리 | `victory fanfare`, `win jingle`, `success` |

---

## 에셋 폴더 구조

```
game/
└── assets/
    └── audio/
        └── sfx/
            ├── ui_tap.mp3
            ├── ui_tap_heavy.mp3
            ├── ui_swipe.mp3
            ├── ui_toggle.mp3
            ├── ui_error.mp3
            ├── ui_success.mp3
            ├── coin_drop.mp3
            ├── coin_stack.mp3
            ├── item_get.mp3
            ├── chest_open.mp3
            ├── legendary_drop.mp3
            ├── level_up.mp3
            ├── hit.mp3
            ├── hit_critical.mp3
            ├── hit_weak.mp3
            ├── miss.mp3
            ├── block.mp3
            ├── heal.mp3
            ├── buff.mp3
            ├── debuff.mp3
            ├── death.mp3
            ├── combo_1.mp3
            ├── combo_2.mp3
            ├── combo_3.mp3
            ├── combo_max.mp3
            ├── combo_break.mp3
            ├── explosion.mp3
            ├── magic.mp3
            ├── ultimate.mp3
            ├── victory.mp3
            └── defeat.mp3
```

---

## pubspec.yaml 설정

```yaml
flutter:
  assets:
    - assets/audio/sfx/
```

---

## AudioManager 사용 예시

```dart
import 'package:mg_common_game/core/audio/audio_manager.dart';
import 'package:mg_common_game/core/ui/polish/polish_sounds.dart';

// 싱글톤 접근
final audio = AudioManager();

// UI 사운드
audio.playSfx(PolishSounds.tap);
audio.playSfx(PolishSounds.success);

// 전투 사운드
audio.playSfx(PolishSounds.hit);
audio.playSfx(PolishSounds.hitCritical);

// 콤보 사운드 (피치 조절)
final comboSound = PolishSounds.comboSound(comboCount);
final comboPitch = PolishSounds.comboPitch(comboCount);
audio.playSfx(comboSound, pitch: comboPitch);

// 볼륨 조절
audio.setSfxVolume(0.8);
audio.setMasterVolume(1.0);
```

---

## 오디오 파일 최적화 팁

### 포맷 권장사항
- **MP3**: 가장 호환성 좋음, 대부분의 SFX에 적합
- **OGG**: 파일 크기 작음, Android 최적화
- **WAV**: 무압축, 아주 짧은 효과음에 적합

### 비트레이트
- SFX: 128kbps 이상
- BGM: 192kbps 이상

### 샘플레이트
- 44.1kHz 권장 (표준)

### 파일 크기 가이드
- UI 사운드: 10-50KB
- 일반 SFX: 50-200KB
- 특수 효과: 100-500KB
- BGM: 2-5MB

---

## 플레이스홀더 생성 스크립트

사운드 파일이 없을 때 빈 파일 생성:

```bash
# Windows PowerShell
$sfxFiles = @(
    "ui_tap", "ui_tap_heavy", "ui_swipe", "ui_toggle", "ui_error", "ui_success",
    "coin_drop", "coin_stack", "item_get", "chest_open", "legendary_drop", "level_up",
    "hit", "hit_critical", "hit_weak", "miss", "block", "heal", "buff", "debuff", "death",
    "combo_1", "combo_2", "combo_3", "combo_max", "combo_break",
    "explosion", "magic", "ultimate", "victory", "defeat"
)

New-Item -ItemType Directory -Force -Path "assets/audio/sfx"

foreach ($file in $sfxFiles) {
    $path = "assets/audio/sfx/$file.mp3"
    if (-not (Test-Path $path)) {
        # 빈 파일 또는 무음 MP3 복사
        Copy-Item "silent.mp3" $path
    }
}
```

---

## 총 필요 파일: 31개

| 카테고리 | 개수 |
|----------|------|
| UI/터치 | 6 |
| 보상/획득 | 6 |
| 전투 | 9 |
| 콤보 | 5 |
| 특수 연출 | 5 |
| **합계** | **31** |
