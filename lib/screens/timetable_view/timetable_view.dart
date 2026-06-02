import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../providers/events_provider.dart';
import '../../storage/local_store.dart';
import '../../core/constants/storage_keys.dart';
import '../../supabase/neis_service.dart';

// ─── Row definition ───────────────────────────────────────────────

enum _RType { free, school, lunch, divider }

class _RowDef {
  final _RType type;
  final String label;
  final int hour;   // -1 for divider
  final int period; // 1..N for school rows, -1 otherwise
  const _RowDef({required this.type, this.label = '', this.hour = -1, this.period = -1});
  bool get isDivider => type == _RType.divider;
}

// ─── Merge group ──────────────────────────────────────────────────

class _MergeGroup {
  final int col;       // 0..6 (Mon..Sun)
  final int startRow;  // row index in rows list
  final int span;      // number of rows merged (>= 2)
  final String text;
  final double topOffset; // pixel offset from grid top

  const _MergeGroup({
    required this.col,
    required this.startRow,
    required this.span,
    required this.text,
    required this.topOffset,
  });
}

// ─── Cell design ─────────────────────────────────────────────────

class _CellDesign {
  final Color? bg;
  final Color? textColor;
  final bool bold;
  const _CellDesign({this.bg, this.textColor, this.bold = false});

  static _CellDesign fromJson(Map<String, dynamic> j) => _CellDesign(
    bg: j['bg'] != null ? _hex(j['bg'] as String) : null,
    textColor: j['color'] != null ? _hex(j['color'] as String) : null,
    bold: j['bold'] == true,
  );

  Map<String, dynamic> toJson() => {
    if (bg != null) 'bg': _toHex(bg!),
    if (textColor != null) 'color': _toHex(textColor!),
    if (bold) 'bold': true,
  };

  bool get isEmpty => bg == null && textColor == null && !bold;

  static Color _hex(String h) {
    final s = h.replaceAll('#', '');
    return Color(int.parse(s.length == 6 ? 'FF$s' : s, radix: 16));
  }

  static String _toHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

// ─── Main widget ──────────────────────────────────────────────────

class TimetableView extends ConsumerStatefulWidget {
  const TimetableView({super.key});

  @override
  ConsumerState<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends ConsumerState<TimetableView> {
  static const _dowNames = ['월', '화', '수', '목', '금', '토', '일'];
  static const _rowH    = 42.0;
  static const _timeLblW = 52.0;
  static const _divH   = 3.0;  // wk-divider height
  static const _hdrH   = 48.0; // day header height (shows dow + date)
  static const _tlbH   = 32.0; // toolbar height

  // NEIS cache: di(0=Mon..6=Sun) → period → subject
  final Map<int, Map<int, String>> _neisData = {};
  final Map<int, String> _neisLunch = {};
  bool _neisFetching = false;

  // Design mode
  bool _designMode = false;
  final Map<String, _CellDesign> _designs = {};

  // ── Design color presets ──────────────────────────────────────
  static const _palette = [
    Color(0xFFFFE4E4), // red tint
    Color(0xFFFFF3CD), // yellow tint
    Color(0xFFD4EDDA), // green tint
    Color(0xFFD1ECF1), // blue tint
    Color(0xFFE2D9F3), // purple tint
    Color(0xFFFFF5EE), // cream
    Color(0xFFF0F0F0), // gray tint
    Color(0xFFFFE8D6), // orange tint
  ];

  @override
  void initState() {
    super.initState();
    _loadDesigns();
    _fetchNeisIfNeeded();
  }

  // ── Design persistence ────────────────────────────────────────

  void _loadDesigns() {
    final raw = LocalStore.instance.getString(StorageKeys.cellDesign);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in map.entries) {
        if (e.value is Map<String, dynamic>) {
          _designs[e.key] = _CellDesign.fromJson(e.value as Map<String, dynamic>);
        }
      }
    } catch (_) {}
  }

