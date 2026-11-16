import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/system.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fingerprint.dart';
import '../../widgets/key_tile.dart';
import '../../widgets/output_view.dart';
import '../../widgets/prompts.dart';
import '../../widgets/ui.dart';

/// اسم ملف آمن من اسم المفتاح.
String safeFileName(KeyInfo k, String suffix) {
  final base = (k.name.isNotEmpty ? k.name : (k.email ?? k.keyId)).replaceAll(RegExp(r'[^\w؀-ۿ@.-]+'), '_');
  return '${base.isEmpty ? k.keyId : base}_${k.keyId.substring(k.keyId.length - 8)}$suffix';
}

/// مشاركة المفتاح العام (نسخ / مشاركة / حفظ / QR).
Future<void> sharePublicKey(BuildContext context, KeyInfo k) async {
  final profile = Session.instance.active!.id;
  final armored = await busy(context, () => Core.exportPublic(profile, [k.fp]));
  if (armored == null || !context.mounted) return;
  final l = context.l10n;
  await showActionSheet<void>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionLabel(l.sharePublicKey),
        ListTile(
          leading: const Icon(Icons.share_rounded),
          title: Text(l.share),
          onTap: () {
            Navigator.pop(ctx);
            SystemBridge.shareText(armored, l.sharePublicKey);
          },
        ),
        ListTile(
          leading: const Icon(Icons.copy_rounded),
          title: Text(l.copy),
          onTap: () {
            Navigator.pop(ctx);
            copySecure(context, armored, sensitive: false);
          },
        ),
        ListTile(
          leading: const Icon(Icons.save_alt_rounded),
          title: Text(l.saveFile),
          onTap: () {
            Navigator.pop(ctx);
            saveTextFile(context, armored, safeFileName(k, '.asc'), mime: 'application/pgp-keys');
          },
        ),
        if (armored.length <= 2200)
          ListTile(
            leading: const Icon(Icons.qr_code_2_rounded),
            title: Text(l.showAsQr),
            subtitle: Text(l.showAsQrHelp),
            onTap: () {
              Navigator.pop(ctx);
              showQrDialog(context, title: k.label, data: armored, caption: l.qrKeyCaption);
            },
          ),
      ],
    ),
  );
}

class KeyDetailsScreen extends StatelessWidget {
  const KeyDetailsScreen({super.key, required this.fp});

