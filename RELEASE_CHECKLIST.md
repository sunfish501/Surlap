# Surlap 릴리스 체크리스트

> **이 파일은 직접 해야 할 항목 목록이다. Claude가 자동으로 할 수 없는 것들.**

---

## ① 릴리스 서명 (필수, 플레이스토어 업로드 전)

```bash
# 1. keystore 생성 (처음 한 번만)
keytool -genkey -v -keystore ~/upload-keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -alias upload

# 2. android/key.properties 파일 생성 (git 제외 — .gitignore 확인)
storePassword=<비밀번호>
keyPassword=<비밀번호>
keyAlias=upload
storeFile=<keystore 절대경로>

# 3. android/app/build.gradle.kts 수정
#    buildTypes { release { signingConfig = signingConfigs.getByName("release") } }
#    + signingConfigs { release { ... key.properties 읽기 ... } }
```

> ⚠️ keystore 파일과 key.properties는 절대 git에 커밋하지 말 것.

---

## ② assetlinks.json — 릴리스 SHA256 추가

앱 링크(`https://kev208dev.github.io/theme/<code>`)가 릴리스 APK/AAB에서도
동작하려면 릴리스 서명의 SHA256을 assetlinks.json에 추가해야 한다.

```bash
# 릴리스 keystore SHA256 확인
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
# → "SHA256:" 항목을 복사

# kev208dev.github.io 레포의 docs/.well-known/assetlinks.json 에 추가:
# { "relation": [...], "target": { ..., "sha256_cert_fingerprints": ["<debug SHA>", "<release SHA>"] } }
```

---

## ③ versionCode / versionName 업데이트

현재: `version: 1.0.0+1` (pubspec.yaml)

Play Store 첫 업로드: versionCode(+1 뒤 숫자)가 1이면 OK.
업데이트 시: versionCode는 반드시 이전보다 높아야 함.

```yaml
# pubspec.yaml
version: 1.0.0+1   # versionName=1.0.0, versionCode=1
```

---

## ④ Supabase RLS (Row Level Security) 최종 확인

Supabase 대시보드에서 각 테이블의 RLS 정책 확인:
- `events`, `user_data`, `themes`, `theme_subscribers` 테이블
- anon 사용자가 다른 사용자의 데이터를 읽을 수 없는지 확인
- 테스트: 다른 계정으로 로그인해서 내 데이터가 안 보이는지 확인

---

## ⑤ 스토어 등록 준비 (Google Play Console)

- [ ] 앱 설명 (한국어 / 영어)
- [ ] 스크린샷 (폰 6.7인치: 최소 2장 이상, 권장 8장)
- [ ] Feature Graphic (1024×500 px)
- [ ] 아이콘 (512×512 px PNG, 투명 배경 없음)
- [ ] 개인정보처리방침 URL (Supabase 인증·저장 데이터 명시)
- [ ] 콘텐츠 등급 설문
- [ ] 타겟 연령대: 13세 이상 (학교 일정 앱)

---

## ⑥ 릴리스 빌드 & 검증

```bash
# AAB 빌드 (Play Store 권장)
flutter build appbundle --release --dart-define-from-file=.dart_define

# 또는 APK (직접 배포용)
flutter build apk --release --split-per-abi --dart-define-from-file=.dart_define

# 에뮬레이터/실기기에서 릴리스 APK 테스트
flutter install --release
```

> ⚠️ **반드시 `--dart-define-from-file=.dart_define` 를 붙일 것.**
> 빠뜨리면 BALLDONTLIE/FOOTBALL_DATA/PANDASCORE 키가 비어서
> "스포츠 API 키가 없어 경기 일정이 안 와요" 에러가 뜬다.
> (`flutter install` 은 위에서 만든 빌드를 그대로 설치하므로 플래그 불필요.)

릴리스 빌드 후 확인:
- [ ] 앱 시작 정상
- [ ] Supabase 로그인 정상
- [ ] NEIS 연동 정상
- [ ] 딥링크 (spacehour://theme/ 및 https://kev208dev.github.io/theme/) 정상
- [ ] 사진 공유 정상
- [ ] 파일 백업/복원 정상

---

## ⑦ 코드 상태 확인 (자동화 가능)

```bash
flutter analyze   # 0 이슈 확인됨 ✓
flutter test      # 없으면 skip
```

---

## 현재 상태 요약

| 항목 | 상태 |
|------|------|
| applicationId | `com.spacehour.spacehour` — 변경 금지 |
| 앱 이름 | `Surlap` — android:label, CFBundleDisplayName 모두 설정됨 |
| 버전 | `1.0.0+1` |
| 릴리스 서명 | ❌ debug key 사용 중 — keystore 생성 필요 |
| assetlinks.json | ❌ 릴리스 SHA256 미추가 |
| 권한 | INTERNET만 사용 (최소 권한) |
| flutter analyze | ✅ 0 이슈 |
| Supabase RLS | 수동 확인 필요 |
