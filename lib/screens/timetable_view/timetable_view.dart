import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../storage/local_store.dart';
import '../../core/constants/storage_keys.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/cell_design_provider.dart';
import '../../providers/neis_cache_provider.dart';
import '../../providers/academic_schedule_provider.dart';
import '../../modals/neis_setup_modal.dart';
import 'dart:convert';

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
  final int col;
  final int startRow;
  final int span;
  final String text;
  final double topOffset;

  const _MergeGroup({
    required this.col,
    required this.startRow,
    required this.span,
    required this.text,
    required this.topOffset,
  });
}

// ─── Main widget ──────────────────────────────────────────────────

class TimetableView extends ConsumerStatefulWidget {
  const TimetableView({super.key});

  @override
  ConsumerState<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends ConsumerState<TimetableView> {
  static const _dowNames = ['월', '화', '수', '목', '금', '토', '일'];
  static const _rowH    = 48.0;
  static const _timeLblW = 52.0;
  static const _divH   = 3.0;

  // 디자인 모드(셀 꾸미기) — 화면 로컬 UI 상태.
  bool _designMode = false;

  static const _palette = [
    Color(0xFFFFE4E4), Color(0xFFFFF3CD), Color(0xFFD4EDDA), Color(0xFFD1ECF1),
    Color(0xFFE2D9F3), Color(0xFFFFF5EE), Color(0xFFF0F0F0), Color(0xFFFFE8D6),
  ];

  // ── Data builders ─────────────────────────────────────────────

  List<DateTime> _weekDays() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  int _maxPeriod(Map<int, Map<int, String>> neis) {
    int mp = 7;
    for (final pm in neis.values) {
      for (final p in pm.keys) {
        if (p > mp) mp = p;
      }
    }
    return mp;
  }

  List<_RowDef> _buildRows(int maxPeriod) {
    final rows = <_RowDef>[];
    for (int h = 0; h <= 8; h++) {
      rows.add(_RowDef(type: _RType.free, label: '$h:00', hour: h));
    }
    rows.add(const _RowDef(type: _RType.divider));
    final topPeriods = maxPeriod < 4 ? maxPeriod : 4;
    for (int p = 1; p <= topPeriods; p++) {
      rows.add(_RowDef(type: _RType.school, label: '$p교시', hour: 8 + p, period: p));
    }
    rows.add(const _RowDef(type: _RType.lunch, label: '점심', hour: 13));
    for (int p = 5; p <= maxPeriod; p++) {
      rows.add(_RowDef(type: _RType.school, label: '$p교시', hour: 9 + p, period: p));
    }
    rows.add(const _RowDef(type: _RType.divider));
    final afterSchool = 10 + maxPeriod;
    for (int h = afterSchool; h <= 23; h++) {
      rows.add(_RowDef(type: _RType.free, label: '$h:00', hour: h));
    }
    return rows;
  }

  // 행별 높이: divider는 _divH, 그 외엔 내용 최대 길이에 따라 가변.
  List<double> _rowHeights(
      List<_RowDef> rows, Map<int, Map<int, String>> displayData) {
    return [
      for (final row in rows)
        if (row.isDivider)
          _divH
        else
          _cellHeightFor(row, displayData),
    ];
  }

  double _cellHeightFor(_RowDef row, Map<int, Map<int, String>> displayData) {
    if (row.hour < 0) return _rowH;
    int maxLen = 0;
    for (int c = 0; c < 7; c++) {
      final t = displayData[c]?[row.hour] ?? '';
      if (t.length > maxLen) maxLen = t.length;
    }
    if (maxLen <= 5) return _rowH;        // 한 줄
    if (maxLen <= 11) return _rowH + 16;  // 두 줄
    return _rowH + 34;                    // 세 줄 이상
  }

  List<double> _rowOffsets(List<double> heights) {
    final offsets = <double>[];
    double acc = 0;
    for (final h in heights) {
      offsets.add(acc);
      acc += h;
    }
    offsets.add(acc);
    return offsets;
  }

  int _maxLinesForHeight(double h) => ((h - 10) / 14).floor().clamp(1, 4);

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

  Map<int, Map<int, String>> _buildNeisHourData(Map<int, Map<int, String>> neis) {
    final result = <int, Map<int, String>>{};
    neis.forEach((di, periodMap) {
      result[di] = {};
      periodMap.forEach((period, subject) {
        final h = period <= 4 ? 8 + period : 9 + period;
        result[di]![h] = subject;
      });
    });
    return result;
  }

  Map<int, Map<int, String>> _buildDisplayData(
    Map<int, Map<int, String>> neisData,
    Map<int, Map<int, String>> tplData,
    Map<int, Map<int, String>> freeData,
    Map<int, String> neisLunch,
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
          final lunch = neisLunch[col] ?? '';
          result[col]![row.hour] =
              u.isNotEmpty ? u : lunch.isNotEmpty ? lunch.split('\n').first : '';
        } else {
          result[col]![row.hour] = u.isNotEmpty ? u : t;
        }
      }
    }
    return result;
  }

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

  void _editCell(BuildContext ctx, int col, int hour, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: ctx,
      builder: (dctx) {
        final sh = ctx.sh;
        return AlertDialog(
          backgroundColor: sh.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22)),
          title: Text('${_dowNames[col]}요일 $hour:00 · 매주 반복',
              style: AppType.section.copyWith(
                  fontWeight: FontWeight.w800, color: sh.ink)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '예) 수학, 영어...',
              hintStyle: TextStyle(color: sh.inkFaint),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _saveCell(dctx, col, hour, ctrl.text.trim()),
          ),
          actions: [
            if (current.isNotEmpty)
              TextButton(
                onPressed: () => _saveCell(dctx, col, hour, ''),
                style: TextButton.styleFrom(foregroundColor: sh.danger),
                child: const Text('삭제'),
              ),
            TextButton(
                onPressed: () => Navigator.pop(dctx), child: const Text('취소')),
            FilledButton(
              onPressed: () => _saveCell(dctx, col, hour, ctrl.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _saveCell(BuildContext ctx, int col, int hour, String text) {
    Navigator.pop(ctx);
    ref.read(recurringProvider.notifier).setCell(col, hour, text);
  }

  void _showDesignPanel(BuildContext ctx, int col, int hour, SpaceHourColors sh) {
    final current = ref.read(cellDesignProvider.notifier).forCell(col, hour);
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _DesignPanel(
        currentDesign: current,
        palette: _palette,
        sh: sh,
        onApply: (design) =>
            ref.read(cellDesignProvider.notifier).setDesign(col, hour, design),
      ),
    );
  }

  // 햄버거 메뉴 — 셀 디자인 토글 + 학교 연결 + 새로고침.
  void _openMenu(BuildContext ctx, SpaceHourColors sh) {
    showModalBottomSheet(
      context: ctx,
      builder: (mctx) => Container(
        color: sh.card,
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.palette_outlined,
                  color: _designMode ? sh.accent : sh.inkSoft),
              title: Text('셀 디자인',
                  style: AppType.body.copyWith(color: sh.ink)),
              subtitle: Text(_designMode ? '켜짐 — 셀을 눌러 꾸미기' : '꺼짐',
                  style: AppType.caption.copyWith(color: sh.inkSoft)),
              trailing: Switch.adaptive(
                value: _designMode,
                activeThumbColor: sh.accent,
                onChanged: (v) {
                  setState(() => _designMode = v);
                  Navigator.pop(mctx);
                },
              ),
              onTap: () {
                setState(() => _designMode = !_designMode);
                Navigator.pop(mctx);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.school_outlined, color: sh.inkSoft),
              title: Text('학교 연결 (NEIS)',
                  style: AppType.body.copyWith(color: sh.ink)),
              onTap: () {
                Navigator.pop(mctx);
                showNeisSetupModal(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.refresh_rounded, color: sh.inkSoft),
              title: Text('시간표·학사일정 새로고침',
                  style: AppType.body.copyWith(color: sh.ink)),
              onTap: () {
                Navigator.pop(mctx);
                ref.read(neisCacheProvider.notifier).refresh();
                ref.read(academicScheduleProvider.notifier).refresh();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final days = _weekDays();
    final now = DateTime.now();

    final neis = ref.watch(neisCacheProvider);
    final designs = ref.watch(cellDesignProvider);
    CellDesign designOf(int col, int hour) =>
        designs[cellDesignKey(col, hour)] ?? const CellDesign();

    final maxPeriod = _maxPeriod(neis.timetable);
    final rows = _buildRows(maxPeriod);
    final neisHourData = _buildNeisHourData(neis.timetable);
    final weekly = ref.watch(recurringProvider);
    final freeData = {
      for (int c = 0; c < 7; c++) c: Map<int, String>.from(weekly[c] ?? const {}),
    };
    final tplData = _buildTemplateData(days);
    final displayData =
        _buildDisplayData(neisHourData, tplData, freeData, neis.lunch, rows);
    // 내용 길이에 따라 행 높이를 가변으로 — 긴 내용은 칸을 더 크게.
    final rowHeights = _rowHeights(rows, displayData);
    final offsets = _rowOffsets(rowHeights);
    final totalH = offsets.last;
    final mergeGroups = _computeMerges(rows, offsets, displayData);
    final mergeSet = _buildMergeSet(mergeGroups);

    return Column(
          children: [
            // ── 제목 + 햄버거 메뉴 ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('스케줄표',
                            style: AppType.title.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: sh.ink)),
                        const SizedBox(height: 2),
                        Text(
                            _designMode
                                ? '디자인 모드 — 셀을 눌러 꾸며요'
                                : '매주 반복되는 내 일정을 배치해요',
                            style: AppType.label.copyWith(
                                color: _designMode ? sh.accent : sh.inkSoft)),
                      ],
                    ),
                  ),
                  _HamburgerBtn(onTap: () => _openMenu(context, sh)),
                ],
              ),
            ),
            // ── 요일 헤더 (색 강화) ─────────────────────────────────
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  SizedBox(
                    width: _timeLblW,
                    child: Container(
                      color: sh.card2,
                      alignment: Alignment.center,
                      child: Icon(Icons.schedule_rounded,
                          size: 15, color: sh.inkSoft),
                    ),
                  ),
                  ...List.generate(7, (i) {
                    final isTodayDow = now.weekday - 1 == i;
                    final isSat = i == 5;
                    final isSun = i == 6;
                    final labelColor = isTodayDow
                        ? sh.accentInk
                        : isSun
                            ? sh.sun
                            : isSat
                                ? sh.sat
                                : sh.ink; // 평일도 진하게
                    return Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isTodayDow
                              ? sh.accentBg
                              : sh.card2.withValues(alpha: sh.dark ? 1 : 0.7),
                          border: Border(
                            left: BorderSide(color: _gridLine(sh), width: 1),
                            bottom: BorderSide(color: _gridLine(sh), width: 1.5),
                          ),
                        ),
                        child: Text(_dowNames[i],
                            style: AppType.body.copyWith(
                                fontWeight: FontWeight.w800, color: labelColor)),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Zoomable + scrollable grid (핀치 확대/축소) ─────────
            Expanded(
              child: LayoutBuilder(builder: (ctx, constraints) {
                  final colW = (constraints.maxWidth - _timeLblW) / 7;
                  return InteractiveViewer(
                    constrained: false,
                    minScale: 1.0,
                    maxScale: 3.0,
                    boundaryMargin: const EdgeInsets.only(bottom: 130),
                    child: SizedBox(
                    width: constraints.maxWidth,
                    height: totalH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Column(
                            children: List.generate(rows.length, (ri) {
                              final row = rows[ri];
                              if (row.isDivider) {
                                return Container(
                                  height: _divH,
                                  color: sh.accent.withValues(alpha: 0.3),
                                );
                              }
                              return SizedBox(
                                height: rowHeights[ri],
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
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
                                    ...List.generate(7, (col) {
                                      final isMerged = mergeSet.contains((col, ri));
                                      final isToday = du.isSameDay(days[col], now);
                                      final text = displayData[col]?[row.hour] ?? '';
                                      final design = designOf(col, row.hour);

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
                                              _editCell(context, col, row.hour,
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
                                            // 칸 높이에 맞춰 줄 수를 늘려 내용이 잘 보이도록.
                                            child: isMerged ? null : (text.isNotEmpty
                                                ? Text(text, style: TextStyle(
                                                    fontSize: 11.5,
                                                    height: 1.15,
                                                    color: design.textColor ??
                                                        (isSchoolFilled || row.type == _RType.lunch
                                                            ? sh.accentInk : sh.ink),
                                                    fontWeight: design.bold || isSchoolFilled
                                                        ? FontWeight.w600 : FontWeight.w400,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: _maxLinesForHeight(rowHeights[ri]),
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

                        ...mergeGroups.map((mg) {
                          final row = rows[mg.startRow];
                          final design = designOf(mg.col, row.hour);
                          final isSchoolFilled = row.type == _RType.school;
                          final textColor = design.textColor ??
                              (isSchoolFilled || row.type == _RType.lunch
                                  ? sh.accentInk : sh.ink);
                          return Positioned(
                            top: mg.topOffset,
                            left: _timeLblW + mg.col * colW,
                            width: colW,
                            height: offsets[mg.startRow + mg.span] -
                                offsets[mg.startRow],
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
                  ),
                );
              }),
            ),
          ],
    );
  }

  Color _timeLblBg(_RowDef row, SpaceHourColors sh) {
    if (row.type == _RType.school) return sh.accentBg.withValues(alpha: 0.4);
    if (row.type == _RType.lunch) return sh.accentBg.withValues(alpha: 0.6);
    return sh.card2;
  }

  Color _gridLine(SpaceHourColors sh) =>
      sh.ink.withValues(alpha: sh.dark ? 0.20 : 0.12);
}

// ─── 햄버거 버튼 ──────────────────────────────────────────────────
class _HamburgerBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _HamburgerBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: sh.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sh.ink.withValues(alpha: 0.06)),
        ),
        child: Icon(Icons.menu_rounded, size: 20, color: sh.inkSoft),
      ),
    );
  }
}

// ─── Design panel bottom sheet ────────────────────────────────────

class _DesignPanel extends StatefulWidget {
  final CellDesign currentDesign;
  final List<Color> palette;
  final SpaceHourColors sh;
  final void Function(CellDesign) onApply;

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
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: sh.ink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(children: [
            Text('셀 디자인', style: AppType.section.copyWith(
                fontWeight: FontWeight.w800, color: sh.ink)),
            const Spacer(),
            TextButton(
              onPressed: () {
                widget.onApply(const CellDesign());
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
                widget.onApply(CellDesign(bg: _bg, bold: _bold));
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: sh.accent,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('적용',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
