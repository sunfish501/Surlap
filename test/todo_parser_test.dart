import 'package:flutter_test/flutter_test.dart';
import 'package:surlap/core/utils/todo_parser.dart';
import 'package:surlap/core/utils/date_utils.dart' as du;

void main() {
  // 고정 기준일: 2026-06-03 (수요일)
  final base = DateTime(2026, 6, 3);
  String key(DateTime d) => du.toDateKey(d);

  group('parseTodoInput', () {
    test('내일 p1 빨래하기', () {
      final r = parseTodoInput('내일 p1 빨래하기', now: base);
      expect(r.dateKey, key(base.add(const Duration(days: 1))));
      expect(r.priority, 1);
      expect(r.content, '빨래하기');
    });

    test('오늘 / 모레 / 글피', () {
      expect(parseTodoInput('오늘 운동', now: base).dateKey, key(base));
      expect(parseTodoInput('모레 회의', now: base).dateKey,
          key(base.add(const Duration(days: 2))));
      expect(parseTodoInput('글피 시험', now: base).dateKey,
          key(base.add(const Duration(days: 3))));
    });

    test('우선순위 표기 다양성', () {
      expect(parseTodoInput('P2 청소', now: base).priority, 2);
      expect(parseTodoInput('우선순위3 정리', now: base).priority, 3);
      expect(parseTodoInput('중요 발표 준비', now: base).priority, 1);
    });

    test('요일 — 다가오는 금요일', () {
      // 기준 수요일(6/3) → 이번 금요일 6/5
      final r = parseTodoInput('금요일 약속', now: base);
      expect(r.dateKey, key(DateTime(2026, 6, 5)));
      expect(r.content, '약속');
    });

    test('요일 — 다음주 월요일', () {
      // 기준 수요일(6/3) → 다음주 월요일 6/8
      final r = parseTodoInput('다음주 월요일 출장', now: base);
      expect(r.dateKey, key(DateTime(2026, 6, 8)));
    });

    test('M월D일 절대 날짜', () {
      final r = parseTodoInput('12월 25일 p1 선물 사기', now: base);
      expect(r.dateKey, key(DateTime(2026, 12, 25)));
      expect(r.priority, 1);
      expect(r.content, '선물 사기');
    });

    test('지난 날짜는 내년으로', () {
      // 기준 6/3 → 1월 1일은 이미 지남 → 2027-01-01
      final r = parseTodoInput('1월 1일 신년 계획', now: base);
      expect(r.dateKey, key(DateTime(2027, 1, 1)));
    });

    test('M/D 표기', () {
      final r = parseTodoInput('7/15 휴가', now: base);
      expect(r.dateKey, key(DateTime(2026, 7, 15)));
      expect(r.content, '휴가');
    });

    test('날짜/우선순위 없으면 본문만', () {
      final r = parseTodoInput('책 읽기', now: base);
      expect(r.dateKey, isNull);
      expect(r.priority, 0);
      expect(r.content, '책 읽기');
    });
  });
}