  void _saveDesigns() {
    LocalStore.instance.setString(
      StorageKeys.cellDesign,
      jsonEncode(_designs.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  String _dKey(int col, int hour) => '${col}_$hour';
  _CellDesign _getDesign(int col, int hour) =>
      _designs[_dKey(col, hour)] ?? const _CellDesign();

  // ── NEIS fetching ─────────────────────────────────────────────

  Future<void> _fetchNeisIfNeeded() async {
    final school = NeisSchool.load();
    if (school == null) return;
    if (_neisFetching) return;
    _neisFetching = true;
    final days = _weekDays();
    for (int di = 0; di < 5; di++) {
      final dk = du.toDateKey(days[di]);
      final dateStr = dk.replaceAll('-', '');
      try {
        final tt = await fetchTimetable(school, dateStr);
        if (tt != null && mounted) setState(() => _neisData[di] = tt);
        final lunch = await fetchLunch(school, dateStr);
        if (lunch != null && mounted) setState(() => _neisLunch[di] = lunch);
      } catch (e) {
        debugPrint('[NEIS] $dateStr error: $e');
      }
    }
    _neisFetching = false;
  }

  List<DateTime> _weekDays() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  // ── Data builders ─────────────────────────────────────────────

  int _maxPeriod() {
    int mp = 7;
    for (final pm in _neisData.values) {
      for (final p in pm.keys) {
        if (p > mp) mp = p;
      }
    }
    return mp;
  }

  List<_RowDef> _buildRows(int maxPeriod) {
    final rows = <_RowDef>[];
    // 0:00 ~ 8:00
    for (int h = 0; h <= 8; h++) {
      rows.add(_RowDef(type: _RType.free, label: '$h:00', hour: h));
    }
    // Divider (wk-divider)
    rows.add(const _RowDef(type: _RType.divider));
    // 1~4교시 (hour = 8+p = 9..12)
    final topPeriods = maxPeriod < 4 ? maxPeriod : 4;
    for (int p = 1; p <= topPeriods; p++) {
      rows.add(_RowDef(type: _RType.school, label: '$p교시', hour: 8 + p, period: p));
    }
    // 점심 (hour = 13)
    rows.add(const _RowDef(type: _RType.lunch, label: '점심', hour: 13));
    // 5~maxPeriod교시 (hour = 9+p = 14..)
    for (int p = 5; p <= maxPeriod; p++) {
      rows.add(_RowDef(type: _RType.school, label: '$p교시', hour: 9 + p, period: p));
    }
    // Divider
    rows.add(const _RowDef(type: _RType.divider));
    // afterSchool ~ 23:00
    final afterSchool = 10 + maxPeriod;
    for (int h = afterSchool; h <= 23; h++) {
      rows.add(_RowDef(type: _RType.free, label: '$h:00', hour: h));
    }
    return rows;
  }

  // Returns [offset0, offset1, ..., totalHeight]
  List<double> _rowOffsets(List<_RowDef> rows) {
    final offsets = <double>[];
    double acc = 0;
    for (final row in rows) {
      offsets.add(acc);
      acc += row.isDivider ? _divH : _rowH;
    }
    offsets.add(acc);
    return offsets;
  }

  Map<int, Map<int, String>> _buildFreeData(
      Map<String, List<EventItem>> events, List<String> dayKeys) {
    final result = <int, Map<int, String>>{};
    for (int di = 0; di < 7; di++) {
      result[di] = {};
      for (final item in (events[dayKeys[di]] ?? [])) {
        if (!item.isTimetable) continue;
        final m = RegExp(r'\((\d{1,2}):(\d{2})\)').firstMatch(item.t);
        if (m != null) {
          final h = int.parse(m.group(1)!);
          result[di]![h] =
              item.t.replaceAll(RegExp(r'\(\d{1,2}:\d{2}\)'), '').trim();
        }
      }
    }
    return result;
  }

  Map<int, Map<int, String>> _buildTemplateData(List<DateTime> days) {
    final result = <int, Map<int, String>>{};
    for (int di = 0; di < 7; di++) { result[di] = {}; }

    final rawTpl = LocalStore.instance.getString(StorageKeys.timetableTemplate);
    if (rawTpl == null) return result;
    Map<String, dynamic> tpl;
    try {
      tpl = jsonDecode(rawTpl) as Map<String, dynamic>;
    } catch (_) {
      return result;
    }

    final blocks = (tpl['blocks'] as List? ?? []).cast<Map<String, dynamic>>();
    final weekdays = (tpl['weekdays'] as List? ?? [0, 1, 2, 3, 4])
        .map((e) => e as int).toSet();
    final startDate = tpl['startDate'] as String?;
    final endDate = tpl['endDate'] as String?;

    Map<String, dynamic> overrides = {};
    final rawOv = LocalStore.instance.getString(StorageKeys.timetableOverrides);
    if (rawOv != null) {
      try {
        overrides = jsonDecode(rawOv) as Map<String, dynamic>;
      } catch (_) {}
    }

    for (int di = 0; di < 7; di++) {
      final date = days[di];
      final dow = (date.weekday - 1) % 7;
      if (!weekdays.contains(dow)) continue;
      final dk = du.toDateKey(date);
      if (startDate != null && dk.compareTo(startDate) < 0) continue;
      if (endDate != null && dk.compareTo(endDate) > 0) continue;
      final ov = overrides[dk] as Map<String, dynamic>? ?? {};
      final hiddenIds = ((ov['hiddenBlockIds'] as List?) ?? [])
          .map((e) => e.toString()).toSet();
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
      final extra = (ov['extra'] as List? ?? []).cast<Map<String, dynamic>>();
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

  Map<int, Map<int, String>> _buildNeisHourData() {
    final result = <int, Map<int, String>>{};
    _neisData.forEach((di, periodMap) {
      result[di] = {};
      periodMap.forEach((period, subject) {
        final h = period <= 4 ? 8 + period : 9 + period;
        result[di]![h] = subject;
      });
    });
    return result;
  }

  // Priority: school rows → NEIS > template > user.
  //           lunch row   → user > NEIS lunch.
  //           free rows   → user > template.
  Map<int, Map<int, String>> _buildDisplayData(
    Map<int, Map<int, String>> neisData,
    Map<int, Map<int, String>> tplData,
    Map<int, Map<int, String>> freeData,
    List<_RowDef> rows,
  ) {
    final result = <int, Map<int, String>>{};
    for (int col = 0; col < 7; col++) {
      result[col] = {};
      for (final row in rows) {
        if (row.isDivider || row.hour < 0) continue;
        final n = neisData[col]?[row.hour] ?? '';
        final t = tplData[col]?[row.hour] ?? '';
        final u = freeData[col]?[row.hour] ?? '';
        if (row.type == _RType.school) {
          result[col]![row.hour] = n.isNotEmpty ? n : t.isNotEmpty ? t : u;
        } else if (row.type == _RType.lunch) {
          // user override shown; NEIS lunch rendered as text if no user override
          final lunch = _neisLunch[col] ?? '';
          result[col]![row.hour] =
              u.isNotEmpty ? u : lunch.isNotEmpty ? lunch.split('\n').first : '';
        } else {
          result[col]![row.hour] = u.isNotEmpty ? u : t;
        }
      }
    }
    return result;
  }

  // ── Merge computation ─────────────────────────────────────────

  List<_MergeGroup> _computeMerges(
    List<_RowDef> rows,
    List<double> offsets,
    Map<int, Map<int, String>> displayData,
  ) {
    final groups = <_MergeGroup>[];
    for (int col = 0; col < 7; col++) {
      int i = 0;
      while (i < rows.length) {
        if (rows[i].isDivider || rows[i].hour < 0) { i++; continue; }
        final text = displayData[col]?[rows[i].hour] ?? '';
        if (text.isEmpty) { i++; continue; }
        int j = i + 1;
        while (j < rows.length &&
               !rows[j].isDivider &&
               rows[j].hour >= 0 &&
               (displayData[col]?[rows[j].hour] ?? '') == text) {
          j++;
        }
        if (j - i >= 2) {
          groups.add(_MergeGroup(
            col: col, startRow: i, span: j - i,
            text: text, topOffset: offsets[i],
          ));
        }
        i = j;
      }
    }
    return groups;
  }

  // All (col, rowIdx) positions that are part of any merge group.
  Set<(int, int)> _buildMergeSet(List<_MergeGroup> groups) {
    final set = <(int, int)>{};
    for (final g in groups) {
      for (int k = g.startRow; k < g.startRow + g.span; k++) {
        set.add((g.col, k));
      }
    }
    return set;
  }

  // ── Cell edit / design handlers ───────────────────────────────

  void _editCell(BuildContext ctx, String dateKey, int hour, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: ctx,
      builder: (dctx) {
        final sh = ctx.sh;
        return AlertDialog(
          backgroundColor: sh.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card)),
          title: Text('$hour:00 메모',
              style: AppType.body.copyWith(fontWeight: FontWeight.w700, color: sh.ink)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '예) 수학, 영어...',
              hintStyle: TextStyle(color: sh.inkFaint),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _saveCell(dctx, dateKey, hour, ctrl.text.trim()),
          ),
          actions: [
            if (current.isNotEmpty)
              TextButton(
                onPressed: () => _saveCell(dctx, dateKey, hour, ''),
                style: TextButton.styleFrom(foregroundColor: sh.danger),
                child: const Text('삭제'),
              ),
            TextButton(
                onPressed: () => Navigator.pop(dctx), child: const Text('취소')),
            FilledButton(
              onPressed: () => _saveCell(dctx, dateKey, hour, ctrl.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _saveCell(BuildContext ctx, String dateKey, int hour, String text) {
    Navigator.pop(ctx);
    final eventsNotifier = ref.read(eventsProvider.notifier);
    final current = ref.read(eventsProvider)[dateKey] ?? [];
    final tag = '($hour:00)';
    final existing = current.indexWhere(
        (e) => e.isTimetable && e.t.contains(tag));
    if (text.isEmpty) {
      if (existing >= 0) eventsNotifier.deleteEvent(dateKey, existing);
    } else {
      _writeRawCell(dateKey, hour, text);
      final stored = LocalStore.instance.getString(StorageKeys.events);
      if (stored != null) eventsNotifier.replaceAll(eventsFromJson(stored));
    }
    setState(() {});
  }

  void _writeRawCell(String dateKey, int hour, String text) {
    final raw = LocalStore.instance.getString(StorageKeys.events) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final list = List<dynamic>.from(map[dateKey] as List? ?? []);
    final tag = '($hour:00)';
    final idx = list.indexWhere(
        (e) => e is Map && (e['tt'] == true) && (e['t'] as String? ?? '').contains(tag));
    final newItem = {'t': '$text $tag', 'tt': true};
    if (idx >= 0) { list[idx] = newItem; } else { list.add(newItem); }
    map[dateKey] = list;
    LocalStore.instance.setString(StorageKeys.events, jsonEncode(map));
  }

  void _showDesignPanel(BuildContext ctx, int col, int hour, SpaceHourColors sh) {
    final key = _dKey(col, hour);
    final current = _designs[key] ?? const _CellDesign();
    showModalBottomSheet(
      context: ctx,
      builder: (_) => _DesignPanel(
        currentDesign: current,
        palette: _palette,
        sh: sh,
        onApply: (design) {
          setState(() {
            if (design.isEmpty) {
              _designs.remove(key);
            } else {
              _designs[key] = design;
            }
          });
          _saveDesigns();
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final events = ref.watch(eventsProvider);
    final days = _weekDays();
    final dayKeys = days.map(du.toDateKey).toList();
    final now = DateTime.now();

    final maxPeriod = _maxPeriod();
    final rows = _buildRows(maxPeriod);
    final offsets = _rowOffsets(rows);
    final totalH = offsets.last;
    final neisHourData = _buildNeisHourData();
    final freeData = _buildFreeData(events, dayKeys);
    final tplData = _buildTemplateData(days);
    final displayData = _buildDisplayData(neisHourData, tplData, freeData, rows);
    final mergeGroups = _computeMerges(rows, offsets, displayData);
    final mergeSet = _buildMergeSet(mergeGroups);

    final school = NeisSchool.load();

    return Column(
      children: [
        // ── Day header (요일 + 날짜) ─────────────────────────────
        SizedBox(
          height: _hdrH,
          child: Row(
            children: [
              SizedBox(
                width: _timeLblW,
                child: Container(
                  color: sh.card2,
                  alignment: Alignment.center,
                  child: Text('시간표', style: AppType.label.copyWith(color: sh.inkFaint)),
                ),
              ),
              ...List.generate(7, (i) {
                final d = days[i];
                final isToday = du.isSameDay(d, now);
                final isSat = d.weekday == DateTime.saturday;
                final isSun = d.weekday == DateTime.sunday;
                final labelColor = isToday ? sh.accentInk
                    : isSun ? sh.danger
                    : isSat ? sh.sat
                    : sh.inkSoft;
                return Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday ? sh.accentBg : sh.card2,
                      border: Border(
                        left: BorderSide(color: _gridLine(sh), width: 1),
                        bottom: BorderSide(color: _gridLine(sh), width: 1.5),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_dowNames[i], style: AppType.caption.copyWith(
                          fontWeight: FontWeight.w600, color: labelColor)),
                        Text('${d.month}/${d.day}', style: AppType.label.copyWith(
                          color: isToday ? sh.accentInk : sh.inkFaint)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // ── Toolbar (🎨 design mode + NEIS info) ─────────────────
        SizedBox(
          height: _tlbH,
          child: Container(
            color: sh.bg,
            padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 4),
            child: Row(
              children: [
                _DesignModeBtn(
                  active: _designMode,
                  onTap: () => setState(() => _designMode = !_designMode),
                ),
                const Spacer(),
                if (school != null) ...[
                  Icon(Icons.school_outlined, size: 13, color: sh.inkFaint),
                  const SizedBox(width: Gap.xs),
                  Text('${school.name} ${school.grade}학년',
                      style: AppType.label.copyWith(color: sh.inkFaint)),
                ],
              ],
            ),
          ),
        ),
        Divider(height: 1, color: sh.border),

        // ── Scrollable grid ──────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: LayoutBuilder(builder: (ctx, constraints) {
              final colW = (constraints.maxWidth - _timeLblW) / 7;
              return SizedBox(
                height: totalH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Main grid rows ────────────────────────────
                    Positioned.fill(
                      child: Column(
                        children: List.generate(rows.length, (ri) {
                          final row = rows[ri];

                          // Divider row (wk-divider)
                          if (row.isDivider) {
                            return Container(
                              height: _divH,
                              color: sh.accent.withValues(alpha: 0.3),
                            );
                          }

                          return SizedBox(
                            height: _rowH,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Time label column
                                SizedBox(
                                  width: _timeLblW,
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _timeLblBg(row, sh),
                                      border: Border(
                                        right: BorderSide(color: _gridLine(sh), width: 1),
                                        bottom: BorderSide(color: _gridLine(sh), width: 1),
                                      ),
                                    ),
                                    child: Text(row.label, style: TextStyle(
                                      fontSize: row.type == _RType.school ? 11 : 10,
                                      color: row.type == _RType.school
                                          ? sh.accentInk : sh.inkSoft,
                                      fontWeight: row.type == _RType.school
                                          ? FontWeight.w600 : FontWeight.w400,
                                    )),
                                  ),
                                ),
                                // 7 day cells
                                ...List.generate(7, (col) {
                                  final isMerged = mergeSet.contains((col, ri));
                                  final isToday = du.isSameDay(days[col], now);
                                  final text = displayData[col]?[row.hour] ?? '';
                                  final design = _getDesign(col, row.hour);

                                  // Whether this cell is the last row of a merge group
                                  // (has bottom border)
                                  final isLastInMerge = isMerged &&
                                      mergeGroups.any((g) =>
                                          g.col == col &&
                                          ri == g.startRow + g.span - 1);
                                  final hasBottomBorder =
                                      !isMerged || isLastInMerge;

                                  final isSchoolFilled = row.type == _RType.school
                                      && text.isNotEmpty;

                                  Color bgColor;
                                  if (design.bg != null) {
                                    bgColor = design.bg!;
                                  } else if (row.type == _RType.lunch) {
                                    bgColor = isToday
                                        ? sh.accentBg.withValues(alpha: 0.5)
                                        : (sh.dark
                                            ? sh.card2
                                            : const Color(0xFFFFF5EE));
                                  } else if (isSchoolFilled) {
                                    bgColor = sh.accentBg.withValues(
                                        alpha: isToday ? 0.5 : 0.3);
                                  } else if (row.type == _RType.school) {
                                    bgColor = isToday
                                        ? sh.accentBg.withValues(alpha: 0.2)
                                        : sh.card2;
                                  } else {
                                    // free row
                                    bgColor = isToday
                                        ? sh.accentBg.withValues(alpha: 0.15)
                                        : sh.card;
                                  }

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_designMode) {
                                          _showDesignPanel(context, col, row.hour, sh);
                                        } else {
                                          _editCell(context, dayKeys[col], row.hour,
                                              freeData[col]?[row.hour] ?? '');
                                        }
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          border: Border(
                                            left: BorderSide(color: _gridLine(sh), width: 1),
                                            right: col == 6
                                                ? BorderSide(color: _gridLine(sh), width: 1)
                                                : BorderSide.none,
                                            bottom: hasBottomBorder
                                                ? BorderSide(color: _gridLine(sh), width: 1)
                                                : BorderSide.none,
                                          ),
                                        ),
                                        // Merged cells: hide individual text
                                        // (merge label overlay will show it)
                                        child: isMerged ? null : (text.isNotEmpty
                                            ? Text(text, style: TextStyle(
                                                fontSize: 10.5,
                                                color: design.textColor ??
                                                    (isSchoolFilled || row.type == _RType.lunch
                                                        ? sh.accentInk : sh.ink),
                                                fontWeight: design.bold || isSchoolFilled
                                                    ? FontWeight.w600 : FontWeight.w400,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ) : null),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    // ── Merge label overlays ──────────────────────
                    ...mergeGroups.map((mg) {
                      final row = rows[mg.startRow];
                      final design = _getDesign(mg.col, row.hour);
                      final isSchoolFilled = row.type == _RType.school;
                      final textColor = design.textColor ??
                          (isSchoolFilled || row.type == _RType.lunch
                              ? sh.accentInk : sh.ink);
                      return Positioned(
                        top: mg.topOffset,
                        left: _timeLblW + mg.col * colW,
                        width: colW,
                        height: mg.span * _rowH,
                        child: IgnorePointer(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(mg.text, style: TextStyle(
                              fontSize: 10.5,
                              color: textColor,
                              fontWeight: design.bold || isSchoolFilled
                                  ? FontWeight.w600 : FontWeight.w400,
                            ),
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Color _timeLblBg(_RowDef row, SpaceHourColors sh) {
    if (row.type == _RType.school) return sh.accentBg.withValues(alpha: 0.4);
    if (row.type == _RType.lunch) return sh.accentBg.withValues(alpha: 0.6);
    return sh.card2;
  }

  // 격자선: ink 색 12% — hairline보다 진하고 배경과 대비 보장.
  Color _gridLine(SpaceHourColors sh) =>
      sh.ink.withValues(alpha: sh.dark ? 0.20 : 0.12);
}

// ─── Design mode button ───────────────────────────────────────────

class _DesignModeBtn extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _DesignModeBtn({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 4),
        decoration: BoxDecoration(
          color: active ? sh.accent : sh.card2,
          borderRadius: BorderRadius.circular(Radii.small),
          border: Border.all(color: active ? sh.accent : sh.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎨', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              active ? '디자인 모드 켜짐' : '셀 디자인',
              style: AppType.label.copyWith(
                  color: active ? Colors.white : sh.inkSoft,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Design panel bottom sheet ────────────────────────────────────

class _DesignPanel extends StatefulWidget {
  final _CellDesign currentDesign;
  final List<Color> palette;
  final SpaceHourColors sh;
  final void Function(_CellDesign) onApply;

  const _DesignPanel({
    required this.currentDesign,
    required this.palette,
    required this.sh,
    required this.onApply,
  });

  @override
  State<_DesignPanel> createState() => _DesignPanelState();
}

class _DesignPanelState extends State<_DesignPanel> {
  late Color? _bg;
  late bool _bold;

  @override
  void initState() {
    super.initState();
    _bg = widget.currentDesign.bg;
    _bold = widget.currentDesign.bold;
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    return Container(
      color: sh.card,
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('셀 디자인', style: AppType.section.copyWith(
                fontWeight: FontWeight.w700, color: sh.ink)),
            const Spacer(),
            TextButton(
              onPressed: () {
                widget.onApply(const _CellDesign());
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: sh.danger),
              child: const Text('초기화'),
            ),
          ]),
          const SizedBox(height: Gap.md),
          Text('배경색', style: AppType.caption.copyWith(color: sh.inkSoft)),
          const SizedBox(height: Gap.xs),
          Wrap(
            spacing: Gap.sm,
            children: [
              // No color (transparent) option
              GestureDetector(
                onTap: () => setState(() => _bg = null),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _bg == null ? sh.ink : sh.border, width: 2),
                  ),
                  child: const Center(child: Text('✕',
                      style: TextStyle(fontSize: 12, color: Color(0xFF888888)))),
                ),
              ),
              ...widget.palette.map((c) => GestureDetector(
                onTap: () => setState(() => _bg = c),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _bg == c ? sh.ink : Colors.transparent, width: 2),
                    boxShadow: _bg == c
                        ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6)]
                        : null,
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(children: [
            Text('굵게', style: AppType.caption.copyWith(color: sh.inkSoft)),
            const SizedBox(width: Gap.sm),
            Switch(
              value: _bold,
              onChanged: (v) => setState(() => _bold = v),
            ),
          ]),
          const SizedBox(height: Gap.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_CellDesign(bg: _bg, bold: _bold));
                Navigator.pop(context);
              },
              child: const Text('적용'),
            ),
          ),
        ],
      ),
    );
  }
}
