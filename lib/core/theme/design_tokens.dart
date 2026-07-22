import 'package:flutter/material.dart';

/// Surlap 디자인 시스템 v2.1.
/// 색은 기존 프리셋(context.sh)을 그대로 쓰고, 여기서는 간격·반경·타이포·그림자만 정의.
/// 카드의 위계는 그림자가 아닌 hairline border와 타이포로 표현한다.

/// 8pt 그리드 간격(4의 배수).
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // 화면 좌우/카드 기본 패딩
  static const double xl = 24; // 섹션 간 간격
  static const double xxl = 32;
}

/// 반경은 네 단계만 사용한다.
abstract final class Radii {
  static const double small = 8;
  static const double card = 16;
  static const double sheet = 20;
  static const double pill = 999;
}

/// 최소 터치 영역.
const double kMinTouch = 44;

/// 그림자는 칩 hover와 떠 있는 FAB·시트에만 허용한다.
abstract final class Shadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 18, offset: Offset(0, 6)),
  ];
}

/// Material TextTheme 명칭과 동일한 단일 타이포 체계.
abstract final class AppType {
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.3,
  );
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 1.2,
  );
  static const TextStyle number = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}

/// 모션은 180/260ms와 easeOutCubic만 사용한다.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 260);
  static const Curve curve = Curves.easeOutCubic;
}

/// 보더 두께 — 1px 미만은 hairline, 1px+는 divider.
abstract final class Borders {
  static const double hairline = 0.5;
  static const double divider = 1.0;
}
