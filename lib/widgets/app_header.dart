import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/view_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/coach_mark.dart';
import '../modals/theme_manager_modal.dart';
import '../modals/profile_modal.dart';
import '../utils/screenshot_util.dart';

enum _MoreAction { category, settings, profile }

// ─── 통합 상단 chrome ─────────────────────────────────────────────
// Brand row / 날짜 앵커 / 모토 / 뷰 세그먼트 탭을 하나의 위젯으로 묶음.
class AppHeader extends ConsumerStatefulWidget {
  const AppHeader({super.key});

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader> {
  bool _pickerOpen = false;
  late TextEditingController _mottoCtrl;
  bool _mottoEditing = false;

  static const _monthNames = [
    '1월','2월','3월','4월','5월','6월',
    '7월','8월','9월','10월','11월','12월',
  ];

  @override
  void initState() {
    super.initState();
    _mottoCtrl = TextEditingController(
        text: ref.read(settingsProvider).motto);
  }

  @override
  void dispose() {
    _mottoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final view = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final isHome = view.mode == ViewMode.home;
    final isTimetable = view.mode == ViewMode.timetable;
    final isYear = view.mode == ViewMode.year;

    if (!_mottoEditing && _mottoCtrl.text != settings.motto) {
      _mottoCtrl.text = settings.motto;
    }

    return Container(
      color: sh.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 브랜드 행 ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xs, Gap.xl, 0),
            child: Row(
              children: [
                _SpaceHourLogo(color: sh.inkFaint),
                const SizedBox(width: Gap.xs),
                Text('HourSpace',
                    style: AppType.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sh.inkSoft,
                        letterSpacing: -0.2)),
                const Spacer(),
                _IconBtn(
                  icon: Icons.ios_share_outlined,
                  sh: sh,
                  onTap: captureAndShare,
                ),
                SizedBox(key: coachKeyBtnCategory, width: 0, height: 0),
                _IconBtn(
                  key: coachKeyBtnSettings,
                  icon: Icons.more_horiz,
                  sh: sh,
                  onTap: () => _openMore(context, ref, sh),
                ),
              ],
            ),
          ),

          // ── 날짜 앵커 + 탐색 (홈 모드에서 숨김) ─────────────
          if (isHome) const SizedBox.shrink()
          else
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.xl, 0),
            child: isTimetable
                ? Text('시간표',
                    style: AppType.title.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: sh.ink))
                : Row(
                    children: [
                      // 날짜 라벨 탭 → 날짜 피커
                      GestureDetector(
                        onTap: () =>
                            setState(() => _pickerOpen = !_pickerOpen),
                        child: Text(
                          isYear
                              ? '${view.viewYear}년'
                              : '${view.viewYear}년 ${_monthNames[view.viewMonth - 1]}',
                          style: AppType.title.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: sh.ink),
                        ),
                      ),
                      const Spacer(),
                      _NavBtn(
                        label: '＜',
                        onTap: isYear
                            ? () => notifier.prevYear()
                            : () => notifier.prevMonth(),
                        sh: sh,
                      ),
                      _NavBtn(
                        label: '＞',
                        onTap: isYear
                            ? () => notifier.nextYear()
                            : () => notifier.nextMonth(),
                        sh: sh,
                      ),
                      const SizedBox(width: Gap.xs),
                      _TodayBtn(
                        onTap: () {
                          notifier.goToToday();
                          if (isYear) notifier.setMode(ViewMode.events);
                        },
                        sh: sh,
                      ),
                    ],
                  ),
          ),

          // 날짜 피커 팝업
          if (_pickerOpen && !isTimetable)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xs, Gap.xl, 0),
              child: _DatePickerPopup(
                year: view.viewYear,
                month: view.viewMonth,
                sh: sh,
                onSelect: (y, m) {
                  notifier.setYearMonth(y, m);
                  if (isYear) notifier.setMode(ViewMode.events);
                  setState(() => _pickerOpen = false);
                },
              ),
            ),

          // ── 모토 (홈·시간표에서 숨김) ────────────────────────
          if (!isHome) Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, 2, Gap.xl, Gap.xs),
            child: Row(
              children: [
                Text('"',
                    style: AppType.label.copyWith(
                        color: sh.inkFaint.withValues(alpha: 0.6), height: 1)),
                Expanded(
                  child: TextField(
                    controller: _mottoCtrl,
                    style: AppType.label.copyWith(
                        color: sh.inkFaint, fontStyle: FontStyle.italic),
                    decoration: InputDecoration(
                      hintText: '이달의 모토',
                      hintStyle: AppType.label.copyWith(
                          color: sh.inkFaint.withValues(alpha: 0.45),
                          fontStyle: FontStyle.italic),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: Gap.xs),
                    ),
                    maxLines: 1,
                    maxLength: 120,
                    buildCounter: (_, {required currentLength,
                          required isFocused, required maxLength}) => null,
                    onTap: () => setState(() => _mottoEditing = true),
                    onSubmitted: (v) {
                      ref.read(settingsProvider.notifier).setMotto(v);
                      setState(() => _mottoEditing = false);
                    },
                    onEditingComplete: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setMotto(_mottoCtrl.text);
                      setState(() => _mottoEditing = false);
                    },
                  ),
                ),
                Text('"',
                    style: AppType.label.copyWith(
                        color: sh.inkFaint.withValues(alpha: 0.6), height: 1)),
              ],
            ),
          ),

          // ── 뷰 세그먼트 탭 (홈에서 숨김) ────────────────────
          if (!isHome) Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.sm),
            child: _ViewSegment(view: view, notifier: notifier, sh: sh),
          ),
        ],
      ),
    );
  }

  void _openMore(BuildContext context, WidgetRef ref, SpaceHourColors sh) {
    showModalBottomSheet<_MoreAction>(
      context: context,
      builder: (_) => const _MoreSheet(),
    ).then((action) {
      if (action == null || !context.mounted) return;
      switch (action) {
        case _MoreAction.category:
          showThemeManagerModal(context);
        case _MoreAction.settings:
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const FractionallySizedBox(
              heightFactor: 0.85,
              child: SidebarDrawer(),
            ),
          );
        case _MoreAction.profile:
          showProfileModal(context);
      }
    });
  }
}

