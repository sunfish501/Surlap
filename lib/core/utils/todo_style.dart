import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 할 일 상태(0 없음/1 진행중/2 완료) 아이콘.
IconData todoStatusIcon(int status) => switch (status) {
      2 => Icons.check_circle_rounded,
      1 => Icons.timelapse_rounded, // 진행중
      _ => Icons.radio_button_unchecked_rounded,
    };

/// 상태별 아이콘 색상. (priorityColor는 미완료 0단계 기본색)
Color todoStatusColor(int status, int priority, SurlapColors sh) {
  if (status == 2) return sh.accent;
  if (status == 1) return const Color(0xFFE8943A); // 진행중 = 주황
  return todoPriorityColor(priority, sh);
}

/// 우선순위(1~3)별 색상. 0(없음)은 보조 텍스트색.
Color todoPriorityColor(int priority, SurlapColors sh) {
  switch (priority) {
    case 1:
      return const Color(0xFFE0564A); // 빨강 (높음)
    case 2:
      return const Color(0xFFE8943A); // 주황 (보통)
    case 3:
      return const Color(0xFF4A90D9); // 파랑 (낮음)
    default:
      return sh.inkSoft;
  }
}
