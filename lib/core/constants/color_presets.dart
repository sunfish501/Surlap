import 'package:flutter/material.dart';

class ColorPreset {
  final String id;
  final String name;
  final Color dot;
  final Color accent;
  final Color accentInk;
  final Color accentBg;
  final Color app;
  final Color card;
  final Color card2;
  final Color hairline;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final bool dark;

  const ColorPreset({
    required this.id,
    required this.name,
    required this.dot,
    required this.accent,
    required this.accentInk,
    required this.accentBg,
    required this.app,
    required this.card,
    required this.card2,
    required this.hairline,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    this.dark = false,
  });
}

// 단일 프리셋: 흰 배경 + 검정 글씨 / 테마 선택 제거
const kDefaultPreset = ColorPreset(
  id: 'light',
  name: 'HourSpace',
  dot: Color(0xFF1A1A1A),
  accent: Color(0xFF1A1A1A),
  accentInk: Color(0xFF111111),
  accentBg: Color(0xFFEEEEEE),
  app: Color(0xFFF8F8F8),
  card: Color(0xFFFFFFFF),
  card2: Color(0xFFF3F3F3),
  hairline: Color(0xFFE2E2E2),
  ink: Color(0xFF111111),
  inkSoft: Color(0xFF666666),
  inkFaint: Color(0xFFAAAAAA),
  dark: false,
);

// presetById 호출 코드 하위 호환용
ColorPreset presetById(String id) => kDefaultPreset;