// ─── 알약형 뷰 세그먼트 탭 ────────────────────────────────────────
class _ViewSegment extends StatelessWidget {
  final ViewState view;
  final ViewNotifier notifier;
  final SpaceHourColors sh;

  const _ViewSegment({
    required this.view,
    required this.notifier,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive(ViewMode m) => view.mode == m;

    void goToDay() {
      final n = DateTime.now();
      final key =
          '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
      notifier.setDayView(key);
    }

    final tabs = [
      (label: '연간', mode: ViewMode.year,
          onTap: () => notifier.setMode(ViewMode.year)),
      (label: '월간', mode: ViewMode.events,
          onTap: () => notifier.setMode(ViewMode.events)),
      (label: '주간', mode: ViewMode.planner,
          onTap: () => notifier.setMode(ViewMode.planner)),
      (label: '일별', mode: ViewMode.day, onTap: goToDay),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sh.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: tabs.map((t) {
          final active = isActive(t.mode);
          return Expanded(
            child: GestureDetector(
            onTap: t.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: Gap.md, vertical: Gap.xs + 2),
              decoration: BoxDecoration(
                color: active ? sh.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: sh.accent.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                t.label,
                textAlign: TextAlign.center,
                style: AppType.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : sh.inkSoft,
                    height: 1),
              ),
            ),
          ));
        }).toList(),
      ),
    );
  }
}

// ─── 아이콘 버튼 (44×44 터치 영역) ──────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _IconBtn({super.key, required this.icon, required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kMinTouch,
      height: kMinTouch,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kMinTouch / 2),
        child: Center(child: Icon(icon, size: 20, color: sh.inkSoft)),
      ),
    );
  }
}

// ─── 탐색 화살표 버튼 ────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _NavBtn({required this.label, required this.onTap, required this.sh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(label,
            style: AppType.body.copyWith(
                fontWeight: FontWeight.w500, color: sh.inkSoft)),
      ),
    );
  }
}

// ─── 오늘 버튼 ───────────────────────────────────────────────────
class _TodayBtn extends StatelessWidget {
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _TodayBtn({required this.onTap, required this.sh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.small),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Gap.sm + 2, vertical: Gap.xs),
        decoration: BoxDecoration(
          border: Border.all(color: sh.border),
          borderRadius: BorderRadius.circular(Radii.small),
        ),
        child: Text('오늘',
            style: AppType.caption.copyWith(
                fontWeight: FontWeight.w500, color: sh.inkSoft)),
      ),
    );
  }
}

