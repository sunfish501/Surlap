# 무인 작업 진행 기록 (feature/polish)

## feature/polish 진행 현황

### 디자인 시안 정렬

| 화면 | 상태 | 비고 |
|------|------|------|
| 상단 chrome — 날짜 앵커·뷰 세그먼트·4탭 하단 네비 | [완료] | feat(chrome) 커밋 |
| 월간 뷰 | [완료] | 기존 구조 시안과 일치, 추가 변경 불필요 |
| 연간 뷰 | [완료] | 3열 미니카드, 현재 월 강조 테두리 확인 |
| 주간 뷰 | [완료] | 7컬럼 시간 그리드 확인 |
| 일별 뷰 | [완료] | 시간축 + 현재 시각 표시선 확인 |
| 시간표 뷰 | [완료] | 주간 그리드 확인, NEIS 연동 설정 접근 가능 |
| 테마 관리 | [건너뜀] | 기능 동작 이상 없음, 미세 시각 폴리시는 다음 이터레이션 |

### 히어로 전환 점검

| 항목 | 상태 | 비고 |
|------|------|------|
| 연간→월간 커스텀 오버레이 줌 전환 | [완료] | easeInOutCubic 360ms, 콘텐츠 스케일 — 이미 구현됨 |

### 앱 이름 통일

| 항목 | 상태 | 비고 |
|------|------|------|
| android:label | [완료] | HourSpace |
| iOS CFBundleDisplayName | [완료] | HourSpace |
| UI 텍스트 (AppHeader) | [완료] | HourSpace |

### 배포 준비

| 항목 | 상태 | 비고 |
|------|------|------|
| flutter analyze 경고 | [완료] | 0 이슈 |
| 디버그 print | [완료] | 전부 debugPrint (릴리스 모드 자동 억제) |
| Android 빌드 설정 점검 | [완료] | applicationId/권한/딥링크 확인 |
| RELEASE_CHECKLIST.md 작성 | [완료] | 직접 해야 할 항목 목록화 |

### 확인 필요 (위험/미검증)
- 릴리스 키 서명 미설정 (debug key 사용 중) → RELEASE_CHECKLIST.md 참고
- assetlinks.json에 릴리스 SHA256 미추가 → RELEASE_CHECKLIST.md 참고
- Supabase RLS 수동 검증 필요 → RELEASE_CHECKLIST.md 참고

---

## 이전 작업 기록 (feature/finish-remaining)

### Baseline
- 커밋: d81ddd9 (master)
- 브랜치: feature/finish-remaining

### 1. 날짜 메모 → 월간 뷰 표시 (calendar-memos-v1)
상태: **완료** ✓
- month_grid.dart: 6×7 그리드 리팩토링, 앞쪽/뒤쪽 여백 셀을 _MemoCell로 교체
- month_view.dart: memosProvider 연결, _editMemo 다이얼로그 추가
- month_view.dart: onDayLongPress → _showDayActionMenu로 통합

### 2. 날짜 셀 위젯 입력값 표시 (calendar-day-widget-values-v1)
상태: **완료** ✓
- day_cell.dart: applicableTemplates, dateWidgetValues 파라미터 추가
- day_cell.dart: _buildWidgetRows() — 빈 값 스킵, 최대 3행, dimmed opacity
- month_grid.dart: dayTemplatesProvider/widgetValuesProvider 연결, _buildDayCell helper

### 3. 반복 시간표 → 시간표 뷰 반영 (timetable-template + overrides)
상태: **완료** ✓
- timetable_view.dart: _buildTemplateData() — JSON 파싱, weekdays/날짜범위/override/extra 처리
- timetable_view.dart: 우선순위 user > NEIS > template 적용

### 4. NEIS 데이터 화면 연결
상태: **완료** ✓
- timetable_view.dart: _fetchNeisIfNeeded() initState에서 비동기 호출
- timetable_view.dart: 교시→시간 매핑, 급식 첫 메뉴 점심 행 표시

### 1.5. 비주얼 정밀 보정
상태: **완료** ✓
- bottom_nav_bar.dart: minWidth 46→52, padding horizontal 8→10

### 5. 연속 보기 (ContinuousMonthView)
상태: **완료** ✓
- continuous_month_view.dart: PageView.builder + PageController 기반 무한 월간 스크롤
- _pageToYearMonth / _yearMonthToPage: 월 산술 계산
- ref.listen<ViewState>: 외부 nav 변경 시 PageController 동기화 (피드백 루프 차단)
- main_shell.dart: settings.continuousView에 따라 MonthView ↔ ContinuousMonthView 전환

