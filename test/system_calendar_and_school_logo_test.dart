import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surlap/models/calendar_theme.dart';
import 'package:surlap/providers/holidays_provider.dart';
import 'package:surlap/providers/academic_schedule_provider.dart';
import 'package:surlap/supabase/neis_service.dart';
import 'package:surlap/widgets/school_logo.dart';

void main() {
  test('holiday calendar is canonical and excluded from user themes', () {
    const customHoliday = CalendarTheme(
      id: holidayThemeId,
      name: '변경된 공휴일',
      color: '#000000',
    );
    const userTheme = CalendarTheme(
      id: 'school-events',
      name: '학교 일정',
      color: '#123456',
    );

    final normalized = withSystemCalendarThemes([customHoliday, userTheme]);

    expect(normalized, [holidayCalendarTheme, userTheme]);
    expect(userCalendarThemes(normalized), [userTheme]);
  });

  test('school profile retains real logo URL data', () {
    const school = NeisSchool(
      name: '테스트학교',
      code: '1',
      officeCode: '2',
      kind: '고등학교',
      grade: 1,
      classNm: 2,
      logoOverride: 'https://school.example/logo.png',
    );

    final restored = NeisSchool.fromJson(school.toJson());

    expect(restored.logoUrl, 'https://school.example/logo.png');
    expect(school.toJson()['logoUrl'], 'https://school.example/logo.png');
  });

  test('official school emblem metadata wins over a generic favicon', () {
    const html = '''
      <html><head><link rel="icon" href="/favicon.ico"></head>
      <body>
        <img class="school-logo" alt="테스트학교 교표" src="/assets/emblem.png">
      </body></html>
    ''';

    final logo = extractOfficialSchoolLogoUrl(
      html,
      Uri.parse('https://school.example/main/index.html'),
      '테스트학교',
    );

    expect(logo, 'https://school.example/assets/emblem.png');
  });

  test('reader Markdown can provide the official school emblem', () {
    const markdown = '''
![행사 배너](https://school.example/banner/summer.png)
![테스트학교 교표](https://school.example/assets/emblem.png)
![학교 전경](https://school.example/assets/building.jpg)
''';

    expect(
      extractOfficialSchoolLogoFromMarkdown(markdown, '테스트학교'),
      'https://school.example/assets/emblem.png',
    );
  });

  test('academic schedule wording is student friendly', () {
    expect(friendlyAcademicScheduleName('학교장재량휴업일'), '학교 쉬는 날');
    expect(friendlyAcademicScheduleName('여름방학식'), '여름방학 시작');
    expect(friendlyAcademicScheduleName('1학기 1차 지필평가'), '1학기 중간고사');
    expect(friendlyAcademicScheduleName('전국연합학력평가'), '전국연합 모의고사');
  });

  testWidgets('school logo has a 44dp offline building fallback', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SchoolLogo(name: '테스트학교', logoUrl: null)),
      ),
    );

    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    expect(find.text('테'), findsNothing);
    expect(tester.getSize(find.byType(SchoolLogo)), const Size.square(44));
    expect(find.bySemanticsLabel('테스트학교 학교 로고'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('school logo falls back after network image errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SchoolLogo(
            name: '테스트학교',
            logoUrl: 'https://school.invalid/logo.png',
            fallbackUrl: 'https://school.invalid/favicon.png',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    expect(find.text('테'), findsNothing);
  });
}
