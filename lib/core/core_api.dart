import 'package:flutter/services.dart';

import 'models.dart';

/// خطأ جاي من الـ core (Kotlin). [code] نفس أسماء `Err` في `Errors.kt`.
class CoreException implements Exception {
  const CoreException(this.code, {this.waitMs = 0, this.detail});

  final String code;
  final int waitMs;
  final String? detail;

  @override
  String toString() => 'CoreException($code)';
}

/// كل الكلام مع الـ core (قناة `shen/core`). كل التشفير والتخزين بيحصل هناك — Dart بيعرض بس.
class Core {
  Core._();

  static const channel = MethodChannel('shen/core');

  static Future<T?> call<T>(String method, [Map<String, Object?> args = const {}]) async {
    try {
      return await channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      final d = e.details;
      final wait = d is Map ? (d['waitMs'] as num?)?.toInt() ?? 0 : 0;
      throw CoreException(e.code, waitMs: wait, detail: e.message);
    }
  }

  static Map<String, Object?> _map(Object? o) => Map<String, Object?>.from(o as Map);

  static List<Map<String, Object?>> _list(Object? o) =>
      (o as List? ?? const []).map((e) => Map<String, Object?>.from(e as Map)).toList();

  // ---------------- الخزنة ----------------

  static Future<VaultStatus> status() async => VaultStatus.fromMap(_map(await call<Map>('status')));

  static Future<void> setup(String password, String profileName, int color) =>
      call('setup', {'password': password, 'profileName': profileName, 'color': color});

  static Future<void> unlock(String password) => call('unlock', {'password': password});

  static Future<void> lock() => call('lock');

  static Future<void> changeMasterPassword(String old, String newPassword) =>
      call('changeMasterPassword', {'old': old, 'new': newPassword});

  static Future<bool> verifyMasterPassword(String password) async =>
      await call<bool>('verifyMasterPassword', {'password': password}) ?? false;

  static Future<void> wipeAll(String password) => call('wipeAll', {'password': password});

  static Future<void> setPassCache(int minutes) => call('setPassCache', {'minutes': minutes});

  static Future<bool> bioAvailable() async => await call<bool>('bioAvailable') ?? false;

  static Future<void> bioEnable(String title, String subtitle, String cancel) =>
      call('bioEnable', {'title': title, 'subtitle': subtitle, 'cancel': cancel});

  static Future<void> bioUnlock(String title, String subtitle, String cancel) =>
      call('bioUnlock', {'title': title, 'subtitle': subtitle, 'cancel': cancel});

  static Future<void> bioDisable() => call('bioDisable');

  // ---------------- البروفايلات ----------------

  static Future<List<Profile>> profiles() async => _list(await call<List>('profiles')).map(Profile.fromMap).toList();

  static Future<String> createProfile(String name, int color, String? password) async =>
      (await call<String>('createProfile', {'name': name, 'color': color, 'password': password}))!;

  static Future<void> updateProfile(String id, String name, int color) =>
      call('updateProfile', {'id': id, 'name': name, 'color': color});

  static Future<void> deleteProfile(String id, String masterPassword) =>
      call('deleteProfile', {'id': id, 'password': masterPassword});

  static Future<void> setActiveProfile(String id) => call('setActiveProfile', {'id': id});

  static Future<void> unlockProfile(String id, String password) =>
      call('unlockProfile', {'id': id, 'password': password});

  static Future<void> lockProfile(String id) => call('lockProfile', {'id': id});

  static Future<void> setProfilePassword(String id, String? password) =>
      call('setProfilePassword', {'id': id, 'password': password});

  // ---------------- مفاتيحي ----------------

  static Future<List<KeyInfo>> keys(String profile) async =>
      _list(await call<List>('keys', {'profile': profile})).map(KeyInfo.fromMap).toList();

  static Future<KeyInfo> generateKey({
    required String profile,
    required String name,
    String? email,
    String? comment,
    String? passphrase,
    String algo = 'cv25519',
    DateTime? expires,
  }) async =>
      KeyInfo.fromMap(_map(await call<Map>('generateKey', {
        'profile': profile,
        'name': name,
        'email': email,
        'comment': comment,
        'passphrase': passphrase,
        'algo': algo,
        'expires': expires?.millisecondsSinceEpoch,
      })));