### 6. 이미지 저장 / 공유
상태: **완료** ✓
- screenshot_util.dart: captureAndShare() — RepaintBoundary → PNG → share_plus
- app_header.dart: iOS 공유 아이콘 버튼 추가
- main_shell.dart: RepaintBoundary(key: screenshotKey) 래핑

### 7. 클라우드 백업 (Supabase)
상태: **완료** ✓
- backup_modal.dart: 로그인 시 클라우드 동기화 섹션 추가
- _cloudPush: EventsSync + UserDataSync 업로드
- _cloudPull: UserDataSync 다운로드 + provider 무효화

### 9. 테마 공유 Supabase
상태: **완료** ✓
- theme_share_service.dart: shareTheme (upload) / fetchByCode (download)
- theme_manager_modal.dart: 공유 버튼, 초대 코드 배지, 가져오기 다이얼로그

### 10. 생일 연락처
상태: **완료** ✓
- birthdays_provider.dart: BirthdaysNotifier — addAll/remove/clear/eventsForYear
- vcf_parser.dart: FN/N/BDAY(YYYYMMDD, MMDD) 파싱
- sidebar_drawer.dart: .vcf 파일 선택 → parseVcf → addAll
- month_view.dart + continuous_month_view.dart: 🎂 생일 이벤트 filteredEvents에 병합

### 8. Hero 전환 애니메이션
상태: 스킵 (기존 AnimatedSwitcher + SlideTransition으로 충분)

### 11. 튜토리얼 coach mark
상태: 대기

### 12. (선택) 월간 주 단위 스냅
상태: 대기

### 13. 캘린더 헤더 UX 통합 (뷰 전환 단순화)
상태: **완료** ✓ (flutter analyze 0 경고)
- view_segment_control.dart (신규): 통합 세그먼트 `연·월·주·일`. 탭 1번 전환.
  연=year, 월=events, 주=planner(setWeekView), 일=day(setDayView). 현재 모드 active.
- AppHeader(월/연)·planner `_WeekNav`(주)·day_view 헤더가 동일 `ViewSegmentControl` 공유.
- app_top_bar.dart: 떠 있던 `more_vert` 뷰전환 버튼 + `showViewSwitcher` 바텀시트 + `_ViewSwitcherSheet` 제거 → 오버레이는 상태바 블러만(빈 띠 제거).
- main_shell.dart: 상단 reserve = topInset만(`topBarHasButtons`/`kTopBarButtonH` 제거). planner/day 필터칩을 각 뷰 헤더 안으로 이동(헤더 한 묶음).
- bottom_nav_bar.dart: 캘린더 탭 → 캘린더 계열(events/year/planner/day) 안이어도 탭하면 월간(events) 복귀. day도 active 집합에 포함.
- 디클러터: planner/day의 `ZoomControl`(슬라이더+%) → 컴팩트 `ZoomButton(+/−)`. 날짜 이동 한 줄 유지. day 헤더 back 화살표 제거(세그먼트가 대체).
- ZoomButton: `behavior: HitTestBehavior.opaque` 추가(탭영역 보강).
- 변경: lib/widgets/view_segment_control.dart(신규), app_top_bar.dart, app_header.dart, bottom_nav_bar.dart, zoom_button.dart, main_shell.dart, planner_view.dart, day_view.dart

### 14. 공유 캘린더 화면 2탭 개편 + '테마'→'캘린더' 문구 통일
상태: **완료** ✓ (flutter analyze 0 경고)
- theme_share_page.dart: `DefaultTabController` 2탭(아이콘만, 제목 텍스트 없음).
  탭1=공유 일정(ThemeManagerBody), 탭2=스포츠 구독(SportsSubscriptionSection). 각 탭 Tooltip로 접근성. 큰 제목 제거.
