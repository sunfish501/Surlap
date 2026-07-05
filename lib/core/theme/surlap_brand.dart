import 'package:flutter/material.dart';

/// Surlap 브랜드 로고 / 워드마크 전용 컬러 램프.
/// 메인 앱 테마(`SurlapColors`)와 분리 — 로고 자체의 시각 밸런스가 핵심이므로
/// 임의로 톤 다운하지 말 것.
abstract final class SurlapBrand {
  /// 잉크 / 워드마크 텍스트 (라이트 배경)
  static const ink = Color(0xFF1B0A3A);
  static const orbit800 = Color(0xFF4C1D95);   // 바깥 궤도
  static const orbit700 = Color(0xFF6D28D9);   // 단색 심볼 기본 / 강조
  static const orbit600 = Color(0xFF7C3AED);   // 중간 궤도 / 그라데이션 시작
  static const orbit500 = Color(0xFF8B5CF6);   // 보조 강조
  static const orbit400 = Color(0xFFA855F7);   // 안쪽 궤도
  static const orbit300 = Color(0xFFC4B5FD);   // 반전 안쪽 / 라이트 강조
  static const chip100 = Color(0xFFF3EEFF);    // 칩 배경

  /// 다크 배경 반전 톤(워드마크/심볼 mono 색).
  static const darkOrbit800 = Color(0xFF7C5CE0);
  static const darkOrbit600 = Color(0xFFA78BFA);
  static const darkOrbit400 = Color(0xFFC4B5FD);

  /// 앱 아이콘 그라데이션 (145°, #7C3AED → #4C1D95).
  static const iconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orbit600, orbit800],
  );
}
