import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// إعدادات الشكل والسلوك (مش سرية: لغة، ثيم، مدد القفل). المفاتيح والبيانات كلها في الخزنة.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  SharedPreferences? _prefs;

  /// null = لغة الموبايل.
  String? language;
  ThemeMode themeMode = ThemeMode.system;

  /// القفل التلقائي بعد ما التطبيق يروح في الخلفية (ثواني). 0 = على طول.
  int autoLockSeconds = 60;

  /// حفظ كلمات سر المفاتيح في الذاكرة (دقايق). 0 = متتحفظش (الافتراضي).
  int passCacheMinutes = 0;

  /// مسح الحافظة بعد النسخ (ثواني).
  int clipboardSeconds = 45;

  static const autoLockChoices = [0, 30, 60, 300, 900];
  static const passCacheChoices = [0, 1, 5, 15];
  static const clipboardChoices = [20, 45, 90];

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    language = p.getString('language');
    themeMode = ThemeMode.values.firstWhere((m) => m.name == p.getString('theme'), orElse: () => ThemeMode.system);
    autoLockSeconds = _pick(p.getInt('autoLock'), autoLockChoices, 60);
    passCacheMinutes = _pick(p.getInt('passCache'), passCacheChoices, 0);
    clipboardSeconds = _pick(p.getInt('clipboard'), clipboardChoices, 45);
  }

  static int _pick(int? v, List<int> allowed, int fallback) => v != null && allowed.contains(v) ? v : fallback;

  Future<void> update({
    String? Function()? language,
    ThemeMode? themeMode,
    int? autoLockSeconds,
    int? passCacheMinutes,
    int? clipboardSeconds,
  }) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    if (language != null) {
      this.language = language();
      this.language == null ? await p.remove('language') : await p.setString('language', this.language!);
    }
    if (themeMode != null) {
      this.themeMode = themeMode;
      await p.setString('theme', themeMode.name);
    }
    if (autoLockSeconds != null) {
      this.autoLockSeconds = autoLockSeconds;
      await p.setInt('autoLock', autoLockSeconds);
    }
    if (passCacheMinutes != null) {
      this.passCacheMinutes = passCacheMinutes;
      await p.setInt('passCache', passCacheMinutes);
    }
    if (clipboardSeconds != null) {
      this.clipboardSeconds = clipboardSeconds;
      await p.setInt('clipboard', clipboardSeconds);
    }
    notifyListeners();
  }
}
