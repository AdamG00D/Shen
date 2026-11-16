import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/system.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/prompts.dart';
import '../contacts/import_screen.dart';
import 'file_screen.dart';
import 'text_screens.dart';

/// حاجة جاية من تطبيق تاني (Share → شِن، أو "افتح بـ"): بنشوف هي إيه ونفتح الشاشة المناسبة.
Future<void> handleIncoming(BuildContext context, Incoming inc) async {
  final s = Session.instance;
  final profile = s.active;
  if (profile == null || !profile.open) {
    showToast(context, context.l10n.errProfileLocked, error: true);
    return;
  }
  void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  if (inc.text != null) {
    final t = inc.text!;
    if (t.contains('-----BEGIN PGP')) {
      go(DecryptTextScreen(initial: t));
    } else {
      go(EncryptTextScreen(initial: t));
    }
    return;
  }
  final f = inc.file!;
  // الملفات الصغيرة: نشوف لو فيها مفاتيح
  if ((f.size ?? 0) <= 8 * 1024 * 1024) {
    Uint8List? bytes;
    Inspection? ins;
    try {
      bytes = await SystemBridge.readUri(f.uri);
      if (bytes != null) ins = await Core.inspect(profile.id, bytes);
    } catch (_) {}
    if (bytes != null && ins != null && context.mounted) {
      if (ins.kind == 'keys' || (ins.kind == 'unknown' && await _looksLikeKeys(profile.id, bytes))) {
        if (context.mounted) await openImport(context, bytes);
        return;
      }
      if (!context.mounted) return;
      return switch (ins.kind) {
        'signature' || 'signed' => go(FileScreen(mode: FileMode.verify, input: f)),
        'encrypted' => go(FileScreen(mode: FileMode.decrypt, input: f)),
        'clearsigned' => go(DecryptTextScreen(initial: utf8.decode(bytes, allowMalformed: true))),
        _ => go(FileScreen(mode: FileMode.encrypt, input: f)),
      };
    }
  }
  if (!context.mounted) return;
  final ins = await busy(context, () => Core.inspectFile(profile.id, f.uri));
  if (!context.mounted) return;
  go(FileScreen(mode: ins?.kind == 'encrypted' ? FileMode.decrypt : FileMode.encrypt, input: f));
}

Future<bool> _looksLikeKeys(String profile, Uint8List bytes) async {
  try {
    final r = await Core.previewImport(profile, bytes);
    return r.isNotEmpty;
  } catch (_) {
    return false;
  }
}