  final String fp;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final k = Session.instance.keys.where((e) => e.fp == fp).firstOrNull;
        if (k == null) return const AppScaffold(body: SizedBox());
        return _Details(k: k);
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.k});

  final KeyInfo k;

  String get _profile => Session.instance.active!.id;

  Future<void> _refresh() => Session.instance.refresh();

  Future<void> _setDefault(BuildContext context) =>
      busy(context, () async {
        await Core.setDefaultKey(_profile, k.fp);
        await _refresh();
      }, done: context.l10n.saved);

  Future<void> _expiry(BuildContext context) async {
    final l = context.l10n;
    final years = await showActionSheet<int>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionLabel(l.changeExpiry),
          for (final y in [1, 2, 3, 5, 0])
            ListTile(title: Text(y == 0 ? l.never : l.yearsFromNow(y)), onTap: () => Navigator.pop(ctx, y)),
        ],
      ),
    );
    if (years == null || !context.mounted) return;
    final now = DateTime.now();
    await busy(context, () async {
      final pass = await keyPassphrase(context, k);
      await Core.setKeyExpiry(_profile, k.fp, pass, years == 0 ? null : DateTime(now.year + years, now.month, now.day));
      await _refresh();
    }, done: l.updatedShareAgain);
  }

  Future<void> _changePass(BuildContext context) async {
    final l = context.l10n;
    String? old;
    try {
      old = await keyPassphrase(context, k);
    } catch (_) {
      return;
    }
    if (!context.mounted) return;
    final n = await askNewPassword(context, title: l.changeKeyPassphrase, message: l.changeKeyPassphraseBody);
    if (n == null || !context.mounted) return;
    await busy(context, () async {
      await Core.changeKeyPassphrase(_profile, k.fp, old, n);
      await _refresh();
    }, done: l.passphraseChanged);
  }

  Future<void> _addUid(BuildContext context) async {
    final l = context.l10n;
    final uid = await askText(context, title: l.addIdentity, label: l.identityHint, maxLength: 200);
    if (uid == null || uid.isEmpty || !context.mounted) return;
    await busy(context, () async {
      final pass = await keyPassphrase(context, k);
      await Core.addUserId(_profile, k.fp, pass, uid);
      await _refresh();
    }, done: l.updatedShareAgain);
  }

  Future<void> _exportSecret(BuildContext context) async {
    final l = context.l10n;
    if (!await warnDialog(context, title: l.exportSecretTitle, message: l.exportSecretBody, confirm: l.export)) return;
    if (!context.mounted) return;
    final armored = await busy(context, () async {
      final pw = await masterPassword(context, l.masterPasswordForExport);
      return Core.exportSecret(_profile, k.fp, pw);
    });
    if (armored == null || !context.mounted) return;
    await saveTextFile(context, armored, safeFileName(k, '_SECRET.asc'), mime: 'application/pgp-keys');
  }

  Future<void> _revocationCert(BuildContext context) async {
    final l = context.l10n;
    await infoDialog(context, title: l.revocationCert, message: l.revocationCertBody, icon: Icons.shield_rounded);
    if (!context.mounted) return;
    final armored = await busy(context, () async {
      final pw = await masterPassword(context, l.masterPasswordForExport);
      return Core.revocationCert(_profile, k.fp, pw);
    });
    if (armored == null || !context.mounted) return;
    await saveTextFile(context, armored, safeFileName(k, '_REVOCATION.asc'), mime: 'application/pgp-keys');
  }

  Future<void> _revoke(BuildContext context) async {
    final l = context.l10n;
    if (!await warnDialog(context, title: l.revokeTitle, message: l.revokeBody, confirm: l.revoke)) return;
    if (!context.mounted) return;
    final reason = await showActionSheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionLabel(l.revokeReason),
          ListTile(title: Text(l.reasonCompromised), onTap: () => Navigator.pop(ctx, 'compromised')),
          ListTile(title: Text(l.reasonSuperseded), onTap: () => Navigator.pop(ctx, 'superseded')),
          ListTile(title: Text(l.reasonRetired), onTap: () => Navigator.pop(ctx, 'retired')),
          ListTile(title: Text(l.reasonNone), onTap: () => Navigator.pop(ctx, 'none')),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    await busy(context, () async {
      final pass = await keyPassphrase(context, k);
      await Core.revokeKey(_profile, k.fp, pass, reason, '');
      await _refresh();
    }, done: l.revokedShareNow);
  }

  Future<void> _delete(BuildContext context) async {
    final l = context.l10n;
    if (!await warnDialog(context, title: l.deleteKeyTitle, message: l.deleteKeyBody, confirm: l.delete)) return;
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    final ok = await busy(context, () async {
      final pw = await masterPassword(context, l.masterPasswordForDelete);
      await Core.deleteKey(_profile, k.fp, pw);
      await _refresh();
      return true;
    }, done: l.deleted);
    if (ok == true) nav.pop();
  }

  Future<void> _note(BuildContext context) async {
    final l = context.l10n;
    final n = await askText(context, title: l.note, label: l.note, initial: k.note, maxLength: 300, maxLines: 3);
    if (n == null || !context.mounted) return;
    await busy(context, () async {
      await Core.setNote(_profile, k.fp, n);
      await _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final chips = keyChips(context, k);
    return AppScaffold(
      title: l.keyDetails,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          KeyHeader(k: k),
          if (chips.isNotEmpty) ...[const SizedBox(height: 10), Wrap(spacing: 6, runSpacing: 6, children: chips)],
          if (k.revoked) ...[
            const SizedBox(height: 12),
            _Notice(color: p.danger, text: l.keyRevokedNotice),
          ] else if (k.expired) ...[
            const SizedBox(height: 12),
            _Notice(color: p.danger, text: l.keyExpiredNotice),
          ],
          SectionLabel(l.fingerprint),
          FingerprintView(
            fp: k.fp,
            onQr: () => showQrDialog(context, title: l.fingerprint, data: fingerprintQr(k.fp), caption: l.qrFingerprintCaption),
          ),
          const SizedBox(height: 14),
          PrimaryButton(label: l.sharePublicKey, icon: Icons.ios_share_rounded, onPressed: () => sharePublicKey(context, k)),
          KeyInfoRows(k: k),
          SectionLabel(l.manage),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (!k.isDefault && k.usable)
                  SettingTile(icon: Icons.star_rounded, title: l.makeDefault, subtitle: l.makeDefaultHelp, onTap: () => _setDefault(context)),
                if (!k.revoked) ...[
                  SettingTile(icon: Icons.event_rounded, title: l.changeExpiry, onTap: () => _expiry(context)),
                  SettingTile(icon: Icons.password_rounded, title: l.changeKeyPassphrase, onTap: () => _changePass(context)),
                  SettingTile(icon: Icons.person_add_alt_rounded, title: l.addIdentity, onTap: () => _addUid(context)),
                ],
                SettingTile(icon: Icons.sticky_note_2_rounded, title: l.note, subtitle: k.note.isEmpty ? null : k.note, onTap: () => _note(context)),
              ],
            ),
          ),
          SectionLabel(l.backupAndSafety),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingTile(icon: Icons.key_rounded, title: l.exportSecret, subtitle: l.exportSecretHelp, onTap: () => _exportSecret(context)),
                if (k.hasRevocation)
                  SettingTile(icon: Icons.shield_rounded, title: l.revocationCert, subtitle: l.revocationCertHelp, onTap: () => _revocationCert(context)),
                if (!k.revoked)
                  SettingTile(icon: Icons.block_rounded, title: l.revoke, subtitle: l.revokeHelp, color: p.danger, onTap: () => _revoke(context)),
                SettingTile(icon: Icons.delete_forever_rounded, title: l.deleteKey, color: p.danger, onTap: () => _delete(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      color: color.withValues(alpha: p.isDark ? 0.14 : 0.08),
      borderColor: color.withValues(alpha: 0.4),
      child: Text(text, style: const TextStyle(height: 1.5)),
    );
  }
}

