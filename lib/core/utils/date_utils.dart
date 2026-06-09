import '../../i18n/dates.dart' as i18nd;

String pad(int n) => n.toString().padLeft(2, '0');

/// DateTime → 'YYYY-MM-DD'
String toDateKey(DateTime d) =>
    '${d.year}-${pad(d.month)}-${pad(d.day)}';

/// 'YYYY-MM-DD' → DateTime (시간 00:00:00)
DateTime fromDateKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// 오늘 날짜 키
String todayKey() => toDateKey(DateTime.now());

/// 두 날짜가 같은 날인지
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 해당 월의 첫 번째 날 (요일 기준 셀 시작)
/// weekStartDow: 0=일, 1=월, 6=토
DateTime firstCellDate(int year, int month, int weekStartDow) {
  final first = DateTime(year, month, 1);
  int offset = (first.weekday % 7) - weekStartDow;
  if (offset < 0) offset += 7;
  return first.subtract(Duration(days: offset));
}

/// 월의 마지막 날
DateTime lastDayOfMonth(int year, int month) =>
    DateTime(year, month + 1, 0);

/// 요일 짧은 이름 (주 시작에 따라 순서 달라짐, 현재 언어로 표기)
List<String> weekdayHeaders(int weekStartDow) {
  final list = <String>[];
  for (int i = 0; i < 7; i++) {
    // (weekStartDow+i)%7 은 0=일 기준 인덱스.
    list.add(i18nd.weekdayShortFromSun((weekStartDow + i) % 7));
  }
  return list;
}

/// 해당 요일이 토요일(6) 또는 일요일(0)인지
bool isSaturday(DateTime d) => d.weekday == DateTime.saturday;
bool isSunday(DateTime d)   => d.weekday == DateTime.sunday;
