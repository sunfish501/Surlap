import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:surlap/core/constants/color_presets.dart';
import 'package:surlap/core/theme/app_theme.dart';
import 'package:surlap/modals/add_edit_event_modal.dart';
import 'package:surlap/providers/color_preset_provider.dart';
import 'package:surlap/screens/home_view/home_view.dart';
import 'package:surlap/screens/main_shell.dart';
import 'package:surlap/screens/profile_view.dart';
import 'package:surlap/screens/search_view.dart';
import 'package:surlap/screens/theme_share_page.dart';
import 'package:surlap/screens/timetable_view/timetable_agenda_view.dart';
import 'package:surlap/screens/year_view/year_view.dart';
import 'package:surlap/storage/local_store.dart';
import 'package:surlap/widgets/view_segment_control.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(kDefaultPreset),
          home: const MainShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
  }

  void expectMinimumTapSize(
    WidgetTester tester,
    Finder finder, {
    String? reason,
  }) {
    expect(finder, findsWidgets, reason: reason);
    for (var index = 0; index < finder.evaluate().length; index++) {
      final size = tester.getSize(finder.at(index));
      expect(size.width, greaterThanOrEqualTo(44), reason: reason);
      expect(size.height, greaterThanOrEqualTo(44), reason: reason);
    }
  }

  testWidgets('핵심 화면은 실제 탭으로 이동하고 검색·FAB·모달 닫기가 동작한다', (tester) async {
    await pumpShell(tester);
    expect(find.byType(HomeView), findsOneWidget);

    await openDrawer(tester);
    await tester.tap(find.text('캘린더'));
    await tester.pumpAndSettle();
    expect(find.byType(ViewSegmentControl), findsOneWidget);

    final yearButton = find.descendant(
      of: find.byType(ViewSegmentControl),
      matching: find.text('년'),
    );
    await tester.tap(yearButton);
    await tester.pumpAndSettle();
    expect(find.byType(YearView), findsOneWidget);

    await tester.tap(find.byTooltip('검색'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchView), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.byType(YearView), findsOneWidget);

    await openDrawer(tester);
    await tester.tap(find.text('시간표'));
    await tester.pumpAndSettle();
    expect(find.byType(TimetableAgendaView), findsOneWidget);

    await openDrawer(tester);
    await tester.tap(find.text('공유 및 구독'));
    await tester.pumpAndSettle();
    expect(find.byType(ThemeSharePage), findsOneWidget);

    await openDrawer(tester);
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileView), findsOneWidget);

    await openDrawer(tester);
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeView), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(AddEditEventModal), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(AddEditEventModal), findsNothing);
  });

  testWidgets('전역 내비게이션·검색·일정 시트 터치 영역은 최소 44dp다', (tester) async {
    await pumpShell(tester);

    expectMinimumTapSize(tester, find.byTooltip('메뉴 열기'));
    expectMinimumTapSize(tester, find.byTooltip('검색'));
    expectMinimumTapSize(tester, find.byType(FloatingActionButton));

    await openDrawer(tester);
    final drawerTaps = find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(InkWell),
    );
    expectMinimumTapSize(
      tester,
      drawerTaps,
      reason: '드로어의 모든 목적지와 다크 모드 행은 44dp 이상이어야 한다.',
    );

    final scope = ProviderScope.containerOf(
      tester.element(find.byType(MainShell)),
    );
    final beforeDark = scope.read(colorPresetProvider).dark;
    await tester.tap(find.text('다크 모드'));
    await tester.pumpAndSettle();
    expect(scope.read(colorPresetProvider).dark, isNot(beforeDark));

    await tester.tap(find.text('캘린더'));
    await tester.pumpAndSettle();
    final segmentTaps = find.descendant(
      of: find.byType(ViewSegmentControl),
      matching: find.byType(InkWell),
    );
    expectMinimumTapSize(tester, segmentTaps);

    await tester.tap(find.byTooltip('검색'));
    await tester.pumpAndSettle();
    expectMinimumTapSize(tester, find.byType(ChoiceChip));
    expectMinimumTapSize(tester, find.byType(ActionChip));
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expectMinimumTapSize(tester, find.byTooltip('닫기'));

    final timeButtons = find.ancestor(
      of: find.text('--:--'),
      matching: find.byType(InkWell),
    );
    expectMinimumTapSize(tester, timeButtons);

    final dateTap = find.ancestor(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(widget.data!),
      ),
      matching: find.byType(GestureDetector),
    );
    expectMinimumTapSize(tester, dateTap);

    final moreButton = find.widgetWithText(TextButton, '추가 옵션');
    await tester.tap(moreButton);
    await tester.pumpAndSettle();
    expect(find.text('옵션 접기'), findsOneWidget);
    final recurTap = find.ancestor(
      of: find.text('없음'),
      matching: find.byType(InkWell),
    );
    expectMinimumTapSize(tester, recurTap);

    final titleField = find.byType(TextField).first;
    await tester.enterText(titleField, '내일 3시 회의');
    await tester.pump();
    expectMinimumTapSize(tester, find.byTooltip('제안 닫기'));

    final modalScroll = find.descendant(
      of: find.byType(AddEditEventModal),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(modalScroll, const Offset(0, -600));
    await tester.pumpAndSettle();
    final cancelButton = find.widgetWithText(OutlinedButton, '취소');
    expect(cancelButton.hitTestable(), findsOneWidget);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    expect(find.byType(AddEditEventModal), findsNothing);
  });
}
