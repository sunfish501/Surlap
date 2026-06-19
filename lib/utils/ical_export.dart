import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event_item.dart';

/// RFC 5545(.ics) 단순 export — VEVENT 직렬화 + share_plus 공유.
/// 지원: SUMMARY/DTSTART/DTEND/UID/RRULE(W·M·Y), all-day와 시각 있는 이벤트.
class IcalExport {
  IcalExport._();

  static String buildIcs(Map<String, List<EventItem>> events,
      {String calName = 'Surlap'}) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Surlap//KO',
      'CALSCALE:GREGORIAN',
      'X-WR-CALNAME:$calName',
    ];
    var seq = 0;
    events.forEach((dateKey, list) {
      DateTime d;
      try {
        d = DateTime.parse(dateKey);
      } catch (_) {
        return;
      }
      for (final e in list) {
        if (e.isTimetable || e.academic || e.birthday || e.sport) continue;
        lines.addAll(_vevent(e, d, seq++));
      }
    });
    lines.add('END:VCALENDAR');
    return lines.join('\r\n');
  }

  static List<String> _vevent(EventItem e, DateTime date, int seq) {
    final uid = e.id ?? 'hs-${date.toIso8601String()}-$seq@hourspace';
    final summary = _escape(e.t);
    final out = <String>['BEGIN:VEVENT', 'UID:$uid', 'SUMMARY:$summary'];

    if (e.hasTime) {
      final s = _parseTime(e.tm!);
      if (s != null) {
        final start = DateTime(date.year, date.month, date.day, s.$1, s.$2);
        out.add('DTSTART:${_fmtLocal(start)}');
        if (e.te != null) {
          final en = _parseTime(e.te!);
          if (en != null) {
            final end = DateTime(date.year, date.month, date.day, en.$1, en.$2);
            out.add('DTEND:${_fmtLocal(end)}');
          }
        }
      }
    } else {
      out.add('DTSTART;VALUE=DATE:${_fmtDate(date)}');
      out.add('DTEND;VALUE=DATE:${_fmtDate(date.add(const Duration(days: 1)))}');
    }

    final rr = e.rr;
    if (rr != null) {
      final f = rr['f']?.toString();
      if (f == 'W' || f == 'M' || f == 'Y') {
        final freq = f == 'W'
            ? 'WEEKLY'
            : f == 'M'
                ? 'MONTHLY'
                : 'YEARLY';
        final parts = <String>['FREQ=$freq'];
        if (rr['i'] is int && rr['i'] != 1) parts.add('INTERVAL=${rr['i']}');
        final until = rr['u'] as String?;
        if (until != null) {
          try {
            final u = DateTime.parse(until);
            final endOfDay =
                DateTime.utc(u.year, u.month, u.day, 23, 59, 59);
            parts.add('UNTIL=${_fmtUtc(endOfDay)}');
          } catch (_) {}
        }
        if (rr['c'] is int) parts.add('COUNT=${rr['c']}');
        out.add('RRULE:${parts.join(';')}');
      }
    }

    out.add('END:VEVENT');
    return out;
  }

  static (int, int)? _parseTime(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  static String _fmtLocal(DateTime d) =>
      '${_fmtDate(d)}T${d.hour.toString().padLeft(2, '0')}'
      '${d.minute.toString().padLeft(2, '0')}00';

  static String _fmtUtc(DateTime d) => '${_fmtLocal(d)}Z';

  static String _escape(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('\n', '\\n').replaceAll(',', '\\,').replaceAll(';', '\\;');

  /// 파일로 저장 후 OS 공유 시트 호출.
  static Future<void> exportAndShare(
      Map<String, List<EventItem>> events) async {
    final ics = buildIcs(events);
    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final fname = 'Surlap_${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}.ics';
    final file = File('${dir.path}/$fname');
    await file.writeAsString(ics);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/calendar')],
      text: 'Surlap 일정 (iCal)',
    );
  }
}
