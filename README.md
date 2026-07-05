# Surlap

> 나만의 일정·시간표·위젯을 한 곳에.

한국 K-12 학교(NEIS) 연동, 스포츠 일정 구독, 다국어(ko/en/ja/zh/es) 지원 Flutter 캘린더/시간표/위젯 앱.

## 주요 기능

- **캘린더 뷰**: 일/주(플래너)/월/연 자유 전환, 다일 일정 색띠
- **할 일**: 자연어 입력("내일 p1 빨래"), 음성 인식, 우선순위
- **반복 일정**: 매주/매월/매년 + 종료일
- **푸시 알림**: 일정 시작 N분 전, 매일 아침 브리핑, 생일, 스포츠
- **시간표**: NEIS 자동 + 직접 입력, 빈 교시 라벨(자습/공강)
- **학교 연동**: NEIS 시간표·급식·학사일정 자동 수신, D-day 카드
- **스포츠**: NBA/EPL/F1/LoL 팀·대회 구독 → 캘린더 자동 표시
- **공유 캘린더**: 코드/링크로 공유, 구독자는 읽기 전용
- **백업**: 로컬 JSON, Supabase 클라우드 동기화, iCal(.ics) 내보내기
- **위젯**: iOS WidgetKit / Android AppWidget 홈스크린 위젯
- **i18n**: ko / en / ja / zh / es

## 기술 스택

- Flutter 3.41+ / Dart 3.11+
- 상태: Riverpod (`flutter_riverpod`)
- 백엔드: Supabase (auth, postgres, RLS)
- 인증: 이메일/Google/Apple OAuth
- 저장: SharedPreferences (로컬), Supabase user_data + events 테이블 (클라우드)
- 알림: `flutter_local_notifications` + `timezone`
- 음성: `speech_to_text` (디바이스 내 인식)
- 위젯 브리지: `home_widget`

## 빌드/실행

```bash
flutter pub get
flutter run --dart-define-from-file=.dart_define
```

`.dart_define` 예시는 `.dart_define.example` 참고. Supabase URL/key를 채워야 클라우드 기능 동작.

## 디렉터리

```
lib/
  main.dart           # 부트스트랩
  app.dart            # MaterialApp + 딥링크
  core/               # 테마/상수/유틸 (date/recurrence/event_parser/todo_parser)
  models/             # EventItem / TodoItem / CalendarTheme / ...
  providers/          # Riverpod notifiers
  storage/            # LocalStore
  supabase/           # auth, events_sync, neis_service, sports, theme_share
  i18n/               # translations(ko/en/ja/zh/es) + tr()/trf()
  screens/            # home/day/planner/month/year/timetable/...
  modals/             # add_edit_event, add_todo, profile, backup, ...
  widgets/            # 공통 위젯
  day_widgets/        # 일별 기록 위젯 (check/counter/...)
  home_widget/        # iOS/Android 홈스크린 위젯 브리지
  utils/              # 알림, screenshot, iCal export
supabase/migrations/  # delete_account RPC
```

## 출시 관련

- `STORE_SUBMISSION.md` — App Store / Play 제출 체크리스트
- `RELEASE_CHECKLIST.md` — 릴리스 준비 단계
- `docs/privacy.html` — 개인정보 처리방침 (GitHub Pages 호스팅)
- `docs/index.html` — 지원 페이지

## 라이선스

비공개. © 2026 SpaceHour.