  static Future<void> setDefaultKey(String profile, String fp) => call('setDefaultKey', {'profile': profile, 'fp': fp});

  static Future<bool> needsPassphrase(String profile, String fp) async =>
      await call<bool>('needsPassphrase', {'profile': profile, 'fp': fp}) ?? true;

  static Future<bool> checkKeyPassphrase(String profile, String fp, String? passphrase) async =>
      await call<bool>('checkKeyPassphrase', {'profile': profile, 'fp': fp, 'passphrase': passphrase}) ?? false;

  static Future<void> changeKeyPassphrase(String profile, String fp, String? old, String? newPassphrase) =>
      call('changeKeyPassphrase', {'profile': profile, 'fp': fp, 'passphrase': old, 'new': newPassphrase});

  static Future<void> setKeyExpiry(String profile, String fp, String? passphrase, DateTime? expires) => call(
      'setKeyExpiry', {'profile': profile, 'fp': fp, 'passphrase': passphrase, 'expires': expires?.millisecondsSinceEpoch});

  static Future<void> addUserId(String profile, String fp, String? passphrase, String userId) =>
      call('addUserId', {'profile': profile, 'fp': fp, 'passphrase': passphrase, 'userId': userId});

  static Future<void> revokeKey(String profile, String fp, String? passphrase, String reason, String description) =>
      call('revokeKey', {
        'profile': profile,
        'fp': fp,
        'passphrase': passphrase,
        'reason': reason,
        'description': description,
      });

  static Future<void> deleteKey(String profile, String fp, String masterPassword) =>
      call('deleteKey', {'profile': profile, 'fp': fp, 'password': masterPassword});

  static Future<String> exportPublic(String profile, List<String> fps) async =>
      (await call<String>('exportPublic', {'profile': profile, 'fps': fps}))!;

  static Future<String> exportSecret(String profile, String fp, String masterPassword) async =>
      (await call<String>('exportSecret', {'profile': profile, 'fp': fp, 'password': masterPassword}))!;

  static Future<String> revocationCert(String profile, String fp, String masterPassword) async =>
      (await call<String>('revocationCert', {'profile': profile, 'fp': fp, 'password': masterPassword}))!;

  // ---------------- جهات الاتصال ----------------

  static Future<List<KeyInfo>> contacts(String profile) async =>
      _list(await call<List>('contacts', {'profile': profile})).map(KeyInfo.fromMap).toList();

  static Future<List<KeyInfo>> previewImport(String profile, Uint8List data) async =>
      _list(await call<List>('previewImport', {'profile': profile, 'data': data})).map(KeyInfo.fromMap).toList();

  static Future<ImportResult> importKeys(String profile, Uint8List data, String scope, [List<String>? only]) async =>
      ImportResult.fromMap(_map(await call<Map>('importKeys', {'profile': profile, 'data': data, 'scope': scope, 'fps': only})));

  static Future<void> setContactScope(String profile, String fp, String scope) =>
      call('setContactScope', {'profile': profile, 'fp': fp, 'scope': scope});

  static Future<void> setContactVerified(String profile, String fp, bool verified) =>
      call('setContactVerified', {'profile': profile, 'fp': fp, 'verified': verified});

  static Future<void> setNote(String profile, String fp, String note) =>
      call('setNote', {'profile': profile, 'fp': fp, 'note': note});

  static Future<void> deleteContact(String profile, String fp) => call('deleteContact', {'profile': profile, 'fp': fp});

  static Future<void> certifyContact(String profile, String fp, String keyFp, String? passphrase) =>
      call('certifyContact', {'profile': profile, 'fp': fp, 'keyFp': keyFp, 'passphrase': passphrase});

  static Future<FingerprintMatch?> findFingerprint(String profile, String fp) async {
    final m = await call<Map>('findFingerprint', {'profile': profile, 'fp': fp});
    return m == null ? null : FingerprintMatch.fromMap(_map(m));
  }

