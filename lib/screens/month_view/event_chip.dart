import 'package:flutter/material.dart';
import '../../models/event_item.dart';
import '../../models/calendar_theme.dart';
import '../../core/theme/app_theme.dart';

/// 모든 이벤트 칩에 공통으로 적용하는 미묘한 그림자.
/// 칩 자체 색을 낮은 알파로 써서 카드 위에서 한 단계 떠 보이게 한다.
/// (다크 모드의 기존 패턴을 라이트 모드까지 일관되게 확장.)
List<BoxShadow> _chipShadow(Color color, bool dark) => [
      BoxShadow(
        color: color.withValues(alpha: dark ? 0.18 : 0.10),
        blurRadius: 4,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];

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
    // 생일: 분홍 틴트 + 케이크 아이콘.
    if (item.birthday) {
      return _IconChip(
          icon: Icons.cake_rounded, color: sh.birthdayColor, text: item.t, sh: sh);
    }
    // 학사일정: 청록 틴트 + 학교 아이콘으로 기존 일정과 구분.
    if (item.academic) {
      return _IconChip(
          icon: Icons.school_rounded,
          color: sh.academicColor,
          text: item.t,
          sh: sh);
    }
    // 스포츠 구독 경기: 종목 이모지 + 구독 색.
    if (item.sport) {
      return _EmojiChip(
          emoji: item.sportEmoji ?? '🏅',
          color: Color(item.sportColor ?? 0xFF6C63FF),
          text: item.t,
          sh: sh);
    }

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
          boxShadow: _chipShadow(themeColor ?? sh.accent, sh.dark),
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

/// 스포츠 구독 경기 칩 — 종목 이모지 + 구독 색.
class _EmojiChip extends StatelessWidget {
  final String emoji;
  final Color color;
  final String text;
  final SpaceHourColors sh;
  const _EmojiChip(
      {required this.emoji,
      required this.color,
      required this.text,
      required this.sh});

  @override
  Widget build(BuildContext context) {
    final textColor =
        sh.dark ? Color.lerp(color, Colors.white, 0.25)! : Color.lerp(color, Colors.black, 0.35)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.fromLTRB(4, 2, 5, 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: sh.dark ? 0.24 : 0.14),
        borderRadius: BorderRadius.circular(6),
        boxShadow: _chipShadow(color, sh.dark),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 9, height: 1.3)),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 생일·학사일정 등 아이콘 칩 공용.
class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final SpaceHourColors sh;
  const _IconChip(
      {required this.icon,
      required this.color,
      required this.text,
      required this.sh});

  @override
  Widget build(BuildContext context) {
    final textColor =
        sh.dark ? color : Color.lerp(color, Colors.black, 0.35)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.fromLTRB(4, 2, 5, 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: sh.dark ? 0.24 : 0.14),
        borderRadius: BorderRadius.circular(6),
        boxShadow: _chipShadow(color, sh.dark),
      ),
      child: Row(
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
