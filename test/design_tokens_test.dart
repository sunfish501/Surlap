import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surlap/core/theme/design_tokens.dart';

void main() {
  test('Surlap v2.1 typography and shape tokens stay exact', () {
    expect(AppType.titleLarge.fontSize, 20);
    expect(AppType.titleLarge.fontWeight, FontWeight.w600);
    expect(AppType.headlineLarge.fontSize, 28);
    expect(AppType.headlineLarge.fontWeight, FontWeight.w700);
    expect(Radii.card, 16);
    expect(Radii.sheet, 20);
    expect(Motion.fast, const Duration(milliseconds: 180));
    expect(Motion.base, const Duration(milliseconds: 260));
  });
}
