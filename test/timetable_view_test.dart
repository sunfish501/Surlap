import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spacehour/core/constants/color_presets.dart';
import 'package:spacehour/core/theme/app_theme.dart';
import 'package:spacehour/screens/timetable_view/timetable_view.dart';
import 'package:spacehour/storage/local_store.dart';

void main() {
  // 데이터(template/NEIS/override)가 전혀 없어도 그리드 틀(요일 헤더 + 교시 행)이
  // 항상 그려져야 하고, 세로 스크롤 안 Row의 stretch가
  // "BoxConstraints forces an infinite height"로 터지지 않아야 한다.
  testWidgets('시간표 뷰는 데이터가 비어도 그리드 틀을 무한높이 크래시 없이 그린다',
      (tester) async {
    SharedPreferences.setMockInitialValues({}); // 빈 저장소 = 데이터 없음
    await LocalStore.init();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(kDefaultPreset),
          home: const Scaffold(
            // 앱과 동일하게 Expanded 안에 배치(상단 바운드 높이 제공)
            body: SafeArea(
              child: Column(
                children: [Expanded(child: TimetableView())],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // 1) 렌더 도중 예외(무한 높이 등)가 없어야 한다.
    expect(tester.takeException(), isNull);

    // 2) 요일 헤더가 그려진다.
    expect(find.text('월'), findsWidgets);

    // 3) 교시 행 + 점심 행(빈 격자 틀)이 데이터 없이도 그려진다.
    expect(find.text('1교시'), findsOneWidget);
    expect(find.text('7교시'), findsOneWidget);
    expect(find.text('점심'), findsOneWidget);
  });
}
