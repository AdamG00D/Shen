import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shen/app.dart';
import 'package:shen/core/session.dart';
import 'package:shen/core/settings.dart';
import 'package:shen/core/system.dart';
import 'package:shen/l10n/app_localizations.dart';

import 'support/fake_core.dart';

late FakeCore core;

Future<void> startApp(WidgetTester tester, {String? language = 'ar'}) async {
  // شاشة طويلة عشان كل الخانات تتبني من غير سكرول
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'language': ?language});
  await AppSettings.instance.load();
  SystemBridge.init();
  await tester.pumpWidget(const ShenApp());
  await Session.instance.start();
  await tester.pumpAndSettle();
}

AppLocalizations l10n(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(Scaffold).first));

void main() {
  setUp(() {
    core = FakeCore()..install();
  });

  testWidgets('first run: create the vault and land on an empty key list (Arabic, RTL)', (tester) async {
    await startApp(tester);
    final l = l10n(tester);
    expect(find.text(l.setupTitle), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(l.setupTitle))), TextDirection.rtl);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'master password 1');
    await tester.enterText(fields.at(2), 'master password 2');
    await tester.ensureVisible(find.text(l.createVault));
    await tester.tap(find.text(l.createVault));
    await tester.pumpAndSettle();
    expect(find.text(l.passwordsDontMatch), findsOneWidget);
    expect(core.exists, isFalse);

    await tester.enterText(fields.at(2), 'master password 1');
    await tester.ensureVisible(find.text(l.createVault));
    await tester.tap(find.text(l.createVault));
    await tester.pumpAndSettle();
    expect(core.exists, isTrue);
    expect(find.text(l.noKeysTitle), findsOneWidget);
    expect(find.text(l.defaultProfileName), findsWidgets);
  });

  testWidgets('lock screen rejects a wrong password and opens with the right one', (tester) async {
    core
      ..exists = true
      ..password = 'master password 1';
    core.profiles.add({'id': 'p0', 'name': 'Work', 'color': 2, 'hasPassword': false, 'open': true});
    core.active = 'p0';
    await startApp(tester, language: 'en');
    final l = l10n(tester);
    expect(find.text(l.locked), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(l.locked))), TextDirection.ltr);

    await tester.enterText(find.byType(TextField), 'nope nope');
    await tester.tap(find.text(l.unlock));
    await tester.pumpAndSettle();
    expect(find.text(l.errWrongPassword), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'master password 1');
    await tester.tap(find.text(l.unlock));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsWidgets);

    // قفل يدوي يرجّع لشاشة القفل
    await tester.tap(find.byTooltip(l.lockNow));
    await tester.pumpAndSettle();
    expect(find.text(l.locked), findsOneWidget);
    expect(core.calls, contains('lock'));
  });

  testWidgets('new key screen validates and creates the key', (tester) async {
    core
      ..exists = true
      ..unlocked = true;
    core.profiles.add({'id': 'p0', 'name': 'Personal', 'color': 0, 'hasPassword': false, 'open': true});
    core.active = 'p0';
    await startApp(tester, language: 'en');
    final l = l10n(tester);
    await tester.tap(find.text(l.newKey));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(l.createKey));
    await tester.tap(find.text(l.createKey));
    await tester.pumpAndSettle();
    expect(find.text(l.nameOrEmailRequired), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Alice');
    await tester.enterText(fields.at(1), 'not an email');
    await tester.ensureVisible(find.text(l.createKey));
    await tester.tap(find.text(l.createKey));
    await tester.pumpAndSettle();
    expect(find.text(l.invalidEmail), findsOneWidget);

    await tester.enterText(fields.at(1), 'alice@example.org');
    await tester.enterText(fields.at(3), 'key passphrase');
    await tester.enterText(fields.at(4), 'key passphrase');
    await tester.ensureVisible(find.text(l.createKey));
    await tester.tap(find.text(l.createKey));
    await tester.pumpAndSettle();
    expect(core.calls, contains('generateKey'));
    expect(find.text(l.keyCreatedTitle), findsOneWidget);
    await tester.tap(find.text(l.ok));
    await tester.pumpAndSettle();
    expect(find.text(l.sharePublicKey), findsOneWidget);
  });

  testWidgets('contacts show where they are visible and if they are verified', (tester) async {
    core
      ..exists = true
      ..unlocked = true;
    core.profiles.add({'id': 'p0', 'name': 'Personal', 'color': 0, 'hasPassword': false, 'open': true});
    core.active = 'p0';
    core.contacts['p0'] = [FakeCore.key('Bob', secret: false, n: 2)];
    core.shared.add(FakeCore.key('Carol', secret: false, scope: 'shared', verified: true, n: 3));
    await startApp(tester, language: 'en');
    final l = l10n(tester);
    await tester.tap(find.text(l.contacts));
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);
    expect(find.text(l.allProfiles), findsOneWidget);
    expect(find.text(l.verified), findsOneWidget);
  });

  testWidgets('every tool screen opens in both languages', (tester) async {
    for (final lang in ['ar', 'en']) {
      core = FakeCore()..install();
      core
        ..exists = true
        ..unlocked = true;
      core.profiles.add({'id': 'p0', 'name': 'P', 'color': 0, 'hasPassword': false, 'open': true});
      core.active = 'p0';
      core.keys['p0'] = [FakeCore.key('Me')];
      await startApp(tester, language: lang);
      final l = l10n(tester);
      await tester.tap(find.text(l.tools));
      await tester.pumpAndSettle();
      for (final t in [l.encryptText, l.decryptVerify, l.signText, l.encryptFile, l.decryptFile, l.signFile, l.verifyFile]) {
        await tester.ensureVisible(find.text(t).first);
        await tester.tap(find.text(t).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$lang $t');
        rootNavigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(l.settings));
      await tester.pumpAndSettle();
      expect(find.text(l.security), findsOneWidget);
    }
  });

  testWidgets('encrypting text goes to the output screen', (tester) async {
    core
      ..exists = true
      ..unlocked = true;
    core.profiles.add({'id': 'p0', 'name': 'P', 'color': 0, 'hasPassword': false, 'open': true});
    core.active = 'p0';
    core.keys['p0'] = [FakeCore.key('Me')];
    await startApp(tester, language: 'en');
    final l = l10n(tester);
    await tester.tap(find.text(l.tools));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.encryptText));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'hello');
    await tester.ensureVisible(find.text(l.encrypt).last);
    await tester.tap(find.text(l.encrypt).last);
    await tester.pumpAndSettle();
    expect(core.calls, contains('encryptText'));
    expect(find.text(l.encryptedMessage), findsOneWidget);
    expect(find.textContaining('BEGIN PGP MESSAGE'), findsOneWidget);
  });
}
