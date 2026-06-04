import 'package:flutter/material.dart';
import '../constants/color_presets.dart';

/// ColorPreset → Flutter ThemeData 변환.
/// 웹 CSS 변수 대응:
///   --bg              → scaffold bg
///   --cell-bg         → card / surface
///   --today-accent    → primary
///   --text            → onSurface
///   --border          → divider / outline
ThemeData buildTheme(ColorPreset p) {
  final cs = ColorScheme(
    brightness: p.dark ? Brightness.dark : Brightness.light,
    primary: p.accent,
    onPrimary: p.dark ? p.ink : Colors.white,
    primaryContainer: p.accentBg,
    onPrimaryContainer: p.accentInk,
    secondary: p.accent,
    onSecondary: Colors.white,
    secondaryContainer: p.accentBg,
    onSecondaryContainer: p.accentInk,
    surface: p.card,
    onSurface: p.ink,
    surfaceContainerHighest: p.card2,
    error: const Color(0xFFD9614E),
    onError: Colors.white,
    outline: p.hairline,
    outlineVariant: p.hairline,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: p.app,
    cardColor: p.card,
    dividerColor: p.hairline,
    fontFamily: 'Pretendard',
    textTheme: _buildTextTheme(p.ink, p.inkSoft),
    appBarTheme: AppBarTheme(
      backgroundColor: p.app,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: p.ink,
      titleTextStyle: TextStyle(
        color: p.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Pretendard Variable',
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.dark ? p.ink : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Pretendard'),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Pretendard'),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? p.accent : Colors.transparent),
      checkColor: WidgetStateProperty.all(
          p.dark ? p.ink : Colors.white),
      side: BorderSide(color: p.inkSoft),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? p.accent : p.inkFaint),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? p.accentBg
              : p.hairline),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        color: p.ink, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Pretendard'),
    ),
    extensions: [SpaceHourColors(preset: p)],
  );
}

TextTheme _buildTextTheme(Color ink, Color inkSoft) => TextTheme(
  bodyLarge: TextStyle(color: ink, fontFamily: 'Pretendard', fontSize: 15),
  bodyMedium: TextStyle(color: ink, fontFamily: 'Pretendard', fontSize: 13),
  bodySmall: TextStyle(color: inkSoft, fontFamily: 'Pretendard', fontSize: 11),
  labelLarge: TextStyle(color: ink, fontFamily: 'Pretendard', fontWeight: FontWeight.w600, fontSize: 13),
  titleMedium: TextStyle(color: ink, fontFamily: 'Pretendard', fontWeight: FontWeight.w600, fontSize: 15),
  titleSmall: TextStyle(color: inkSoft, fontFamily: 'Pretendard', fontSize: 12),
);

/// ThemeExtension으로 색상 토큰 전달 — Theme.of(context).extension 으로 접근.
class SpaceHourColors extends ThemeExtension<SpaceHourColors> {
  final ColorPreset preset;
  const SpaceHourColors({required this.preset});

  Color get bg       => preset.app;
  Color get card     => preset.card;
  Color get card2    => preset.card2;
  Color get border   => preset.hairline;
  Color get ink      => preset.ink;
  Color get inkSoft  => preset.inkSoft;
  Color get inkFaint => preset.inkFaint;
  Color get accent   => preset.accent;
  Color get accentBg => preset.accentBg;
  Color get accentInk => preset.accentInk;
  Color get dot      => preset.dot;
  bool  get dark     => preset.dark;
  // 주말 색 — 너무 튀지 않는 soft red / soft blue
  Color get sat      => preset.dark ? const Color(0xFF8AAAC8) : const Color(0xFF5C7CFA);
  Color get sun      => preset.dark ? const Color(0xFFD98A8A) : const Color(0xFFE86A6A);
  // 파괴적 액션용 (삭제 등)
  Color get danger   => const Color(0xFFD9614E);
  // NEIS 학사일정 — 기존 일정과 구분되는 청록 톤.
  Color get academicColor => const Color(0xFF0FB5AE);
  // 생일 — 분홍 톤.
  Color get birthdayColor => const Color(0xFFEC4899);

  @override
  SpaceHourColors copyWith({ColorPreset? preset}) =>
      SpaceHourColors(preset: preset ?? this.preset);

  @override
  SpaceHourColors lerp(SpaceHourColors? other, double t) => this;
}

extension BuildContextThemeX on BuildContext {
  SpaceHourColors get sh =>
      Theme.of(this).extension<SpaceHourColors>()!;
}
