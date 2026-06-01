import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/color_preset_provider.dart';
import 'screens/main_shell.dart';

class SpaceHourApp extends ConsumerWidget {
  const SpaceHourApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(colorPresetProvider);
    return MaterialApp(
      title: 'spaceHour',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(preset),
      home: const MainShell(),
    );
  }
}
