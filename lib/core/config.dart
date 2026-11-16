/// ثوابت التطبيق.
class AppConfig {
  AppConfig._();

  /// لازم يتغيّر مع `version` في pubspec.yaml.
  static const appVersion = '1.2.0';

  static const repoUrl = 'https://github.com/AdamG00D/Shen';

  /// بصمة مفتاح OpenPGP اللي بيوقّع ملفات الإصدارات (docs/shen-release-key.asc).
  static const releaseKeyFingerprint = 'B2D453B85430D721C1733C1FB0E8ADA63BD784BC';
}
