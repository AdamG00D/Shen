import 'dart:async';

import 'package:flutter/widgets.dart';

import 'core_api.dart';
import 'models.dart';
import 'settings.dart';

enum Phase { loading, setup, locked, unlocked }

/// حالة التطبيق: الخزنة مفتوحة ولا لأ، البروفايل الحالي، مفاتيحه وجهات اتصاله.
/// وكمان القفل التلقائي لما التطبيق يروح في الخلفية.
class Session extends ChangeNotifier with WidgetsBindingObserver {
  Session._();
  static final Session instance = Session._();

  Phase phase = Phase.loading;
  bool bioEnabled = false;
  List<Profile> profiles = const [];
  List<KeyInfo> keys = const [];
  List<KeyInfo> contacts = const [];

  /// بيتنده لما الخزنة تتقفل (عشان الشاشات المفتوحة تتقفل).
  VoidCallback? onLocked;

  /// آخر تبويب كان مفتوح — بيرجع عليه بعد فتح القفل. رقم بس، من غير أي محتوى.
  int lastTab = 0;

  DateTime? _pausedAt;
  int _outside = 0;
  Timer? _lockTimer;

  Profile? get active {
    for (final p in profiles) {
      if (p.active) return p;
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  /// مفاتيحي اللي تقدر توقّع (مش منتهية ولا ملغية).
  List<KeyInfo> get signingKeys => keys.where((k) => k.usable && k.canSign).toList();

  KeyInfo? get defaultKey {
    for (final k in keys) {
      if (k.isDefault) return k;
    }
    return keys.isEmpty ? null : keys.first;
  }

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    final s = await Core.status();
    bioEnabled = s.bio;
    phase = !s.exists ? Phase.setup : (s.unlocked ? Phase.unlocked : Phase.locked);
    if (phase == Phase.unlocked) await refresh();
    notifyListeners();
  }

  Future<void> setup(String password, String profileName, int color) async {
    await Core.setup(password, profileName, color);
    await _afterUnlock();
  }

  Future<void> unlock(String password) async {
    await Core.unlock(password);
    await _afterUnlock();
  }

  Future<void> unlockWithBio(String title, String subtitle, String cancel) async {
    // نافذة البصمة بتعدّي التطبيق على "رجع للواجهة" — متتحسبش خروج
    await outside(() => Core.bioUnlock(title, subtitle, cancel));
    await _afterUnlock();
  }

  Future<void> _afterUnlock() async {
    _pausedAt = null;
    _lockTimer?.cancel();
    await Core.setPassCache(AppSettings.instance.passCacheMinutes);
    final s = await Core.status();
    bioEnabled = s.bio;
    phase = Phase.unlocked;
    await refresh();
  }

  Future<void> lock() async {
    if (phase != Phase.unlocked) return;
    _lockTimer?.cancel();
    // لو فضل متسجّل، أول "رجوع للواجهة" بعد الفتح (زي قفلة نافذة البصمة) هيقفل تاني
    _pausedAt = null;
    try {
      await Core.lock();
    } catch (_) {}
    phase = Phase.locked;
    profiles = const [];
    keys = const [];
    contacts = const [];
    onLocked?.call();
    notifyListeners();
  }

  /// بعد ما كل حاجة اتمسحت.
  void wiped() {
    phase = Phase.setup;
    lastTab = 0;
    bioEnabled = false;
    profiles = const [];
    keys = const [];
    contacts = const [];
    onLocked?.call();
    notifyListeners();
  }

  Future<void> refreshBio() async {
    bioEnabled = (await Core.status()).bio;
    notifyListeners();
  }

  /// يحمّل البروفايلات + مفاتيح وجهات اتصال البروفايل الحالي.
  Future<void> refresh() async {
    if (phase != Phase.unlocked) return;
    profiles = await Core.profiles();
    final a = active;
    if (a != null && a.open) {
      keys = await Core.keys(a.id);
      contacts = await Core.contacts(a.id);
    } else {
      keys = const [];
      contacts = const [];
    }
    notifyListeners();
  }

  Future<void> switchProfile(String id) async {
    await Core.setActiveProfile(id);
    await refresh();
  }

  // ---------------- القفل التلقائي ----------------

  /// نوافذ النظام (اختيار ملف، QR، البصمة، المشاركة) بتخلي التطبيق "في الخلفية" —
  /// منقفلش وإحنا مستنيين المستخدم يرجع منها.
  Future<T> outside<T>(Future<T> Function() f) async {
    _outside++;
    try {
      return await f();
    } finally {
      _outside--;
      _pausedAt = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (phase != Phase.unlocked) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_outside > 0) return;
        _pausedAt ??= DateTime.now();
        final secs = AppSettings.instance.autoLockSeconds;
        _lockTimer?.cancel();
        if (secs == 0) {
          lock();
        } else {
          _lockTimer = Timer(Duration(seconds: secs), lock);
        }
      case AppLifecycleState.resumed:
        _lockTimer?.cancel();
        final at = _pausedAt;
        _pausedAt = null;
        if (at != null && _outside == 0 &&
            DateTime.now().difference(at).inSeconds >= AppSettings.instance.autoLockSeconds) {
          lock();
        }
      case AppLifecycleState.detached:
        lock();
      case AppLifecycleState.inactive:
        break;
    }
  }
}
