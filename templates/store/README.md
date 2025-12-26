# Store Metadata Templates

이 폴더는 Google Play Store와 Apple App Store에 게임을 등록할 때 필요한 메타데이터 템플릿을 제공합니다.

## 폴더 구조

```
store/
├── google_play/
│   ├── listing_ko.md      # 한국어 스토어 등록 정보
│   ├── listing_en.md      # 영어 스토어 등록 정보
│   ├── listing_ja.md      # 일본어 스토어 등록 정보
│   └── screenshots/       # 스크린샷 가이드
├── app_store/
│   ├── listing_ko.md      # 한국어 앱스토어 정보
│   ├── listing_en.md      # 영어 앱스토어 정보
│   └── listing_ja.md      # 일본어 앱스토어 정보
├── keywords.md            # ASO 키워드 가이드
└── CHECKLIST.md           # 출시 전 체크리스트
```

## 사용법

1. 각 언어별 템플릿을 복사하여 게임별 폴더에 저장
2. `{{GAME_NAME}}`, `{{DEVELOPER_NAME}}` 등의 플레이스홀더를 실제 값으로 교체
3. 스크린샷 가이드에 따라 스크린샷 준비
4. 체크리스트를 따라 모든 항목 확인

## 필수 요소

### Google Play Store
- 앱 제목: 최대 30자
- 간단한 설명: 최대 80자
- 자세한 설명: 최대 4,000자
- 스크린샷: 최소 2개 (최대 8개)
- 피처 그래픽: 1024x500 (필수)
- 앱 아이콘: 512x512

### Apple App Store
- 앱 이름: 최대 30자
- 부제목: 최대 30자
- 프로모션 텍스트: 최대 170자
- 설명: 최대 4,000자
- 키워드: 최대 100자
- 스크린샷: 기기별 필수
