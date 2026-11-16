import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String lang) => jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _placeholders(String text) => RegExp(r'\{(\w+)[,}]').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  final ar = _arb('ar');
  final en = _arb('en');

  test('Arabic and English have the same keys', () {
    final a = ar.keys.where((k) => !k.startsWith('@')).toSet();
    final e = en.keys.where((k) => !k.startsWith('@')).toSet();
    expect(a.difference(e), isEmpty, reason: 'missing in English');
    expect(e.difference(a), isEmpty, reason: 'missing in Arabic');
  });

  test('placeholders match in both languages', () {
    for (final k in ar.keys.where((k) => !k.startsWith('@'))) {
      final meta = ar['@$k'] as Map<String, dynamic>?;
      final declared = ((meta?['placeholders'] as Map<String, dynamic>?)?.keys ?? const <String>[]).toSet();
      expect(_placeholders(ar[k] as String).intersection(declared), declared, reason: 'ar $k');
      expect(_placeholders(en[k] as String).intersection(declared), declared, reason: 'en $k');
    }
  });

  test('no empty strings', () {
    for (final m in [ar, en]) {
      for (final e in m.entries.where((e) => !e.key.startsWith('@'))) {
        expect((e.value as String).trim(), isNotEmpty, reason: e.key);
      }
    }
  });
}
