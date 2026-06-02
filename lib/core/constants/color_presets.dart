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

// 원본 COLOR_PRESETS 8개 — 값 변경 금지.
const kColorPresets = [
  ColorPreset(
    id: 'sage', name: '세이지',
    dot: Color(0xFF6E8E5E), accent: Color(0xFF6E8E5E), accentInk: Color(0xFF4E6A40),
    accentBg: Color(0xFFE5EFDD), app: Color(0xFFF2F5EC), card: Color(0xFFFFFFFF),
    card2: Color(0xFFF7F5F0), hairline: Color(0xFFECEAE3), ink: Color(0xFF3B342C),
    inkSoft: Color(0xFF8C8377), inkFaint: Color(0xFFB7AEA1),
  ),
  ColorPreset(
    id: 'lavender', name: '라벤더',
    dot: Color(0xFF8B7BC0), accent: Color(0xFF8B7BC0), accentInk: Color(0xFF62548F),
    accentBg: Color(0xFFEAE4F5), app: Color(0xFFF4F1FA), card: Color(0xFFFFFFFF),
    card2: Color(0xFFF5F2FB), hairline: Color(0xFFE0DAF0), ink: Color(0xFF28204A),
    inkSoft: Color(0xFF706888), inkFaint: Color(0xFFA89EC4),
  ),
  ColorPreset(
    id: 'rose', name: '로즈',
    dot: Color(0xFFCF7088), accent: Color(0xFFCF7088), accentInk: Color(0xFFA24E64),
    accentBg: Color(0xFFF7E3EA), app: Color(0xFFFBF1F4), card: Color(0xFFFFFFFF),
    card2: Color(0xFFFBF0F3), hairline: Color(0xFFEDD6DE), ink: Color(0xFF38202A),
    inkSoft: Color(0xFF8A5868), inkFaint: Color(0xFFC0909E),
  ),
  ColorPreset(
    id: 'peach', name: '피치',
    dot: Color(0xFFD8835A), accent: Color(0xFFD8835A), accentInk: Color(0xFFAC5C36),
    accentBg: Color(0xFFFAE3D6), app: Color(0xFFFCF3ED), card: Color(0xFFFFFFFF),
    card2: Color(0xFFFBF0E8), hairline: Color(0xFFEDD8C8), ink: Color(0xFF3C2014),
    inkSoft: Color(0xFF886050), inkFaint: Color(0xFFC09878),
  ),
  ColorPreset(
    id: 'butter', name: '버터',
    dot: Color(0xFFC99A2E), accent: Color(0xFFC99A2E), accentInk: Color(0xFF8E6C14),
    accentBg: Color(0xFFF4EAC6), app: Color(0xFFF9F4E4), card: Color(0xFFFFFFFF),
    card2: Color(0xFFF8F2DC), hairline: Color(0xFFE8D898), ink: Color(0xFF342A10),
    inkSoft: Color(0xFF7A6840), inkFaint: Color(0xFFB89E60),
  ),
  ColorPreset(
    id: 'sky', name: '스카이',
    dot: Color(0xFF5A86C4), accent: Color(0xFF5A86C4), accentInk: Color(0xFF3E6298),
    accentBg: Color(0xFFE2EBF7), app: Color(0xFFEFF4FB), card: Color(0xFFFFFFFF),
    card2: Color(0xFFEAF0F8), hairline: Color(0xFFC8D8EE), ink: Color(0xFF182438),
    inkSoft: Color(0xFF506888), inkFaint: Color(0xFF8AAAC8),
  ),
  ColorPreset(
    id: 'default', name: '스페이스',
    dot: Color(0xFF6B8EC2), accent: Color(0xFF6B8EC2), accentInk: Color(0xFF3E6298),
    accentBg: Color(0xFFDDEAFF), app: Color(0xFFEEF3FA), card: Color(0xFFFFFFFF),
    card2: Color(0xFFEEF2F8), hairline: Color(0xFFD0DAEA), ink: Color(0xFF1E2A38),
    inkSoft: Color(0xFF546070), inkFaint: Color(0xFF9AAABF),
  ),
  ColorPreset(
    id: 'dark', name: '다크모드',
    dot: Color(0xFFC9A878), accent: Color(0xFFC9A878), accentInk: Color(0xFFE2C795),
    accentBg: Color(0xFF3A3024), app: Color(0xFF211D17), card: Color(0xFF2C2720),
    card2: Color(0xFF251F19), hairline: Color(0xFF3B352D), ink: Color(0xFFECE5D9),
    inkSoft: Color(0xFFA89E8E), inkFaint: Color(0xFF6E6557),
    dark: true,
  ),
  // Dark Elegant — 차콜 + 인디고/바이올렛 포인트
  ColorPreset(
    id: 'dark_elegant', name: '다크 엘레강스',
    dot: Color(0xFF9B8FE0),
    accent: Color(0xFF9B8FE0), accentInk: Color(0xFFCEC4FF),
    accentBg: Color(0xFF201E3C),
    app: Color(0xFF0E0E14), card: Color(0xFF1A1A24),
    card2: Color(0xFF22223A), hairline: Color(0xFF2E2E42),
    ink: Color(0xFFEDEDF2), inkSoft: Color(0xFF9898AC), inkFaint: Color(0xFF5A5A72),
    dark: true,
  ),
];

ColorPreset presetById(String id) =>
    kColorPresets.firstWhere((p) => p.id == id, orElse: () => kColorPresets.first);
