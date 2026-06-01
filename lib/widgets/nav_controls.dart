import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/view_provider.dart';

class NavControls extends ConsumerStatefulWidget {
  const NavControls({super.key});

  @override
  ConsumerState<NavControls> createState() => _NavControlsState();
}

class _NavControlsState extends ConsumerState<NavControls> {
  bool _pickerOpen = false;

  static const _monthNames = [
    '1월','2월','3월','4월','5월','6월',
    '7월','8월','9월','10월','11월','12월',
  ];

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(viewProvider);
    final sh = context.sh;
    final notifier = ref.read(viewProvider.notifier);
    final isYear = view.mode == ViewMode.year;

    final label = isYear
        ? '${view.viewYear}년'
        : '${view.viewYear}년 ${_monthNames[view.viewMonth - 1]}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: sh.bg,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isYear) _NavBtn('≪', () => notifier.prevYear(), sh),
              _NavBtn('＜', () => isYear ? notifier.prevYear() : notifier.prevMonth(), sh),
              const SizedBox(width: 4),
              // 월 레이블 — 탭하면 날짜 피커 팝업
              GestureDetector(
                onTap: () => setState(() => _pickerOpen = !_pickerOpen),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: sh.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _NavBtn('＞', () => isYear ? notifier.nextYear() : notifier.nextMonth(), sh),
              if (!isYear) _NavBtn('≫', () => notifier.nextYear(), sh),
              const SizedBox(width: 8),
              // 오늘 버튼
              _TodayBtn(onTap: () {
                notifier.goToToday();
                if (view.mode != ViewMode.events) {
                  notifier.setMode(ViewMode.events);
                }
              }, sh: sh),
            ],
          ),
          // 날짜 피커 팝업
          if (_pickerOpen)
            _DatePickerPopup(
              year: view.viewYear,
              month: view.viewMonth,
              sh: sh,
              onSelect: (y, m) {
                notifier.setYearMonth(y, m);
                setState(() => _pickerOpen = false);
              },
            ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _NavBtn(this.label, this.onTap, this.sh);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(label,
            style: TextStyle(fontSize: 14, color: sh.inkSoft, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _TodayBtn extends StatelessWidget {
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _TodayBtn({required this.onTap, required this.sh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: sh.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('오늘',
            style: TextStyle(
                fontSize: 12, color: sh.inkSoft, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _DatePickerPopup extends StatefulWidget {
  final int year;
  final int month;
  final SpaceHourColors sh;
  final void Function(int, int) onSelect;
  const _DatePickerPopup({
    required this.year, required this.month,
    required this.sh, required this.onSelect,
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
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sh.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 연도 컬럼
          _PickerCol(
            items: List.generate(11, (i) => '${_year - 5 + i}년'),
            selected: 5,
            onChanged: (i) => setState(() => _year = _year - 5 + i),
            sh: sh,
          ),
          const SizedBox(width: 8),
          // 월 컬럼
          _PickerCol(
            items: List.generate(12, (i) => '${i + 1}월'),
            selected: _month - 1,
            onChanged: (i) {
              widget.onSelect(_year, i + 1);
            },
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
    required this.items, required this.selected,
    required this.onChanged, required this.sh,
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
                      borderRadius: BorderRadius.circular(8))
                  : null,
              child: Center(
                child: Text(items[i],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? sh.accentInk : sh.inkSoft)),
              ),
            ),
          );
        },
      ),
    );
  }
}