// ─── 날짜 피커 팝업 ──────────────────────────────────────────────
class _DatePickerPopup extends StatefulWidget {
  final int year;
  final int month;
  final SpaceHourColors sh;
  final void Function(int, int) onSelect;
  const _DatePickerPopup({
    required this.year,
    required this.month,
    required this.sh,
    required this.onSelect,
  });

  @override
  State<_DatePickerPopup> createState() => _DatePickerPopupState();
}

class _DatePickerPopupState extends State<_DatePickerPopup> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    return Container(
      margin: const EdgeInsets.only(top: Gap.xs),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: sh.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PickerCol(
            items: List.generate(11, (i) => '${_year - 5 + i}년'),
            selected: 5,
            onChanged: (i) => setState(() => _year = _year - 5 + i),
            sh: sh,
          ),
          const SizedBox(width: Gap.sm),
          _PickerCol(
            items: List.generate(12, (i) => '${i + 1}월'),
            selected: _month - 1,
            onChanged: (i) => widget.onSelect(_year, i + 1),
            sh: sh,
          ),
        ],
      ),
    );
  }
}

class _PickerCol extends StatelessWidget {
  final List<String> items;
  final int selected;
  final void Function(int) onChanged;
  final SpaceHourColors sh;
  const _PickerCol({
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 160,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final sel = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: sel
                  ? BoxDecoration(
                      color: sh.accentBg,
                      borderRadius: BorderRadius.circular(Radii.small))
                  : null,
              child: Center(
                child: Text(items[i],
                    style: AppType.body.copyWith(
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? sh.accentInk : sh.inkSoft)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── 더보기 바텀시트 ─────────────────────────────────────────────
class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Container(
      color: sh.card,
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.md, Gap.xl, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: Gap.xl,
            leading: Icon(Icons.label_outline_rounded,
                size: 20, color: sh.inkSoft),
            title: Text('카테고리 관리',
                style: AppType.body.copyWith(color: sh.ink)),
            trailing: Icon(Icons.chevron_right_rounded,
                size: 18, color: sh.inkFaint),
            onTap: () => Navigator.pop(context, _MoreAction.category),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: Gap.xl,
            leading: Icon(Icons.settings_outlined,
                size: 20, color: sh.inkSoft),
            title: Text('설정', style: AppType.body.copyWith(color: sh.ink)),
            trailing: Icon(Icons.chevron_right_rounded,
                size: 18, color: sh.inkFaint),
            onTap: () => Navigator.pop(context, _MoreAction.settings),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: Gap.xl,
            leading: Icon(Icons.person_outline_rounded,
                size: 20, color: sh.inkSoft),
            title: Text('프로필', style: AppType.body.copyWith(color: sh.ink)),
            trailing: Icon(Icons.chevron_right_rounded,
                size: 18, color: sh.inkFaint),
            onTap: () => Navigator.pop(context, _MoreAction.profile),
          ),
        ],
      ),
    );
  }
}

// ─── HourSpace 로고 ──────────────────────────────────────────────
class _SpaceHourLogo extends StatelessWidget {
  final Color color;
  const _SpaceHourLogo({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _LogoPainter(color: color),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final s = size.width;
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1.5, s - 2, s - 2.5), const Radius.circular(2.5));
    canvas.drawRRect(rrect, p);
    canvas.drawLine(Offset(1, s * 0.36), Offset(s - 1, s * 0.36), p);
    canvas.drawLine(Offset(s * 0.29, 0), Offset(s * 0.29, s * 0.22), p);
    canvas.drawLine(Offset(s * 0.71, 0), Offset(s * 0.71, s * 0.22), p);
    final dp = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final x in [s * 0.3, s * 0.5, s * 0.7]) {
      canvas.drawCircle(Offset(x, s * 0.59), 1.0, dp);
    }
    canvas.drawCircle(Offset(s * 0.3, s * 0.78), 1.0, dp);
    canvas.drawCircle(Offset(s * 0.5, s * 0.78), 1.0, dp);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
