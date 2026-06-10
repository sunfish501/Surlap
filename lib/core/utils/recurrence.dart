/// 일정 반복 규칙 — 직렬화 가능한 단순한 RRULE 서브셋.
///
/// JSON 형태 (EventItem.rr 필드):
/// ```
/// { "f": "W"|"M"|"Y", "i": 1, "u": "YYYY-MM-DD"?, "c": int? }
/// ```
///  - `f` 주기: W=매주, M=매월, Y=매년
///  - `i` 간격: 기본 1 (예: 2면 격주)
///  - `u` 종료일(inclusive): null이면 무기한
///  - `c` 횟수: null이면 무기한
class Recurrence {
  final String freq; // 'W' | 'M' | 'Y'
  final int interval;
  final String? until; // YYYY-MM-DD
  final int? count;

  const Recurrence({
    required this.freq,
    this.interval = 1,
    this.until,
    this.count,
  });

  bool get isValid =>
      (freq == 'W' || freq == 'M' || freq == 'Y') && interval >= 1;

  Map<String, dynamic> toJson() => {
        'f': freq,
        if (interval != 1) 'i': interval,
        if (until != null) 'u': until,
        if (count != null) 'c': count,
      };

  static Recurrence? fromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final f = raw['f']?.toString();
    if (f != 'W' && f != 'M' && f != 'Y') return null;
    return Recurrence(
      freq: f!,
      interval: (raw['i'] is int) ? raw['i'] as int : 1,
      until: raw['u'] as String?,
      count: (raw['c'] is int) ? raw['c'] as int : null,
    );
  }
}

/// `anchor`에서 시작한 반복 일정이 `query` 날짜에 발생하는지 판정.
///  - 같은 날(앵커 본인)도 true.
///  - `until`/`count` 종료 조건 적용.
bool occursOn(Recurrence rr, DateTime anchor, DateTime query) {
  if (!rr.isValid) return false;
  final a = DateTime(anchor.year, anchor.month, anchor.day);
  final q = DateTime(query.year, query.month, query.day);
  if (q.isBefore(a)) return false;
  if (rr.until != null) {
    try {
      final u = DateTime.parse(rr.until!);
      if (q.isAfter(DateTime(u.year, u.month, u.day))) return false;
    } catch (_) {}
  }

  int n; // 앵커로부터 N번째 발생
  switch (rr.freq) {
    case 'W':
      if (a.weekday != q.weekday) return false;
      final days = q.difference(a).inDays;
      if (days % (7 * rr.interval) != 0) return false;
      n = days ~/ (7 * rr.interval);
      break;
    case 'M':
      if (a.day != q.day) return false;
      final months = (q.year - a.year) * 12 + (q.month - a.month);
      if (months < 0 || months % rr.interval != 0) return false;
      n = months ~/ rr.interval;
      break;
    case 'Y':
      if (a.month != q.month || a.day != q.day) return false;
      final years = q.year - a.year;
      if (years < 0 || years % rr.interval != 0) return false;
      n = years ~/ rr.interval;
      break;
    default:
      return false;
  }
  if (rr.count != null && n >= rr.count!) return false;
  return n >= 0;
}
