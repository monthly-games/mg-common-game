# 스토어 출시 체크리스트

## 출시 전 준비

### 기술 요구사항

#### Android (Google Play)
- [ ] Target SDK 34 이상 (Android 14)
- [ ] Minimum SDK 21 이상 (Android 5.0)
- [ ] 64비트 지원 (arm64-v8a, x86_64)
- [ ] App Bundle 형식 (.aab)
- [ ] 서명 키 백업 완료
- [ ] ProGuard/R8 난독화 확인

#### iOS (App Store)
- [ ] Xcode 최신 버전 사용
- [ ] iOS 12.0 이상 지원
- [ ] App Transport Security 준수
- [ ] 코드 서명 및 프로비저닝 확인
- [ ] Bitcode 활성화 (선택)

### 필수 에셋

#### 공통
- [ ] 앱 아이콘 (1024x1024)
- [ ] 스플래시 스크린
- [ ] 스크린샷 (각 기기별)

#### Google Play
- [ ] 512x512 앱 아이콘
- [ ] 1024x500 피처 그래픽
- [ ] 전화기 스크린샷 (최소 2개)
- [ ] 7인치 태블릿 스크린샷
- [ ] 10인치 태블릿 스크린샷

#### App Store
- [ ] 6.7" iPhone 스크린샷
- [ ] 6.5" iPhone 스크린샷
- [ ] 5.5" iPhone 스크린샷
- [ ] 12.9" iPad 스크린샷
- [ ] 앱 미리보기 영상 (선택)

### 법적 요구사항

- [ ] 개인정보처리방침 URL
- [ ] 이용약관 URL (선택)
- [ ] 고객 지원 이메일
- [ ] 개발자 웹사이트

### 콘텐츠 등급

#### Google Play
- [ ] IARC 등급 질문서 완료
- [ ] 앱 콘텐츠 정확히 기술

#### App Store
- [ ] 연령 등급 질문서 완료
- [ ] 콘텐츠 설명 선택

---

## 메타데이터 체크리스트

### 다국어 지원

#### 한국어 (ko)
- [ ] 앱 제목 (30자 이내)
- [ ] 간단한 설명 (80자 이내) - Google Play
- [ ] 부제목 (30자 이내) - App Store
- [ ] 상세 설명 (4,000자 이내)
- [ ] 키워드 (100자 이내) - App Store
- [ ] 업데이트 노트

#### 영어 (en)
- [ ] App Title (30 chars max)
- [ ] Short Description (80 chars max) - Google Play
- [ ] Subtitle (30 chars max) - App Store
- [ ] Full Description (4,000 chars max)
- [ ] Keywords (100 chars max) - App Store
- [ ] Release Notes

#### 일본어 (ja) - 선택
- [ ] 앱 제목
- [ ] 설명
- [ ] 키워드

---

## 인앱 결제 (IAP)

### 상품 설정
- [ ] 소모성 상품 등록
- [ ] 비소모성 상품 등록
- [ ] 구독 상품 등록 (해당 시)
- [ ] 가격 설정 (모든 국가)
- [ ] 상품 설명 (다국어)
- [ ] 심사용 테스트 계정

### 결제 테스트
- [ ] 테스트 결제 성공
- [ ] 결제 취소 처리 확인
- [ ] 구독 갱신 테스트
- [ ] 구매 복원 기능 확인

---

## 광고 (해당 시)

- [ ] 광고 SDK 최신 버전
- [ ] GDPR 동의 구현
- [ ] ATT 동의 구현 (iOS)
- [ ] 광고 테스트 완료
- [ ] 광고 ID 설정

---

## 분석 및 추적

- [ ] Firebase Analytics 설정
- [ ] 크래시 리포팅 설정 (Crashlytics)
- [ ] 핵심 이벤트 추적 확인
- [ ] 사용자 속성 설정

---

## 테스트

### 기능 테스트
- [ ] 모든 핵심 기능 동작 확인
- [ ] 오프라인 모드 테스트
- [ ] 저사양 기기 테스트
- [ ] 다양한 화면 크기 테스트

### 성능 테스트
- [ ] 메모리 누수 확인
- [ ] 배터리 소모량 확인
- [ ] 앱 시작 시간 확인
- [ ] 프레임 드롭 확인

### 호환성 테스트
- [ ] Android 5.0 ~ 14 테스트
- [ ] iOS 12 ~ 17 테스트
- [ ] 다양한 기기 테스트

---

## 출시 프로세스

### Google Play

1. **내부 테스트**
   - [ ] 내부 테스트 트랙에 업로드
   - [ ] 테스터 초대 및 피드백 수집
   - [ ] 주요 버그 수정

2. **비공개 테스트**
   - [ ] 비공개 테스트 트랙 설정
   - [ ] 외부 테스터 초대 (100-1000명)
   - [ ] 피드백 기반 개선

3. **공개 테스트** (선택)
   - [ ] 공개 테스트 트랙 설정
   - [ ] 넓은 사용자 피드백 수집

4. **프로덕션 출시**
   - [ ] 단계적 출시 설정 (10% → 50% → 100%)
   - [ ] 출시 노트 작성
   - [ ] 출시 버튼 클릭

### App Store

1. **TestFlight 내부 테스트**
   - [ ] App Store Connect에 빌드 업로드
   - [ ] 내부 테스터 초대
   - [ ] 버그 수정

2. **TestFlight 외부 테스트**
   - [ ] Beta App Review 제출
   - [ ] 외부 테스터 초대 (최대 10,000명)
   - [ ] 피드백 수집

3. **App Store 제출**
   - [ ] 모든 메타데이터 완성
   - [ ] 심사 노트 작성 (필요시)
   - [ ] 심사 제출

4. **출시**
   - [ ] 심사 승인 확인
   - [ ] 출시 일정 설정 (즉시/예약)
   - [ ] 출시 확인

---

## 출시 후

### 모니터링
- [ ] 크래시 리포트 모니터링
- [ ] 사용자 리뷰 확인
- [ ] 다운로드 통계 확인
- [ ] 수익 통계 확인

### 대응
- [ ] 리뷰 응답
- [ ] 긴급 버그 수정 준비
- [ ] 사용자 문의 대응

### 마케팅
- [ ] 소셜 미디어 발표
- [ ] 보도 자료 배포 (해당 시)
- [ ] 커뮤니티 공지

---

## 유용한 링크

### Google Play Console
- https://play.google.com/console

### App Store Connect
- https://appstoreconnect.apple.com

### 정책 및 가이드라인
- [Google Play 정책](https://play.google.com/about/developer-content-policy/)
- [App Store 심사 지침](https://developer.apple.com/app-store/review/guidelines/)
- [Firebase 콘솔](https://console.firebase.google.com/)
