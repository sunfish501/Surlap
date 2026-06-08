import 'package:flutter/material.dart';

/// 스포츠 팀 로고 배지.
///
/// [logoUrl] 이미지가 있으면 흰 원 안에 보여주고, 없거나 로드에 실패하면
/// 종목 [emoji]로 대체한다. 로고 PNG들은 투명 배경이라 라이트/다크 모두
/// 흰 원 위에서 일관되게 보인다.
class SportLogo extends StatelessWidget {
  final String? logoUrl;
  final String emoji;
  final double size; // 배지 지름

  const SportLogo({
    super.key,
    required this.logoUrl,
    required this.emoji,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    final fallback = Center(
      child: Text(emoji, style: TextStyle(fontSize: size * 0.62)),
    );
    if (!hasLogo) return SizedBox(width: size, height: size, child: fallback);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(size * 0.14),
      child: Image.network(
        logoUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
