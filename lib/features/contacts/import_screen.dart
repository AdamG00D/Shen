import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core_api.dart';
import '../../core/errors.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/system.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fingerprint.dart';
import '../../widgets/key_tile.dart';
import '../../widgets/prompts.dart';
import '../../widgets/ui.dart';
import 'contact_details_screen.dart';

/// منين نستورد مفتاح: لصق، ملف، QR.
Future<void> showImportSources(BuildContext context) async {
  final l = context.l10n;
  final src = await showActionSheet<String>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(l.importKey),
        ListTile(leading: const Icon(Icons.content_paste_rounded), title: Text(l.fromClipboard), onTap: () => Navigator.pop(ctx, 'clip')),
        ListTile(leading: const Icon(Icons.edit_note_rounded), title: Text(l.pasteText), onTap: () => Navigator.pop(ctx, 'text')),
        ListTile(leading: const Icon(Icons.folder_open_rounded), title: Text(l.fromFile), onTap: () => Navigator.pop(ctx, 'file')),
        ListTile(
          leading: const Icon(Icons.qr_code_scanner_rounded),
          title: Text(l.scanQr),
          subtitle: Text(l.scanQrHelp),
          onTap: () => Navigator.pop(ctx, 'qr'),
        ),
      ],
    ),
  );
  if (src == null || !context.mounted) return;
  switch (src) {
    case 'clip':
      final d = await Clipboard.getData(Clipboard.kTextPlain);
      final t = d?.text ?? '';
      if (!context.mounted) return;
      if (t.trim().isEmpty) return showToast(context, l.clipboardEmpty, error: true);
      await openImport(context, Uint8List.fromList(utf8.encode(t)));
    case 'text':
      final t = await askText(context, title: l.pasteText, label: l.pasteKeyHere, maxLength: 200000, maxLines: 8);
      if (t == null || t.isEmpty || !context.mounted) return;
      await openImport(context, Uint8List.fromList(utf8.encode(t)));
    case 'file':
      final f = await SystemBridge.pickOpen();
      if (f == null || !context.mounted) return;
      final bytes = await busy(context, () async => (await SystemBridge.readUri(f.uri))!);
      if (bytes == null || !context.mounted) return;
      await openImport(context, bytes);
    case 'qr':
      await scanAndHandle(context);
  }
}

/// مسح QR: مفتاح عام كامل ← استيراد، بصمة ← مقارنة بجهة الاتصال.
Future<void> scanAndHandle(BuildContext context) async {
  final l = context.l10n;
  final text = await SystemBridge.scanQr();
  if (text == null || text.isEmpty || !context.mounted) return;
  if (text.contains('-----BEGIN PGP PUBLIC KEY BLOCK-----')) {
    await openImport(context, Uint8List.fromList(utf8.encode(text)), fromQr: true);
    return;
  }
  final fp = parseFingerprintQr(text);
  if (fp == null) return showToast(context, l.qrNotKey, error: true);
  final m = await busy(context, () => Core.findFingerprint(Session.instance.active!.id, fp));
  if (!context.mounted) return;
  if (m == null) {
    await infoDialog(context, title: l.fingerprintUnknownTitle, message: l.fingerprintUnknownBody(formatFingerprint(fp)), icon: Icons.help_outline_rounded);
    return;
  }
  if (m.kind == 'key') return showToast(context, l.thisIsYourKey);
  // بصمة جهة اتصال: المسح نفسه هو التحقق (الـ QR جاي من موبايل الشخص قدامك)
  await busy(context, () async {
    await Core.setContactVerified(Session.instance.active!.id, fp, true);
    await Session.instance.refresh();
  });
  if (!context.mounted) return;
  await infoDialog(context, title: l.verifiedTitle, message: l.verifiedByQr, icon: Icons.verified_rounded);
  if (!context.mounted) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailsScreen(fp: fp)));
}

Future<void> openImport(BuildContext context, Uint8List data, {bool fromQr = false}) async {
  final preview = await busy(context, () => Core.previewImport(Session.instance.active!.id, data));
  if (preview == null || !context.mounted) return;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => ImportScreen(data: data, preview: preview, fromQr: fromQr)));
}

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key, required this.data, required this.preview, this.fromQr = false});

  final Uint8List data;
  final List<KeyInfo> preview;

  /// المفتاح جه من QR من موبايل الشخص نفسه — نعلّمه "متأكد منه".
  final bool fromQr;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late final Set<String> _sel = widget.preview.map((k) => k.fp).toSet();
  bool _shared = false;
  bool _busy = false;

  bool get _hasPublic => widget.preview.any((k) => !k.secret && _sel.contains(k.fp));
  bool get _hasSecret => widget.preview.any((k) => k.secret && _sel.contains(k.fp));

  Future<void> _import() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final profile = Session.instance.active!.id;
      final r = await Core.importKeys(profile, widget.data, _shared ? 'shared' : 'profile', _sel.toList());
      if (widget.fromQr) {
        for (final k in widget.preview.where((k) => !k.secret && _sel.contains(k.fp))) {
          await Core.setContactVerified(profile, k.fp, true);
        }
      }
      await Session.instance.refresh();
      if (!mounted) return;
      showToast(context, l.importDone(r.added, r.updated));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showToast(context, errorText(l, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    return AppScaffold(
      title: l.importKeysTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(l.importFound(widget.preview.length), style: TextStyle(color: p.textMuted)),
          const SizedBox(height: 12),
          for (final k in widget.preview) ...[
            KeyTile(k: k, selected: _sel.contains(k.fp), onTap: () => setState(() => _sel.contains(k.fp) ? _sel.remove(k.fp) : _sel.add(k.fp))),
            if (k.existing != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 14, top: 4),
                child: Text(l.alreadyHaveUpdate, style: TextStyle(color: p.textMuted, fontSize: 12.5)),
              ),
            const SizedBox(height: 10),
          ],
          if (_hasSecret)
            AppCard(
              color: p.accentSoft,
              child: Row(
                children: [
                  Icon(Icons.vpn_key_rounded, color: p.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l.secretGoesToMyKeys, style: const TextStyle(height: 1.5))),
                ],
              ),
            ),
          if (_hasPublic) ...[
            SectionLabel(l.whereToShow),
            AppCard(
              padding: EdgeInsets.zero,
              child: RadioGroup<bool>(
                groupValue: _shared,
                onChanged: (v) => setState(() => _shared = v ?? false),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      value: false,
                      title: Text(l.thisProfileOnly(Session.instance.active!.name)),
                      subtitle: Text(l.thisProfileOnlyHelp),
                    ),
                    RadioListTile<bool>(value: true, title: Text(l.allProfiles), subtitle: Text(l.allProfilesHelp)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(widget.fromQr ? l.importQrVerified : l.verifyAfterImport, style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.5)),
          ],
          const SizedBox(height: 18),
          PrimaryButton(label: l.import, icon: Icons.download_done_rounded, loading: _busy, onPressed: _sel.isEmpty ? null : _import),
        ],
      ),
    );
  }
}
