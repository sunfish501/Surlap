import 'package:flutter_test/flutter_test.dart';
import 'package:surlap/providers/birthdays_provider.dart';

void main() {
  // 기준일 2026-06-04
  final base = DateTime(2026, 6, 4);
  Birthday bd(int m, int d) =>
      Birthday(id: 'x', name: 'n', month: m, day: d);

  group('Birthday.daysUntilNext', () {
    test('오늘이면 0', () {
      expect(bd(6, 4).daysUntilNext(base), 0);
    });
    test('내일이면 1', () {
      expect(bd(6, 5).daysUntilNext(base), 1);
    });
    test('어제면 내년까지 (364일)', () {
      // 2026-06-03 이미 지남 → 2027-06-03
      expect(bd(6, 3).daysUntilNext(base), 364);
    });
    test('2/29는 비윤년이면 2/28로 보정', () {
      // 2027은 비윤년 → 2027-02-28
      final r = bd(2, 29).daysUntilNext(base);
      expect(r, DateTime(2027, 2, 28).difference(DateTime(2026, 6, 4)).inDays);
    });
  });
}
