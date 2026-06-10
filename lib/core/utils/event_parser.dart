import 'date_utils.dart' as du;
import 'todo_parser.dart' show parseTodoInput;

/// 자연어 일정 입력 파싱 결과.
///
/// 예: "내일 3시 회의" → date=내일, tm="15:00", title="회의"
///     "월요일 9시-10시 운동" → date=월, tm="09:00", te="10:00", title="운동"
///     "오후 2시반 미팅" → date=null, tm="14:30", title="미팅"
class ParsedEvent {
  final String? dateKey;
  final String? tm; // HH:MM 24h
  final String? te; // HH:MM 24h
  final String title;
  const ParsedEvent({this.dateKey, this.tm, this.te, required this.title});
}

ParsedEvent parseEventInput(String input, {DateTime? now}) {
  if (input.trim().isEmpty) return const ParsedEvent(title: '');
  // 1) 날짜 + 우선순위 토큰은 todo_parser로 위임 → 본문(content)을 받아 이어서 시간 파싱.
  final t = parseTodoInput(input, now: now);
  var text = t.content;
  String? tm, te;

  // 2) 시간 범위: "9시-10시" / "9시~10시" / "9시 ~ 10시 30분" / "9:00-10:30"
  final rangeRe = RegExp(
    r'(?:^|\s)'
    r'(?:(오전|오후|아침|점심|저녁|밤)\s*)?'
    r'(\d{1,2})(?:[:시]\s*(\d{1,2})?\s*분?)?'
    r'\s*[-~]\s*'
    r'(?:(오전|오후|아침|점심|저녁|밤)\s*)?'
    r'(\d{1,2})(?:[:시]\s*(\d{1,2})?\s*분?)?'
    r'(?=\s|$)',
  );
  final r = rangeRe.firstMatch(text);
  if (r != null) {
    final sH = _hour(r.group(2)!, r.group(1));
    final sM = int.tryParse(r.group(3) ?? '0') ?? 0;
    final eH = _hour(r.group(5)!, r.group(4) ?? r.group(1));
    final eM = int.tryParse(r.group(6) ?? '0') ?? 0;
    if (sH != null && eH != null) {
      tm = _fmt(sH, sM);
      te = _fmt(eH, eM);
      text = text.replaceRange(r.start, r.end, ' ');
    }
  }

  // 3) 단일 시각: "3시", "오후 3시", "3시 반", "3:30", "15:30"
  if (tm == null) {
    final single = RegExp(
      r'(?:^|\s)'
      r'(?:(오전|오후|아침|점심|저녁|밤)\s*)?'
      r'(\d{1,2})(?:[:시])\s*(\d{1,2})?\s*(반|분)?'
      r'(?=\s|$)',
    ).firstMatch(text);
    if (single != null) {
      final h = _hour(single.group(2)!, single.group(1));
      var m = int.tryParse(single.group(3) ?? '0') ?? 0;
      if (single.group(4) == '반' && (single.group(3) == null)) m = 30;
      if (h != null) {
        tm = _fmt(h, m);
        text = text.replaceRange(single.start, single.end, ' ');
      }
    }
  }

  final title = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return ParsedEvent(
    dateKey: t.dateKey,
    tm: tm,
    te: te,
    title: title.isEmpty ? input.trim() : title,
  );
}

int? _hour(String hStr, String? meridian) {
  var h = int.tryParse(hStr);
  if (h == null) return null;
  if (h < 0 || h > 23) return null;
  if (meridian == null) return h;
  // 오후/저녁/밤 12-23, 오전/아침 0-11. "점심"≈12.
  if (meridian == '오후' || meridian == '저녁' || meridian == '밤') {
    if (h < 12) h += 12;
  } else if (meridian == '점심') {
    if (h < 12) h = 12;
  } else {
    // 오전/아침 — 12를 0시로 정규화(드물지만 "오전 12시"=00:00)
    if (h == 12) h = 0;
  }
  return h;
}

String _fmt(int h, int m) =>
    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

// 외부에서 todo_parser의 dateKey 그대로 쓰지 못할 때 동일 base로 다시 계산하고 싶을 때 호출.
String todayKey() => du.toDateKey(DateTime.now());
