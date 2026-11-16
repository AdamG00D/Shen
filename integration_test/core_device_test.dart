// تيست على موبايل / محاكي حقيقي: الـ core الحقيقي (Keystore + PGPainless على ART) من خلال القناة نفسها.
//   flutter test integration_test -d <device>
// ⚠️ بيمسح بيانات شِن اللي على الجهاز — شغّله على محاكي أو موبايل تجارب بس.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shen/core/core_api.dart';

const _pw = 'device test master password';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

Future<void> _expectCode(String code, Future<void> Function() f) async {
  try {
    await f();
    fail('expected $code');
  } on CoreException catch (e) {
    expect(e.code, code);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real core on Android: vault, keys, encryption, profiles', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var s = await Core.status();
    if (s.exists) {
      if (!s.unlocked) await Core.unlock(_pw);
      await Core.wipeAll(_pw);
    }
    expect((await Core.status()).exists, isFalse);

    final sw = Stopwatch()..start();
    await Core.setup(_pw, 'Personal', 0);
    debugPrint('setup (Argon2id 64 MiB + Keystore): ${sw.elapsedMilliseconds} ms');
    final personal = (await Core.profiles()).single.id;

    sw.reset();
    final me = await Core.generateKey(profile: personal, name: 'Device User', email: 'device@example.org', passphrase: 'key passphrase 1');
    debugPrint('generate Ed25519 key: ${sw.elapsedMilliseconds} ms');
    expect(me.canEncrypt, isTrue);
    expect(me.protected, isTrue);

    // تشفير لنفسي وفك
    final ct = await Core.encryptText(profile: personal, text: 'سر على الموبايل', recipients: [], signWith: me.fp, passphrase: 'key passphrase 1');
    expect(ct, startsWith('-----BEGIN PGP MESSAGE-----'));
    final ins = await Core.inspect(personal, _b(ct));
    expect(ins.kind, 'encrypted');
    expect(ins.mine.single.fp, me.fp);
    await _expectCode('WRONG_PASSWORD', () => Core.decryptText(personal, _b(ct), keyFp: me.fp, passphrase: 'wrong'));
    final dec = await Core.decryptText(personal, _b(ct), keyFp: me.fp, passphrase: 'key passphrase 1');
    expect(dec.text, 'سر على الموبايل');
    expect(dec.signatures.single.good, isTrue);
    expect(dec.signatures.single.mine, isTrue);

    // توقيع نصي وتحقق
    final signed = await Core.signText(personal, 'hello', me.fp, 'key passphrase 1');
    final v = await Core.verifyText(personal, _b(signed));
    expect(v.signatures.single.good, isTrue);

    // بروفايل الشغل بكلمة سر لوحده + جهة اتصال مشتركة
    final work = await Core.createProfile('Work', 3, 'work profile pw');
    final pub = await Core.exportPublic(personal, [me.fp]);
    final r = await Core.importKeys(work, _b(pub), 'profile');
    expect(r.added, 1);
    expect((await Core.contacts(work)).single.fp, me.fp);
    expect(await Core.contacts(personal), isEmpty);

    // قفل وفتح: الخزنة الحقيقية بمفتاح الـ Keystore
    await Core.lock();
    await _expectCode('LOCKED', () => Core.profiles());
    await _expectCode('WRONG_PASSWORD', () => Core.unlock('not the password'));
    sw.reset();
    await Core.unlock(_pw);
    debugPrint('unlock: ${sw.elapsedMilliseconds} ms');
    final profiles = await Core.profiles();
    expect(profiles.firstWhere((p) => p.id == work).open, isFalse);
    await _expectCode('PROFILE_LOCKED', () => Core.keys(work));
    await _expectCode('WRONG_PASSWORD', () => Core.unlockProfile(work, 'nope nope'));
    await Core.unlockProfile(work, 'work profile pw');
    expect((await Core.contacts(work)).single.fp, me.fp);
    expect((await Core.keys(personal)).single.fp, me.fp);

    // رسايل ضارة متوقّعش التطبيق
    for (final junk in ['', '-----BEGIN PGP MESSAGE-----\n\nAAAA\n-----END PGP MESSAGE-----', 'x' * 5000]) {
      try {
        await Core.decryptText(personal, _b(junk));
      } on CoreException {
        // أي كود تمام
      }
    }

    // مسح كل حاجة
    await _expectCode('WRONG_PASSWORD', () => Core.wipeAll('wrong password!'));
    await Core.wipeAll(_pw);
    s = await Core.status();
    expect(s.exists, isFalse);
  });
}
