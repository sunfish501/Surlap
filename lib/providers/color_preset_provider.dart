import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/color_presets.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

class ColorPresetNotifier extends Notifier<ColorPreset> {
  @override
  ColorPreset build() {
    final saved = LocalStore.instance.getString(StorageKeys.colorPreset);
    return presetById(saved ?? 'sage');
  }

  Future<void> setPreset(String id) async {
    state = presetById(id);
    await LocalStore.instance.setString(StorageKeys.colorPreset, id);
  }
}

final colorPresetProvider =
    NotifierProvider<ColorPresetNotifier, ColorPreset>(ColorPresetNotifier.new);
