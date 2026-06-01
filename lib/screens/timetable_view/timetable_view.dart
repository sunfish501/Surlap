import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../providers/events_provider.dart';
import '../../storage/local_store.dart';
import '../../core/constants/storage_keys.dart';
import '../../supabase/neis_service.dart';

class TimetableView extends ConsumerStatefulWidget {
  const TimetableView({super.key});

  @override
  ConsumerState<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends ConsumerState<TimetableView> {
  static const _dowNames = ['월', '화', '수', '목', '금', '토', '일'];
  static final _rows = _buildRows();

  // NEIS 캐시: di(0=Mon) → period → subject
  final Map<int, Map<int, String>> _neisData = {};
  // di → lunch text
  final Map<int, String> _neisLunch = {};
  bool _neisFetching = false;

  static List<({String label, int hour, bool isSchool, bool isLunch})>
      _buildRows() {
    final rows =
        <({String label, int hour, bool isSchool, bool isLunch})>[];
    for (int h = 0; h <= 8; h++) {
      rows.add((label: '$h:00', hour: h, isSchool: false, isLunch: false));
    }
    for (int p = 1; p <= 4; p++) {
      rows.add(
          (label: '$p교시', hour: 8 + p, isSchool: true, isLunch: false));
    }
    rows.add((label: '점심', hour: 13, isSchool: false, isLunch: true));
    for (int p = 5; p <= 7; p++) {
      rows.add(
          (label: '$p교시', hour: 9 + p, isSchool: true, isLunch: false));
    }
    for (int h = 17; h <= 23; h++) {
      rows.add((label: '$h:00', hour: h, isSchool: false, isLunch: false));
    }
    return rows;
  }

  @override
  void initState() {
    super.initState();
    _fetchNeisIfNeeded();
  }

  Future<void> _fetchNeisIfNeeded() async {
    final school = NeisSchool.load();
    if (school == null || _neisFetching) return;
    _neisFetching = true;
    final days = _weekDays();
    for (int di = 0; di < 5; di++) {
      // 주중만 (월~금)
      final dk = du.toDateKey(days[di]);
      final dateStr = dk.replaceAll('-', '');
      try {
        final tt = await fetchTimetable(school, dateStr);
        if (tt != null && mounted) {
          setState(() {
            _neisData[di] = tt;
          });
        }
        final lunch = await fetchLunch(school, dateStr);
        if (lunch != null && mounted) {
          setState(() {
            _neisLunch[di] = lunch;
          });
        }
      } catch (_) {
        // 네트워크 오류 무시
      }
    }
    _neisFetching = false;
  }

  List<DateTime> _weekDays() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(
        7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  // freeData[dayIndex][hour] = text (user-entered events)
  Map<int, Map<int, String>> _buildFreeData(
      Map<String, List<EventItem>> events, List<String> dayKeys) {
    final result = <int, Map<int, String>>{};
    for (int di = 0; di < 7; di++) {
      result[di] = {};
      for (final item in (events[dayKeys[di]] ?? [])) {
        if (!item.isTimetable) continue;
        final text = item.t;
        final m = RegExp(r'\((\d{1,2}):(\d{2})\)').firstMatch(text);
        if (m != null) {
          final h = int.parse(m.group(1)!);
          result[di]![h] =
              text.replaceAll(RegExp(r'\(\d{1,2}:\d{2}\)'), '').trim();
        }
      }
    }
    return result;
  }

  // templateData[dayIndex][hour] = subject from timetable template
  Map<int, Map<int, String>> _buildTemplateData(List<DateTime> days) {
    final result = <int, Map<int, String>>{};
    for (int di = 0; di < 7; di++) {
      result[di] = {};
    }

    final rawTpl =
        LocalStore.instance.getString(StorageKeys.timetableTemplate);
    if (rawTpl == null) return result;

    Map<String, dynamic> tpl;
    try {
      tpl = jsonDecode(rawTpl) as Map<String, dynamic>;
    } catch (_) {
      return result;
    }

    final blocks =
        (tpl['blocks'] as List? ?? []).cast<Map<String, dynamic>>();
    final weekdays = (tpl['weekdays'] as List? ?? [0, 1, 2, 3, 4])
        .map((e) => e as int)
        .toSet();
    final startDate = tpl['startDate'] as String?;
    final endDate = tpl['endDate'] as String?;

    Map<String, dynamic> overrides = {};
    final rawOv =
        LocalStore.instance.getString(StorageKeys.timetableOverrides);
    if (rawOv != null) {
      try {
        overrides = jsonDecode(rawOv) as Map<String, dynamic>;
      } catch (_) {}
    }

    for (int di = 0; di < 7; di++) {
      final date = days[di];
      final dow = (date.weekday - 1) % 7; // 0=Mon..6=Sun
      if (!weekdays.contains(dow)) continue;

      final dk = du.toDateKey(date);
      if (startDate != null && dk.compareTo(startDate) < 0) continue;
      if (endDate != null && dk.compareTo(endDate) > 0) continue;

      final ov = overrides[dk] as Map<String, dynamic>? ?? {};
      final hiddenIds = ((ov['hiddenBlockIds'] as List?) ?? [])
          .map((e) => e.toString())
          .toSet();

      for (final b in blocks) {
        if ((b['day'] as int?) != dow) continue;
        final id = b['id']?.toString() ?? '';
        if (hiddenIds.contains(id)) continue;
        final tm = b['tm'] as String? ?? '';
        if (tm.isEmpty) continue;
        final hour = int.tryParse(tm.split(':')[0]) ?? -1;
        if (hour < 0 || hour > 23) continue;
        result[di]![hour] = b['t']?.toString() ?? '';
      }

      final extra =
          (ov['extra'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final e in extra) {
        final tm = e['tm'] as String? ?? '';
        if (tm.isEmpty) continue;
        final hour = int.tryParse(tm.split(':')[0]) ?? -1;
        if (hour < 0 || hour > 23) continue;
        result[di]![hour] = e['t']?.toString() ?? '';
      }
    }

    return result;
  }

  // NEIS period → hour: 1~4교시=9~12, 5~7교시=14~16
  static int _periodToHour(int period) =>
      period <= 4 ? 8 + period : 9 + period;

  // NEIS 데이터를 hour 키로 변환 (period → hour)
  Map<int, Map<int, String>> _buildNeisHourData() {
    final result = <int, Map<int, String>>{};
    _neisData.forEach((di, periodMap) {
      result[di] = {};
      periodMap.forEach((period, subject) {
        final h = _periodToHour(period);
        result[di]![h] = subject;
      });
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final events = ref.watch(eventsProvider);
    final days = _weekDays();
    final dayKeys = days.map(du.toDateKey).toList();
    final freeData = _buildFreeData(events, dayKeys);
    final templateData = _buildTemplateData(days);
    final neisHourData = _buildNeisHourData();
    final now = DateTime.now();

    const timeLblW = 52.0;
    const rowH = 42.0;
    const headerH = 40.0;

    return Column(
      children: [
        // 헤더 행
        SizedBox(
          height: headerH,
          child: Row(
            children: [
              SizedBox(
                width: timeLblW,
                child: Container(
                  color: sh.card2,
                  alignment: Alignment.center,
                  child: Text('시간표',
                      style: TextStyle(fontSize: 10, color: sh.inkFaint)),
                ),
              ),
              ...List.generate(7, (i) {
                final d = days[i];
                final isToday = du.isSameDay(d, now);
                final isSat = d.weekday == DateTime.saturday;
                final isSun = d.weekday == DateTime.sunday;
                return Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday ? sh.accentBg : sh.card2,
                      border: Border(
                        left: BorderSide(color: sh.border, width: 0.5),
                        bottom: BorderSide(color: sh.border),
                      ),
                    ),
                    child: Text(
                      _dowNames[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? sh.accentInk
                            : isSun
                                ? sh.danger
                                : isSat
                                    ? sh.sat
                                    : sh.inkSoft,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // 시간표 행들 (스크롤)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: _rows.map((row) {
                // 세로 스크롤(SingleChildScrollView)은 자식에게 무한 높이를
                // 주므로, _TimetableRow 내부 Row의 crossAxisAlignment.stretch가
                // "BoxConstraints forces an infinite height"로 터진다.
                // 각 교시 행을 고정 높이(rowH)로 감싸 높이를 확정한다.
                return SizedBox(
                  height: rowH,
                  child: _TimetableRow(
                    label: row.label,
                    hour: row.hour,
                    isSchool: row.isSchool,
                    isLunch: row.isLunch,
                    rowH: rowH,
                    timeLblW: timeLblW,
                    days: days,
                    dayKeys: dayKeys,
                    freeData: freeData,
                    templateData: templateData,
                    neisData: neisHourData,
                    neisLunch: _neisLunch,
                    sh: sh,
                    now: now,
                    onCellTap: (di) => _editCell(context, dayKeys[di],
                        row.hour, freeData[di]?[row.hour] ?? ''),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _editCell(
      BuildContext ctx, String dateKey, int hour, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: ctx,
      builder: (dctx) {
        final sh = ctx.sh;
        return AlertDialog(
          backgroundColor: sh.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('$hour:00 일정',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: sh.ink)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '예) 수학, 영어...',
              hintStyle: TextStyle(color: sh.inkFaint),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) =>
                _saveCell(dctx, dateKey, hour, ctrl.text.trim()),
          ),
          actions: [
            if (current.isNotEmpty)
              TextButton(
                onPressed: () => _saveCell(dctx, dateKey, hour, ''),
                style: TextButton.styleFrom(foregroundColor: sh.danger),
                child: const Text('삭제'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () =>
                  _saveCell(dctx, dateKey, hour, ctrl.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _saveCell(
      BuildContext ctx, String dateKey, int hour, String text) {
    Navigator.pop(ctx);
    final eventsNotifier = ref.read(eventsProvider.notifier);
    final current = ref.read(eventsProvider)[dateKey] ?? [];

    final tag = '($hour:00)';
    final existing = current.indexWhere((e) {
      final t = e.t;
      return e.isTimetable && t.contains(tag);
    });

    if (text.isEmpty) {
      if (existing >= 0) {
        eventsNotifier.deleteEvent(dateKey, existing);
      }
    } else {
      _writeRawTimetableCell(dateKey, hour, text);
      final stored = LocalStore.instance.getString(StorageKeys.events);
      if (stored != null) {
        eventsNotifier.replaceAll(eventsFromJson(stored));
      }
    }
    setState(() {});
  }

  void _writeRawTimetableCell(String dateKey, int hour, String text) {
    final raw =
        LocalStore.instance.getString(StorageKeys.events) ?? '{}';
    final map =
        Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final list = List<dynamic>.from(map[dateKey] as List? ?? []);
    final tag = '($hour:00)';
    final idx = list.indexWhere((e) {
      if (e is Map) {
        return (e['tt'] == true) &&
            (e['t'] as String? ?? '').contains(tag);
      }
      return false;
    });
    final newItem = {'t': '$text $tag', 'tt': true};
    if (idx >= 0) {
      list[idx] = newItem;
    } else {
      list.add(newItem);
    }
    map[dateKey] = list;
    LocalStore.instance.setString(StorageKeys.events, jsonEncode(map));
  }
}

class _TimetableRow extends StatelessWidget {
  final String label;
  final int hour;
  final bool isSchool, isLunch;
  final double rowH, timeLblW;
  final List<DateTime> days;
  final List<String> dayKeys;
  final Map<int, Map<int, String>> freeData;
  final Map<int, Map<int, String>> templateData;
  final Map<int, Map<int, String>> neisData;
  final Map<int, String> neisLunch;
  final SpaceHourColors sh;
  final DateTime now;
  final void Function(int di) onCellTap;

  const _TimetableRow({
    required this.label,
    required this.hour,
    required this.isSchool,
    required this.isLunch,
    required this.rowH,
    required this.timeLblW,
    required this.days,
    required this.dayKeys,
    required this.freeData,
    required this.templateData,
    required this.neisData,
    required this.neisLunch,
    required this.sh,
    required this.now,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: timeLblW,
          height: rowH,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSchool
                  ? sh.accentBg.withValues(alpha: 0.4)
                  : isLunch
                      ? sh.accentBg.withValues(alpha: 0.6)
                      : sh.card2,
              border: Border(
                  bottom: BorderSide(color: sh.border, width: 0.5)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSchool ? 11 : 10,
                color: isSchool ? sh.accentInk : sh.inkSoft,
                fontWeight:
                    isSchool ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
        ...List.generate(7, (di) {
          final isToday = du.isSameDay(days[di], now);
          final userText = freeData[di]?[hour] ?? '';
          final tplText = templateData[di]?[hour] ?? '';
          final neisText = neisData[di]?[hour] ?? '';
          // 우선순위: user > NEIS > template
          final String displayText;
          final bool isTemplate;
          final bool isNeis;
          if (userText.isNotEmpty) {
            displayText = userText;
            isTemplate = false;
            isNeis = false;
          } else if (neisText.isNotEmpty) {
            displayText = neisText;
            isTemplate = false;
            isNeis = true;
          } else if (tplText.isNotEmpty) {
            displayText = tplText;
            isTemplate = true;
            isNeis = false;
          } else {
            displayText = '';
            isTemplate = false;
            isNeis = false;
          }

          // 점심 행: NEIS 급식 표시
          if (isLunch && neisLunch.containsKey(di)) {
            final lunch = neisLunch[di]!;
            return Expanded(
              child: GestureDetector(
                onTap: () => onCellTap(di),
                child: Container(
                  height: rowH,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: isToday
                        ? sh.accentBg.withValues(alpha: 0.5)
                        : sh.accentBg.withValues(alpha: 0.2),
                    border: Border(
                      left: BorderSide(color: sh.border, width: 0.5),
                      bottom: BorderSide(color: sh.border, width: 0.5),
                    ),
                  ),
                  child: Text(
                    lunch.split('\n').first, // 첫 번째 메뉴만
                    style: TextStyle(
                        fontSize: 9,
                        color: sh.accentInk,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onCellTap(di),
              child: Container(
                height: rowH,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                    horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: (isTemplate || isNeis)
                      ? sh.accentBg.withValues(
                          alpha: isToday ? 0.5 : 0.3)
                      : isToday
                          ? sh.accentBg.withValues(alpha: 0.3)
                          : isSchool
                              ? sh.card2
                              : sh.card,
                  border: Border(
                    left: BorderSide(color: sh.border, width: 0.5),
                    bottom:
                        BorderSide(color: sh.border, width: 0.5),
                  ),
                ),
                child: displayText.isNotEmpty
                    ? Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: (isSchool || isTemplate || isNeis)
                              ? sh.accentInk
                              : sh.ink,
                          fontWeight:
                              (isSchool || isTemplate || isNeis)
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
              ),
            ),
          );
        }),
      ],
    );
  }
}
