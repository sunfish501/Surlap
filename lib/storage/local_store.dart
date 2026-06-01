import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 래퍼 — 웹 localStorage와 동일한 get/set 인터페이스.
class LocalStore {
  LocalStore._();
  static LocalStore? _instance;
  static LocalStore get instance => _instance!;

  late SharedPreferences _prefs;

  static Future<LocalStore> init() async {
    _instance ??= LocalStore._();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
}
