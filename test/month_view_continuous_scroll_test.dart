import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surlap/providers/view_provider.dart';
import 'package:surlap/screens/month_view/continuous_month_list.dart';
import 'package:surlap/screens/month_view/month_view.dart';

void main() {
  const itemExtent = 300.0;

  test('calendar data is indexed once by month', () {
    final indexed = indexCalendarItemsByMonth<int>({
      '2026-07-01': [1],
      '2026-07-31': [2],
      '2026-08-01': [3],
      'invalid': [4],
    });

    expect(indexed['2026-07']?.keys, {'2026-07-01', '2026-07-31'});
    expect(indexed['2026-08']?['2026-08-01'], [3]);
    expect(indexed.containsKey('invalid'), isFalse);
  });

  Widget monthItem(BuildContext context, DateTime month) {
    final key = '${month.year}-${month.month}';
    return ColoredBox(
      color: month.month.isEven ? Colors.white : Colors.grey.shade100,
      child: Column(
        children: [Text('title-$key'), const Spacer(), Text('bottom-$key')],
      ),
    );
  }

  Future<void> setViewport(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 220);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('adjacent months remain visible together without snapping', (
    tester,
  ) async {
    await setViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ContinuousMonthList(
          targetMonth: DateTime(2026, 7),
          itemExtent: itemExtent,
          itemBuilder: monthItem,
          onVisibleMonthChanged: (_) {},
        ),
      ),
    );

    final scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    expect(scrollView.controller?.keepScrollOffset, isFalse);

    await tester.timedDrag(
      find.byType(CustomScrollView),
      const Offset(0, -270),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();

    final viewport = Offset.zero & tester.view.physicalSize;
    expect(
      tester.getRect(find.text('bottom-2026-7')).overlaps(viewport),
      isTrue,
    );
    expect(
      tester.getRect(find.text('title-2026-8')).overlaps(viewport),
      isTrue,
    );

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels % itemExtent, isNot(closeTo(0, 0.5)));
  });

  testWidgets('settled visible month synchronizes the header provider', (
    tester,
  ) async {
    await setViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(viewProvider.notifier).setYearMonth(2026, 7);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ContinuousMonthList(
            targetMonth: DateTime(2026, 7),
            itemExtent: itemExtent,
            itemBuilder: monthItem,
            onVisibleMonthChanged: (month) => container
                .read(viewProvider.notifier)
                .setYearMonth(month.year, month.month),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -330));
    await tester.pumpAndSettle();

    final headerState = container.read(viewProvider);
    expect(headerState.viewYear, 2026);
    expect(headerState.viewMonth, 8);
  });
}
