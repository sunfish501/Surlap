import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surlap/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('온보딩 3장: 다음으로 진행, 마지막에 시작하기 → onDone', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(onDone: () => done = true),
    ));

    // 1장
    expect(find.text('하루를 한눈에'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
    expect(find.text('시작하기'), findsNothing);

    // '다음' → 2장
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('시간이 보여요'), findsOneWidget);

    // '다음' → 3장 (마지막): 버튼이 '시작하기'
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('이제 시작할 시간'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);

    // '시작하기' → onDone 호출
    expect(done, isFalse);
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('스와이프로도 넘어간다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(onDone: () {}),
    ));
    expect(find.text('하루를 한눈에'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('시간이 보여요'), findsOneWidget);
  });
}
