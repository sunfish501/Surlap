# HourSpace 출시 체크리스트 (App Store / Google Play)

## ✅ 코드/설정 완료 (이번 작업)
- [x] Pretendard 폰트 번들 (시스템폰트 → 정품 한글 폰트)
- [x] iOS 배포 타겟 16.0 (Podfile + 모든 빌드 구성)
- [x] iOS Privacy Manifest (`ios/Runner/PrivacyInfo.xcprivacy`) — UserDefaults/FileTimestamp/BootTime/DiskSpace 사유 선언, 추적 없음
- [x] 앱 내 회원 탈퇴 (프로필 → 계정 → 회원 탈퇴) — Apple 필수
- [x] 권한 사용 설명 문자열(Info.plist): 마이크/음성/사진/연락처 모두 존재
- [x] 알림 플러그인 시작 시 초기화 (예약 알림 재가동)
- [x] Android release 서명 구성 배선 (`key.properties` 있으면 사용, 없으면 debug)
- [x] 개인정보처리방침/지원 페이지 작성 (`docs/privacy.html`, `docs/index.html`)
- [x] 디버그 배너 off, print 스팸 없음
- [x] Sign in with Apple (iOS) — Google 등 3rd-party 로그인 제공 시 필수 (Apple 4.8)
- [x] 설정 화면에 개인정보처리방침·이용약관 링크 행
- [x] Android targetSdk = Flutter 기본(현재 35) — Play Aug 2025 요구사항(34+) 충족

## ⏳ 남은 수동 단계 (권한/외부작업 — 직접 1회)

### 1. Supabase 회원탈퇴 RPC 적용  (필수)
Supabase 대시보드(프로젝트 `ngmvddxpoqtbrwpwiogh`) → SQL Editor →
`supabase/migrations/0001_delete_account.sql` 전체 붙여넣고 Run.
→ 앱의 "회원 탈퇴"가 실제로 동작.

### 2. 개인정보처리방침 URL 활성화  (필수)
GitHub: `kev208dev/HourSpace-app` → Settings → Pages →
Source = `main` 브랜치 / `/docs` 폴더 → Save.
→ URL: `https://kev208dev.github.io/HourSpace-app/privacy.html`
이 URL을 App Store Connect / Play Console 개인정보처리방침 칸에 입력.

### 3. Android 업로드 키스토어 생성  (Play 제출 시)
Java/Android 환경에서:
```
cd android
keytool -genkeypair -v -keystore app/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
# 그 후 android/key.properties 생성:
#   storePassword=...
#   keyPassword=...
#   keyAlias=upload
#   storeFile=upload-keystore.jks
flutter build appbundle --release
```
(key.properties / *.jks 는 .gitignore 처리됨 — 절대 커밋 금지)

### 4. iOS 서명 + 빌드  (App Store 제출 시)
Xcode → Runner & HourSpaceWidget 타겟 → Signing & Capabilities →
본인 Team 선택 → `flutter build ipa --release` → Transporter/Xcode 업로드.

### 5. Supabase Apple OAuth 설정  (iOS Sign in with Apple)
1. Apple Developer Portal → Identifiers → 새 Service ID 생성 (`com.spacehour.spacehour.web` 등).
2. Service ID에 Sign In with Apple capability + Return URL = `https://<supabase-project>.supabase.co/auth/v1/callback`.
3. Apple Developer Portal → Keys → 새 Key 생성 + Sign in with Apple 활성화. `.p8` 파일 다운로드.
4. Supabase Dashboard → Authentication → Providers → Apple → enable, Service ID/Team ID/Key ID/Private Key 입력.
5. Redirect URLs에 `spacehour://login-callback` 추가.

## 🎬 App Review note (Apple 콘솔 "App Review Information" 칸)
```
이 앱은 로그인 없이 게스트 모드로 모든 기능을 사용할 수 있습니다.
"로그인 없이 사용" 버튼으로 진입하세요.

테스트가 필요한 경우 데모 계정:
  ID: demo@hourspace.app
  PW: HourSpace2026!

Sign in with Apple도 제공합니다 (iOS 빌드).
Google 로그인은 외부 브라우저(Safari)로 리다이렉트됩니다.

회원 탈퇴: 프로필 → 계정 → 회원 탈퇴.
```
(데모 계정은 출시 전 Supabase에 미리 생성하고 ID/PW를 위에 갱신.)

## 📋 스토어 등록물 (콘솔에서 준비)
- [ ] 앱 스크린샷 (iPhone 6.7"/6.5", iPad / Android 폰·태블릿)
- [ ] 앱 설명·키워드 (한국어 + 영어)
- [ ] 카테고리: 생산성(Productivity)
- [ ] 연령 등급: 4+ / 전체이용가
- [ ] 데이터 안전(Play) / 개인정보 라벨(App Store): 이메일=앱기능, 추적 없음
- [ ] 지원 URL: `https://kev208dev.github.io/HourSpace-app/`

## 권한 사용 사유 (심사 메모용)
- 연락처: 생일 가져오기(선택) · 마이크: 할 일 음성 입력(선택)
- 사진: 달력 이미지 저장(선택) · 알림: 생일 알림(선택)
- 모두 사용자가 기능을 켤 때만 요청, 미사용 시 권한 요청 안 함.
