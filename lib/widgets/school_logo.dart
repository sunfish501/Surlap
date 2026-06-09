import 'package:flutter/material.dart';

/// 학교 로고 배지.
///
/// 한국 학교 홈페이지는 대부분 제대로 된 favicon이 없어 자동 로고를 못 받는다.
/// 그래서 [logoUrl] → [fallbackUrl] 순으로 시도하고, 둘 다 실패하면 학교명 첫
/// 글자를 색 원에 그린 '글자 배지'로 대체한다(항상 뜨고 학교마다 구분됨).
class SchoolLogo extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final String? fallbackUrl;
  final double size;

  const SchoolLogo({
    super.key,
    required this.name,
    required this.logoUrl,
    this.fallbackUrl,
    this.size = 32,
  });

  // 이름 기반 결정적 색(학교마다 안정적으로 다른 색).
  static const _palette = [
    Color(0xFF5B8DEF), Color(0xFFE2657A), Color(0xFF3DB58A),
    Color(0xFFF0A33C), Color(0xFF9B6CF0), Color(0xFF18B0BE),
    Color(0xFFEC6AA8), Color(0xFFF0743F),
  ];

  Color get _badgeColor {
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _palette[h % _palette.length];
  }

  String get _initial => name.trim().isEmpty ? '?' : name.trim().characters.first;

  Widget _letterBadge() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _badgeColor,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        alignment: Alignment.center,
        child: Text(
          _initial,
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
      );

  Widget _img(String url, Widget onError) => Image.network(
        url,
        width: size * 0.72,
        height: size * 0.72,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => onError,
      );

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    final hasFb = fallbackUrl != null && fallbackUrl!.isNotEmpty;
    if (!hasLogo) return _letterBadge();

    // 로고 → (실패) 폴백 → (실패) 글자 배지. 로고는 흰 배경 박스 안에.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: _img(
        logoUrl!,
        hasFb ? _img(fallbackUrl!, _letterBadge()) : _letterBadge(),
      ),
    );
  }
}
