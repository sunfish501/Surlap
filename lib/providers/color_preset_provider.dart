import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/color_presets.dart';

class ColorPresetNotifier extends Notifier<ColorPreset> {
  @override
  ColorPreset build() => kDefaultPreset;
}

final colorPresetProvider =
    NotifierProvider<ColorPresetNotifier, ColorPreset>(ColorPresetNotifier.new);
