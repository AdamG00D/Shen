import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// core وهمي في الذاكرة بدل Kotlin — للتيستات بتاعة الواجهة بس.
/// (التشفير الحقيقي متختبر في android/app/src/test على الـ JVM ومع gpg.)
class FakeCore {
  bool exists = false;
  bool unlocked = false;
  String password = '';
  final calls = <String>[];
  final profiles = <Map<String, Object?>>[];
  final keys = <String, List<Map<String, Object?>>>{};
  final contacts = <String, List<Map<String, Object?>>>{};
  final shared = <Map<String, Object?>>[];
  String active = '';
  int _n = 0;

  static Map<String, Object?> key(String name, {bool secret = true, String scope = 'profile', bool verified = false, int n = 1}) => {
        'fp': (n.toRadixString(16).padLeft(2, '0')) * 20,
        'keyId': (n.toRadixString(16).padLeft(2, '0')) * 8,
        'version': 4,
        'uids': ['$name <${name.toLowerCase()}@example.org>'],
        'validUids': ['$name <${name.toLowerCase()}@example.org>'],
        'primaryUid': '$name <${name.toLowerCase()}@example.org>',
        'algo': 'Ed25519',
        'created': DateTime(2026).millisecondsSinceEpoch,
        'expires': DateTime(2028).millisecondsSinceEpoch,
        'expired': false,
        'revoked': false,
        'secret': secret,
        'protected': secret,
        'canEncrypt': true,
        'canSign': true,
        'canCertify': secret,
        'subkeys': const [],
        'scope': secret ? null : scope,
        'verified': verified,
        'default': secret,
        'hasRevocation': secret,
      };

  void install() {
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('shen/core'), _handle);
    m.setMockMethodCallHandler(const MethodChannel('shen/system'), (call) async {
      calls.add('system.${call.method}');
      return null;
    });
  }

  Never _err(String code) => throw PlatformException(code: code);

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call.method);
    final a = Map<String, Object?>.from((call.arguments as Map?) ?? {});
    switch (call.method) {
      case 'status':
        return {'exists': exists, 'unlocked': unlocked, 'bio': false};
      case 'setup':
        exists = true;
        unlocked = true;
        password = a['password'] as String;
        _addProfile(a['profileName'] as String, false);
        return null;
      case 'unlock':
        if (a['password'] != password) _err('WRONG_PASSWORD');
        unlocked = true;
        return null;
      case 'lock':
        unlocked = false;
        return null;
      case 'setPassCache':
      case 'bioAvailable':
        return false;
      case 'verifyMasterPassword':
        return a['password'] == password;
      case 'profiles':
        if (!unlocked) _err('LOCKED');
        return [
          for (final p in profiles)
            {
              ...p,
              'active': p['id'] == active,
              'keys': (keys[p['id']] ?? []).length,
              'contacts': (contacts[p['id']] ?? []).length + shared.length,
            },
        ];
      case 'createProfile':
        return _addProfile(a['name'] as String, a['password'] != null);
      case 'setActiveProfile':
        active = a['id'] as String;
        return null;
      case 'keys':
        return keys[a['profile']] ?? [];
      case 'contacts':
        return [...?contacts[a['profile']], ...shared];
      case 'generateKey':
        final k = key(a['name'] as String, n: 10 + _n++);
        keys.putIfAbsent(a['profile'] as String, () => []).add(k);
        return k;
      case 'needsPassphrase':
        return false;
      case 'encryptText':
        return '-----BEGIN PGP MESSAGE-----\n\nFAKE\n-----END PGP MESSAGE-----';
      default:
        return null;
    }
  }

  String _addProfile(String name, bool hasPassword) {
    final id = 'p${profiles.length}';
    profiles.add({'id': id, 'name': name, 'color': 0, 'hasPassword': hasPassword, 'open': true});
    if (active.isEmpty) active = id;
    return id;
  }
}
