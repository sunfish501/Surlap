import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surlap/core/constants/color_presets.dart';
import 'package:surlap/core/constants/storage_keys.dart';
import 'package:surlap/core/theme/app_theme.dart';
import 'package:surlap/core/utils/date_utils.dart' as du;
import 'package:surlap/screens/day_view/day_view.dart';
import 'package:surlap/storage/local_store.dart';

void main() {
  testWidgets('calendar day shows lunch time together with the menu', (
    tester,
  ) async {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    SharedPreferences.setMockInitialValues({
      StorageKeys.neisCache: jsonEncode({
        'week': du.toDateKey(monday),
        'data': <String, dynamic>{},
        'lunch': {'${today.weekday - 1}': '김치볶음밥\n달걀국'},
      }),
    });
    await LocalStore.init();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(kDefaultPreset),
          home: Scaffold(body: DayView(dateKey: du.toDateKey(today))),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('점심시간 · 13:00'), findsOneWidget);
    expect(find.text('김치볶음밥 · 달걀국'), findsOneWidget);
  });
}
