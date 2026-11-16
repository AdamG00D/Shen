import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fingerprint.dart';
import '../../widgets/key_picker.dart';
import '../../widgets/prompts.dart';
import '../../widgets/ui.dart';
import '../keys/key_details_screen.dart';
import 'import_screen.dart';

class ContactDetailsScreen extends StatelessWidget {
  const ContactDetailsScreen({super.key, required this.fp});

  final String fp;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final k = Session.instance.contacts.where((e) => e.fp == fp).firstOrNull;
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

  Future<void> _set(BuildContext context, Future<void> Function() f, {String? done}) =>
      busy(context, () async {
        await f();
        await Session.instance.refresh();
      }, done: done);

  Future<void> _compare(BuildContext context) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.compareTitle,
      message: l.compareBody(formatFingerprint(k.fp)),
      confirm: l.theyMatch,
      icon: Icons.compare_arrows_rounded,
    );
    if (ok && context.mounted) await _set(context, () => Core.setContactVerified(_profile, k.fp, true), done: l.markedVerified);
  }

  Future<void> _certify(BuildContext context) async {
    final l = context.l10n;
    if (Session.instance.signingKeys.isEmpty) return showToast(context, l.needOwnKey, error: true);
    final ok = await confirmDialog(context, title: l.certifyTitle, message: l.certifyBody, confirm: l.certify, icon: Icons.approval_rounded);
    if (!ok || !context.mounted) return;
    final me = Session.instance.signingKeys.length == 1
        ? Session.instance.signingKeys.first
        : await pickSigningKey(context, current: Session.instance.defaultKey?.fp);
    if (me == null || !context.mounted) return;
    await _set(context, () async {
      final pass = await keyPassphrase(context, me);
      await Core.certifyContact(_profile, k.fp, me.fp, pass);
    }, done: l.certified);
  }

  Future<void> _delete(BuildContext context) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.deleteContactTitle,
      message: k.shared ? l.deleteContactSharedBody : l.deleteContactBody,
      confirm: l.delete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final nav = Navigator.of(context);
    await _set(context, () => Core.deleteContact(_profile, k.fp), done: l.deleted);
    nav.pop();
  }

  Future<void> _note(BuildContext context) async {
    final l = context.l10n;
    final n = await askText(context, title: l.note, label: l.note, initial: k.note, maxLength: 300, maxLines: 3);
    if (n == null || !context.mounted) return;
    await _set(context, () => Core.setNote(_profile, k.fp, n));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    return AppScaffold(
      title: l.contact,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          KeyHeader(k: k),
          const SizedBox(height: 18),
          FingerprintView(fp: k.fp),
          const SizedBox(height: 12),
          AppCard(
            color: (k.verified ? p.success : p.warning).withValues(alpha: p.isDark ? 0.14 : 0.08),
            borderColor: (k.verified ? p.success : p.warning).withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(k.verified ? Icons.verified_rounded : Icons.gpp_maybe_rounded, color: k.verified ? p.success : p.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(k.verified ? l.contactVerified : l.contactNotVerified,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(k.verified ? l.contactVerifiedBody : l.contactNotVerifiedBody, style: const TextStyle(height: 1.5, fontSize: 13.5)),
                const SizedBox(height: 12),
                if (!k.verified) ...[
                  SecondaryButton(label: l.scanTheirQr, icon: Icons.qr_code_scanner_rounded, onPressed: () => scanAndHandle(context)),
                  const SizedBox(height: 8),
                  SecondaryButton(label: l.compareManually, icon: Icons.compare_arrows_rounded, onPressed: () => _compare(context)),
                  const SizedBox(height: 8),
                ],
                if (k.usable)
                  SecondaryButton(label: l.certifyWithMyKey, icon: Icons.approval_rounded, onPressed: () => _certify(context)),
                if (k.verified) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _set(context, () => Core.setContactVerified(_profile, k.fp, false)),
                    child: Text(l.unmarkVerified),
                  ),
                ],
              ],
            ),
          ),
          SectionLabel(l.whereToShow),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              value: k.shared,
              secondary: const Icon(Icons.public_rounded),
              title: Text(l.showInAllProfiles),
              subtitle: Text(k.shared ? l.allProfilesHelp : l.thisProfileOnlyHelp),
              onChanged: (v) => _set(context, () => Core.setContactScope(_profile, k.fp, v ? 'shared' : 'profile')),
            ),
          ),
          const SizedBox(height: 14),
          SecondaryButton(label: l.sharePublicKey, icon: Icons.ios_share_rounded, onPressed: () => sharePublicKey(context, k)),
          KeyInfoRows(k: k),
          SectionLabel(l.manage),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingTile(icon: Icons.sticky_note_2_rounded, title: l.note, subtitle: k.note.isEmpty ? null : k.note, onTap: () => _note(context)),
                SettingTile(
                  icon: Icons.update_rounded,
                  title: l.updateKey,
                  subtitle: l.updateKeyHelp,
                  onTap: () => showImportSources(context),
                ),
                SettingTile(icon: Icons.delete_rounded, title: l.deleteContact, color: p.danger, onTap: () => _delete(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