/// الاسم والإيميل فوق.
class KeyHeader extends StatelessWidget {
  const KeyHeader({super.key, required this.k});

  final KeyInfo k;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        IconBadge(icon: k.secret ? Icons.vpn_key_rounded : Icons.person_rounded, size: 56, color: k.usable ? p.accent : p.textMuted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              if (k.email != null && k.name.isNotEmpty)
                Text(k.email!, textDirection: TextDirection.ltr, style: TextStyle(color: p.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

/// تفاصيل تقنية: النوع، التواريخ، الهويات، المفاتيح الفرعية.
class KeyInfoRows extends StatelessWidget {
  const KeyInfoRows({super.key, required this.k});

  final KeyInfo k;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    Widget row(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, child: Text(a, style: TextStyle(color: p.textMuted))),
              Expanded(child: Text(b, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        );
    String flags(List<String> f) => [
          if (f.contains('CERTIFY_OTHER')) l.flagCertify,
          if (f.contains('SIGN_DATA')) l.flagSign,
          if (f.contains('ENCRYPT_COMMS') || f.contains('ENCRYPT_STORAGE')) l.flagEncrypt,
          if (f.contains('AUTHENTICATION')) l.flagAuth,
        ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l.details),
        AppCard(
          child: Column(
            children: [
              row(l.algorithm, k.algo),
              row(l.created, formatDate(context, k.created)),
              row(l.expires, k.expires == null ? l.never : formatDate(context, k.expires!)),
              row(l.keyIdLabel, k.keyId),
              row(l.version, 'v${k.version}'),
            ],
          ),
        ),
        if (k.uids.length > 1) ...[
          SectionLabel(l.identities),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final u in k.uids)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(u, style: const TextStyle(height: 1.4))),
              ],
            ),
          ),
        ],
        SectionLabel(l.subkeys),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in k.subkeys)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s.algo} — ${flags(s.flags)}', style: TextStyle(fontWeight: FontWeight.w600, color: s.valid ? p.text : p.textMuted)),
                      Text(
                        '${formatDate(context, s.created)} → ${s.expires == null ? l.never : formatDate(context, s.expires!)}'
                        '${s.valid ? '' : ' · ${l.invalid}'}',
                        style: TextStyle(color: p.textMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// يحوّل نص لبايتات (UTF-8).
Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));
