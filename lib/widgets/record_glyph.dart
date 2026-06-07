import 'package:flutter/material.dart';

/// 기록 템플릿 아이콘 세트 — 단색 라인 아이콘(일관 굵기).
/// 저장은 이 id 문자열(템플릿 emoji 필드와 호환). 기존 이모지 값은 폴백 렌더.
const Map<String, IconData> kRecordIcons = {
  'menu_book': Icons.menu_book_rounded, // 공부
  'auto_stories': Icons.auto_stories_rounded, // 독서
  'fitness_center': Icons.fitness_center_rounded, // 운동(웨이트)
  'directions_run': Icons.directions_run_rounded, // 운동(러닝)
  'self_improvement': Icons.self_improvement_rounded, // 명상
  'water_drop': Icons.water_drop_rounded, // 물
  'bedtime': Icons.bedtime_rounded, // 수면
  'restaurant': Icons.restaurant_rounded, // 식사
  'medication': Icons.medication_rounded, // 약
  'music_note': Icons.music_note_rounded, // 음악
  'palette': Icons.palette_rounded, // 작업/취미
  'edit_note': Icons.edit_note_rounded, // 메모
  'timer': Icons.timer_rounded, // 타이머
  'local_fire_department': Icons.local_fire_department_rounded, // 불꽃/연속
  'star': Icons.star_rounded, // 별/기타
};

/// id 순서 보존 목록(에디터 그리드용).
const List<String> kRecordIconIds = [
  'menu_book', 'auto_stories', 'fitness_center', 'directions_run',
  'self_improvement', 'water_drop', 'bedtime', 'restaurant',
  'medication', 'music_note', 'palette', 'edit_note',
  'timer', 'local_fire_department', 'star',
];

IconData? recordIconData(String value) => kRecordIcons[value];

/// 템플릿 글리프: 아이콘 id면 단색 Icon, 아니면(이모지 등) Text 폴백.
/// 데이터 없음 표시는 [faint]로 흐리게.
Widget recordGlyph(String value,
    {required double size, required Color color, bool faint = false}) {
  final icon = kRecordIcons[value];
  if (icon != null) {
    return Icon(icon,
        size: size, color: faint ? color.withValues(alpha: 0.4) : color);
  }
  // 이모지 폴백 — 색 적용 불가라 흐림은 Opacity로.
  final text = Text(value,
      style: TextStyle(fontSize: size * 0.92, height: 1.0));
  return faint ? Opacity(opacity: 0.35, child: text) : text;
}
