import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surlap/screens/onboarding/onboarding_screen.dart';
import 'package:surlap/storage/local_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();
  });

  testWidgets('온보딩 소개와 유형 선택 후 시작하기 → onDone', (tester) async {
    var done = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: OnboardingScreen(onDone: () => done = true)),
      ),
    );

    // 1장
    expect(find.text('학교 시간표·급식,\n자동으로 채워져요'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
    expect(find.text('시작하기'), findsNothing);

    // '다음' → 2장
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('일정·할 일·기록을\n앱 하나로'), findsOneWidget);

    // '다음' → 3장
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 필요한 정보만\n한눈에 보여드려요'), findsOneWidget);

    // 유형 선택 페이지에서 유형을 골라야 시작할 수 있다.
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('어떤 분이세요?'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
    await tester.tap(find.text('중학생'));
    await tester.pump();

    // '시작하기' → onDone 호출
    expect(done, isFalse);
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('스와이프로도 넘어간다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: OnboardingScreen(onDone: () {})),
      ),
    );
    expect(find.text('학교 시간표·급식,\n자동으로 채워져요'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('일정·할 일·기록을\n앱 하나로'), findsOneWidget);
  });
}
