import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:surlap/core/constants/color_presets.dart';
import 'package:surlap/core/constants/storage_keys.dart';
import 'package:surlap/core/theme/app_theme.dart';
import 'package:surlap/core/utils/date_utils.dart' as du;
import 'package:surlap/models/event_item.dart';
import 'package:surlap/models/todo_item.dart';
import 'package:surlap/screens/home_view/home_view.dart';
import 'package:surlap/storage/local_store.dart';
import 'package:surlap/widgets/dark_star_background.dart';

void main() {
  testWidgets('빈 홈은 아이콘과 오늘 콘텐츠 추가 동작을 보여준다', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(kDefaultPreset),
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: HomeView()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('mascot'),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('home_empty_state')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_add_todo')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_add_event')), findsOneWidget);
    expect(find.byKey(const ValueKey('app_dark_star_field')), findsNothing);
  });

  testWidgets('홈은 기존 provider에서 오늘 할 일과 일정을 표시한다', (tester) async {
    final today = du.todayKey();
    SharedPreferences.setMockInitialValues({
      'guest::${StorageKeys.events}': eventsToJson({
        today: const [EventItem(t: 'Provider event', tm: '10:00')],
      }),
      'guest::${StorageKeys.todos}': todosToJson([
        TodoItem(id: 'today-todo', title: 'Provider todo', dateKey: today),
      ]),
    });
    await LocalStore.init();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(kDefaultPreset),
          home: const Scaffold(body: HomeView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Provider event'), findsOneWidget);
    expect(find.text('Provider todo'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_empty_state')), findsNothing);
  });

  testWidgets('다크 홈 별 장식은 모션 감소 설정에서 정지 상태로 그려진다', (tester) async {
    tester.view.physicalSize = const Size(667, 375);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(kDarkPreset),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: DarkStarBackground(child: HomeView())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app_dark_star_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
