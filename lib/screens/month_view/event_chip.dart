import 'package:flutter/material.dart';
import '../../models/event_item.dart';
import '../../models/calendar_theme.dart';
import '../../core/theme/app_theme.dart';

class EventChip extends StatelessWidget {
  final EventItem item;
  final List<CalendarTheme> themes;
  final SpaceHourColors sh;
  final VoidCallback? onTap;

  const EventChip({
    super.key,
    required this.item,
    required this.themes,
    required this.sh,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = _resolveColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.fromLTRB(5, 2, 5, 2.5),
        decoration: BoxDecoration(
          color: themeColor != null
              ? themeColor.withValues(alpha: sh.dark ? 0.22 : 0.14)
              // 미분류 일정도 카드보다 한 단계 따뜻한 연한 틴트로.
              : sh.accent.withValues(alpha: sh.dark ? 0.16 : 0.07),
          borderRadius: BorderRadius.circular(6),
          boxShadow: (sh.dark && themeColor != null)
              ? [BoxShadow(
                  color: themeColor.withValues(alpha: 0.18),
                  blurRadius: 4, spreadRadius: 0,
                )]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 5, height: 5,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: themeColor ?? sh.accent.withValues(alpha: 0.7),
                shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(
                item.t,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: sh.ink,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _resolveColor() {
    final ids = item.themeIds;
    if (ids.isEmpty) return null;
    try {
      final t = themes.firstWhere((t) => ids.contains(t.id));
      return t.colorValue;
    } catch (_) {
      return null;
    }
  }
}