- sports_subscription_section.dart: 상단 "🏟️ 스포츠 구독" 타이틀 행 제거(탭 아이콘 대체).
- theme_manager_modal.dart: "내 캘린더 N개" 요약 제거, `_TipCard`(클래스+사용+local_store/storage_keys import) 전부 제거. 캘린더 이름 폰트 16→20, 행 padding 14→18·margin 10→12. `_chip`(공유/삭제/받기/복제/구독취소) 라벨 없는 40×40 아이콘 버튼화(Tooltip+Semantics 유지). "가져오기" → 54×54 아이콘 버튼(새 캘린더 만들기는 텍스트 CTA 유지).
- 식별자/DB(CalendarTheme·theme_shares·shareCode 등) 변경 없음. 사용자 노출 문자열만 '테마'→'캘린더/공유 캘린더':
  main_shell FAB '테마 일정'→'공유 캘린더', add_edit_event_modal '테마 (여러 개…)'→'캘린더 (여러 개…)', bottom_nav_bar 탭 '테마'→'공유 캘린더', backup_modal 부제 제거, theme_manager_modal 힌트/스낵바('캘린더 이름'·'원본 캘린더'·'내 캘린더로 복제'), coach_mark '(테마)'→'(캘린더)', profile_view·login_screen 동기화 문구, app.dart 구독 스낵바, theme_share_notifications 채널명.

### 15. 스크롤 시 상단 헤더 자동 접힘/펼침
상태: **완료** ✓ (flutter analyze 0 경고)
- header_collapse.dart(신규): `headerCollapsedProvider`(StateProvider<bool>), `CollapseOnScroll`(NotificationListener로 수직 스크롤 방향 감지, 임계값 12px 떨림 방지, 맨 위=항상 펼침, 진입 시 펼침 리셋), `CollapsibleHeader`(AnimatedSize 260ms로 높이 0↔full).
- AppHeader(월/연): 연속 월간에서만 접힘(고정 월간/연간은 스크롤 없어 항상 펼침), 검색 입력 중엔 항상 펼침(게이트).
- continuous_week_view: 스크롤 리스트를 CollapseOnScroll로 감쌈 → AppHeader 접힘 구동.
- planner_view·day_view: 헤더(세그먼트+이동+필터칩)를 CollapsibleHeader로 묶고 전체를 CollapseOnScroll로 감쌈.
- 오버레이 상단바(status bar 블러)·topInset reserve·하단 글래스 네비 충돌 없음. 버튼 없이 스크롤만으로 동작.

### 16. 기록 템플릿 에디터 디자인 정리(아이콘 세트 + 입력칸 단일배경)
상태: **완료** ✓ (flutter analyze 0 경고)
- record_glyph.dart(신규): 큐레이션 라인 아이콘 15종(menu_book·auto_stories·fitness_center·directions_run·self_improvement·water_drop·bedtime·restaurant·medication·music_note·palette·edit_note·timer·local_fire_department·star) + `recordGlyph(value,size,color,faint)` — 아이콘 id면 단색 Icon, 아니면 이모지 Text 폴백.
- record_template_edit_sheet.dart: raw 이모지 그리드 → 단색 아이콘 타일(정사각 라운드, 비선택 card2+inkSoft, 선택 accent 링/틴트, 46px 일정 간격). 입력칸(이름·라벨·단위·태그라벨) 2겹 배경 수정 — `filled:false`+`enabled/focusedBorder:none`+`contentPadding:0`로 컨테이너 단일 배경(검색바 패턴).
- 모델 호환: RecordTemplate.emoji 필드 유지(신규=아이콘 id 저장, 기존 이모지 데이터는 폴백 표시). 프리셋(공부=menu_book/독서=auto_stories/운동=directions_run)도 아이콘 id로.
- 렌더 일원화: day_cell 뱃지·day_action_sheet·record_entry_sheet·record_template_sheet 전부 `recordGlyph` 사용. 아이콘 색은 셀/템플릿 색(accent·inkSoft) 따름, 기록 없으면 faint.
- 참고: day_widgets/widget_cell_renderer.dart는 레거시 위젯(DayField)용 — 기록 템플릿 글리프는 day_cell 뱃지에서 그림(거기 업데이트).

