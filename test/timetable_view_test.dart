import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:surlap/core/constants/color_presets.dart';
import 'package:surlap/core/theme/app_theme.dart';
import 'package:surlap/screens/timetable_view/timetable_agenda_view.dart';
import 'package:surlap/screens/timetable_view/quick_timetable_editor.dart';
import 'package:surlap/storage/local_store.dart';

void main() {
  test('Excel 시간표 표를 월~금 교시 데이터로 변환한다', () {
    final cells = parseTimetableGrid(
      '교시\t월\t화\t수\t목\t금\n'
      '1교시\t국어\t영어\t수학\t과학\t체육\n'
      '2교시\t음악\t미술\t국어\t영어\t수학',
    );

    expect(cells[(0, 1)], '국어');
    expect(cells[(4, 1)], '체육');
    expect(cells[(0, 2)], '음악');
    expect(cells[(4, 2)], '수학');
  });

  // 데이터(template/NEIS/override)가 전혀 없어도 그리드 틀(요일 헤더 + 교시 행)이
  // 항상 그려져야 하고, 세로 스크롤 안 Row의 stretch가
  // "BoxConstraints forces an infinite height"로 터지지 않아야 한다.
  testWidgets('시간표 뷰는 데이터가 비어도 그리드 틀을 무한높이 크래시 없이 그린다', (tester) async {
    SharedPreferences.setMockInitialValues({}); // 빈 저장소 = 데이터 없음
    await LocalStore.init();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(kDefaultPreset),
          home: const Scaffold(
            // 앱과 동일하게 Expanded 안에 배치(상단 바운드 높이 제공)
            body: SafeArea(
              child: Column(children: [Expanded(child: TimetableAgendaView())]),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // 1) 렌더 도중 예외(무한 높이 등)가 없어야 한다.
    expect(tester.takeException(), isNull);

    // 2) Artifact v2.1의 06–24시 단일 날짜 축이 그려진다.
    expect(find.text('06:00'), findsOneWidget);
    expect(find.text('24:00'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.byKey(const ValueKey('timetable_quick_edit')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('timetable_quick_edit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timetable_excel_paste')), findsOneWidget);
    expect(find.byKey(const ValueKey('timetable_save_all')), findsOneWidget);
  });
}
