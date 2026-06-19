Surlap - Google Play Console 업로드 번들
=========================================

앱 이름:                Surlap
패키지명(applicationId): com.kev208dev.Surlap
버전명(versionName):     1.0.0
버전코드(versionCode):   1
빌드 타입:               release (서명됨, upload-keystore.jks)

파일
----
- Surlap-v1.0.0-build1.aab        ← Play Console "새 버전 만들기"에 업로드
- mapping/mapping.txt              ← R8 디오브퓨스케이션 매핑(선택, 크래시 분석용)

주의
----
- 딥링크 scheme `spacehour://` 는 유지(Supabase OAuth 콜백 연결).
  scheme 까지 surlap 으로 바꾸려면 Supabase redirectTo + Google OAuth client 설정 동시 갱신 필요.
- iOS bundle id 미변경. iOS 출시 시 별도 작업.
- applicationId 는 Play Store 첫 출시 후 영구 락. 대문자 S 포함된 상태로 락됨.