### 17. 월간 캘린더 일정 = 가로 색 바(span) + 탭 펼침
상태: **완료** ✓ (flutter analyze 0 경고)
- multiday_span.dart: `WeekBar`/`computeWeekBars` 추가 — 모든 일정(+할일, 단일일 포함)을 색 바로, 연속 동일 제목은 하나의 긴 바, 겹침은 레인 패킹. 기존 computeDaySpans(타뷰용)는 보존.
- month_grid.dart: StatefulWidget화. 평소엔 **얇은 색 바(높이4, 이름 없이 색만)**, 다일 연속 바, 셀당 최대 N레인 + 초과 `+N`. DayCell은 events 비워 칩 미표시(날짜·기록뱃지·격자만).
- 탭 펼침: 날짜/주 탭 → 그 주 바들이 **라벨 패널(두꺼운 바 + 이름)**로 팝오버 확장(fade+scale 220ms). 라벨 바 탭 → onDayTap(상세/액션시트). 바깥 탭 → 접힘.
- 기록 템플릿 뱃지는 셀 상단 얇은 줄 유지(바와 영역 분리). 필터/색 체계·다크 일관.

### 18. 헤더 스크롤 동작 + 월/연/주/일 헤더 통일
상태: **완료** ✓ (flutter analyze 0 경고)
- header_collapse.dart: 펼침을 '맨 위로 끌어올렸을 때(px≤4)'만 — 위로 스크롤 도중엔 헤더 안 나옴(아래로 충분히=접힘, 위로는 펼치지 않음).
- app_header.dart(월/연): 검색바·세그먼트 별행 제거 → 주/일(_WeekNav)과 동일한 단일 행 `‹ 날짜 › + 세그먼트(150) + ⋮` + 필터칩(접힘). 검색은 ⋮ → showSearchSheet(시트). 네비 행 항상 보임. ConsumerWidget화.
- planner ⋮에도 '일정 검색' 추가(일관). → 4뷰 헤더 배치 통일로 전환 튐 완화.

### 19. 주간 뷰 = 3일 가로 연속 스크롤(전면 재작성) + 자기검토 수정
상태: **완료** ✓ (flutter analyze 0 경고)
- planner_view.dart 재작성: 한 화면 3일(넓은 컬럼), 가로 무한 연속 스크롤. 시간축 좌측 고정(sticky), 날짜 헤더 가로 동기 스크롤, 세로(시간)/가로(날짜) 독립.
- 이벤트 블록 재디자인: 좌측 색 띠 + 아이콘(스포츠 이모지/학사·생일/일반) + 제목 + 시간. 짧으면 1줄, 길면 2줄+시간. 겹침은 클러스터 레인 좌우 분할. 탭 → 상세/편집.
- 줌(±) 유지, 진입 시 오늘 왼쪽 + 현재시각 스크롤, 현재시각선, 종일=헤더 밴드(1칩+N), 시간표 오버레이.
- 자기검토 수정: ① 제목을 ValueNotifier로 → 가로 스크롤 중 그리드 리빌드 제거(잔렉 해결). ② 빈 칸 탭 → 그 날 일간 뷰(회귀 복구). ③ 하루 단위 스냅 physics → 컬럼 반쯤 잘려 멈추지 않게.
- 아젠다(리스트) 뷰는 선택사항이라 보류.

### 20. 기숙사 급식 3끼 + 시간표 병합 + 주 시작일 + 헤더 일(日)뷰 통일
상태: **완료** ✓ (flutter analyze 0 경고)
- 급식 3끼(기숙사): neis_service.dart에 `SchoolMeals`(조/중/석)·`fetchMeals`(MMEAL_SC_CODE 1/2/3 분기)·`_cleanMenu` 추가, `fetchLunch`는 중→조→석 폴백으로 유지(타뷰 호환). home_view `_MealCard`가 끼니 여러 개면 라벨(🌅조식/🍱중식/🌙석식)로, 1개면 라벨 없이 렌더. 홈에만 표시.
- 시간표 병합: `_computeMerges` 비교 키를 `getDisplaySubjectName(...).replaceAll(\s+,'')`로 — 공백 차이("아침운동"/"아침 운동")도 같은 과목으로 세로 병합.
- 주 시작일: 주(planner) 좌측 첫 칸을 '오늘'이 아니라 **이번 주 시작일(설정 weekStartDow, 기본 월)**에 정렬(`_anchor=_weekStart(today)`). '오늘' 버튼은 오늘 칸으로 점프. 무한 연속 스크롤·스냅 유지.
- 헤더 통일: 월/연(app_header)·주(_PlannerNav)를 **일 뷰 구조**로 — 1행 세그먼트 풀폭 + 2행 날짜(좌, 탭→오늘)·컨트롤(우, 화살표+⋮). 패딩 (lg,xs,lg,sm)/(lg,0,lg,sm)로 4뷰 일치.
