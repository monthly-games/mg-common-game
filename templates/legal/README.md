# Legal Document Templates

모바일 게임 출시에 필요한 법적 문서 템플릿입니다.

## 포함된 템플릿

### 개인정보처리방침 (Privacy Policy)
- `PRIVACY_POLICY_KO.md` - 한국어 버전
- `PRIVACY_POLICY_EN.md` - 영어 버전 (GDPR, CCPA 포함)

### 이용약관 (Terms of Service)
- `TERMS_OF_SERVICE_EN.md` - 영어 버전

## 사용 방법

### 1. 템플릿 복사
게임 프로젝트의 `legal/` 폴더에 필요한 템플릿을 복사합니다.

### 2. 플레이스홀더 교체
다음 플레이스홀더를 실제 정보로 교체합니다:

| 플레이스홀더 | 설명 | 예시 |
|--------------|------|------|
| `{{DEVELOPER_NAME}}` | 개발자/회사명 | Monthly Games |
| `{{GAME_NAME}}` | 게임 이름 | Puzzle Master |
| `{{SUPPORT_EMAIL}}` | 지원 이메일 | support@example.com |
| `{{WEBSITE_URL}}` | 웹사이트 주소 | https://example.com |
| `{{PRIVACY_POLICY_URL}}` | 개인정보처리방침 URL | https://example.com/privacy |
| `{{LAST_UPDATED}}` | 최종 수정일 | January 1, 2025 |
| `{{EFFECTIVE_DATE}}` | 시행일 | January 1, 2025 |
| `{{AD_NETWORK}}` | 광고 네트워크 | Google AdMob |
| `{{JURISDICTION}}` | 관할권 | Republic of Korea |

### 3. 호스팅
문서를 웹에서 접근 가능하게 호스팅합니다:

**무료 호스팅 옵션:**
- GitHub Pages (github.io)
- Notion 페이지 공개
- Google Docs 링크 공유
- 개인 웹사이트

**권장 URL 구조:**
```
https://yourdomain.com/games/[game-name]/privacy
https://yourdomain.com/games/[game-name]/terms
```

### 4. 앱 내 링크 설정
Flutter 앱에서 URL 열기:

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> openPrivacyPolicy() async {
  final url = Uri.parse('https://yourdomain.com/privacy');
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  }
}
```

## 법적 고지

**중요**: 이 템플릿은 참고용으로 제공됩니다.

- 법적 조언이 아닙니다
- 각 국가/지역의 법률에 맞게 수정이 필요할 수 있습니다
- 중요한 사안에 대해서는 법률 전문가와 상담하세요
- 앱스토어 정책 변경에 따라 업데이트가 필요할 수 있습니다

## 필수 규정 체크리스트

### GDPR (유럽)
- [ ] 데이터 처리의 법적 근거 명시
- [ ] 데이터 주체 권리 안내
- [ ] 데이터 보호 책임자(DPO) 정보 (해당 시)
- [ ] 국외 데이터 전송 고지

### CCPA (캘리포니아)
- [ ] 수집되는 개인정보 범주 공개
- [ ] 개인정보 판매 여부 명시
- [ ] 옵트아웃 권리 안내
- [ ] 차별 금지 조항

### COPPA (아동)
- [ ] 13세 미만 아동 대상 여부 명시
- [ ] 아동 정보 수집 시 부모 동의 절차
- [ ] 아동 정보 특별 보호 조치

### 한국 개인정보보호법
- [ ] 개인정보 수집/이용 목적
- [ ] 개인정보 보유 기간
- [ ] 제3자 제공 현황
- [ ] 개인정보 처리 위탁
- [ ] 개인정보 보호책임자

## 앱스토어 요구사항

### Google Play
- 개인정보처리방침 URL 필수
- 데이터 안전 섹션 작성
- 아동 대상 앱은 추가 요구사항

### App Store
- 개인정보처리방침 URL 필수
- App Privacy 정보 제출
- Sign in with Apple 사용 시 추가 고려사항

## 정기 업데이트 권장

법적 문서는 다음 경우에 업데이트하세요:
- 새로운 기능/서비스 추가
- 제3자 SDK 추가/변경
- 법률/규정 변경
- 앱스토어 정책 변경
- 최소 연 1회 검토

## 유용한 리소스

- [GDPR 공식 사이트](https://gdpr.eu/)
- [CCPA 공식 정보](https://oag.ca.gov/privacy/ccpa)
- [한국 개인정보보호위원회](https://www.pipc.go.kr/)
- [Google Play 정책](https://play.google.com/about/developer-content-policy/)
- [Apple App Store 지침](https://developer.apple.com/app-store/review/guidelines/)
