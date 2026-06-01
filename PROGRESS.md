# 무인 작업 진행 기록

## 최종 요약 (작업 완료 후 여기에 씀)
_작업 완료 후 업데이트 예정_

---

## 진행 기록

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
