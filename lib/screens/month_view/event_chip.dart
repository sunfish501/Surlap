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
        margin: const EdgeInsets.only(bottom: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        decoration: BoxDecoration(
          color: themeColor != null
              ? themeColor.withValues(alpha: 0.15)
              : sh.card2,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            if (themeColor != null)
              Container(
                width: 5, height: 5,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: themeColor, shape: BoxShape.circle),
              ),
            Expanded(
              child: Text(
                item.t,
                style: TextStyle(
                  fontSize: 10.5,
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