  // ---------------- نصوص ----------------

  static Future<Inspection> inspect(String profile, Uint8List data) async =>
      Inspection.fromMap(_map(await call<Map>('inspect', {'profile': profile, 'data': data})));

  static Future<String> encryptText({
    required String profile,
    required String text,
    required List<String> recipients,
    String? signWith,
    String? passphrase,
    bool self = true,
  }) async =>
      (await call<String>('encryptText', {
        'profile': profile,
        'text': text,
        'recipients': recipients,
        'signWith': signWith,
        'passphrase': passphrase,
        'self': self,
      }))!;

  static Future<String> encryptTextWithPassword(String text, String password) async =>
      (await call<String>('encryptTextWithPassword', {'text': text, 'password': password}))!;

  static Future<DecryptOutcome> decryptText(String profile, Uint8List data,
          {String? keyFp, String? passphrase, String? password}) async =>
      DecryptOutcome.fromMap(_map(await call<Map>('decryptText', {
        'profile': profile,
        'data': data,
        'keyFp': keyFp,
        'passphrase': passphrase,
        'password': password,
      })));

  static Future<String> signText(String profile, String text, String keyFp, String? passphrase, {bool detached = false}) async =>
      (await call<String>('signText', {
        'profile': profile,
        'text': text,
        'keyFp': keyFp,
        'passphrase': passphrase,
        'mode': detached ? 'detached' : 'clear',
      }))!;

  static Future<DecryptOutcome> verifyText(String profile, Uint8List data, {Uint8List? signature}) async =>
      DecryptOutcome.fromMap(_map(await call<Map>('verifyText', {'profile': profile, 'data': data, 'signature': signature})));

  // ---------------- ملفات ----------------

  static Future<Inspection> inspectFile(String profile, String uri) async =>
      Inspection.fromMap(_map(await call<Map>('inspectFile', {'profile': profile, 'in': uri})));

  static Future<void> encryptFile({
    required String profile,
    required String input,
    required String output,
    List<String> recipients = const [],
    String? signWith,
    String? passphrase,
    String? password,
    String? fileName,
    bool armor = false,
    bool self = true,
  }) =>
      call('encryptFile', {
        'profile': profile,
        'in': input,
        'out': output,
        'recipients': recipients,
        'signWith': signWith,
        'passphrase': passphrase,
        'password': password,
        'fileName': fileName,
        'armor': armor,
        'self': self,
      });

  static Future<DecryptOutcome> decryptFile(String profile, String input, String output,
          {String? keyFp, String? passphrase, String? password}) async =>
      DecryptOutcome.fromMap(_map(await call<Map>('decryptFile', {
        'profile': profile,
        'in': input,
        'out': output,
        'keyFp': keyFp,
        'passphrase': passphrase,
        'password': password,
      })));

  static Future<void> signFile(String profile, String input, String output, String keyFp, String? passphrase) =>
      call('signFile', {'profile': profile, 'in': input, 'out': output, 'keyFp': keyFp, 'passphrase': passphrase});

  /// [signature] = ملف التوقيع المنفصل، أو [output] لو الملف موقّع جوه نفسه (المحتوى بيتكتب فيه).
  static Future<List<SigResult>> verifyFile(String profile, String input, {String? signature, String? output}) async =>
      _list(await call<List>('verifyFile', {'profile': profile, 'in': input, 'sig': signature, 'out': output}))
          .map(SigResult.fromMap)
          .toList();

  // ---------------- النسخ الاحتياطي ----------------

  static Future<BackupResult> exportBackup(String? profile, String password, String output) async =>
      BackupResult.fromMap(_map(await call<Map>('exportBackup', {'profile': profile, 'password': password, 'out': output})));

  static Future<BackupPreview> previewBackup(String input, String password) async =>
      BackupPreview.fromMap(_map(await call<Map>('previewBackup', {'in': input, 'password': password})));

  static Future<ImportResult> importBackup(String input, String password) async =>
      ImportResult.fromMap(_map(await call<Map>('importBackup', {'in': input, 'password': password})));
}
