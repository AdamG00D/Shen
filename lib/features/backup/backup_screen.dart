import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/errors.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/system.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/key_tile.dart';
import '../../widgets/prompts.dart';
import '../../widgets/ui.dart';

/// النسخ الاحتياطي: ملف `.shen` متشفّر كرسالة OpenPGP بكلمة سر (Argon2 + AES-256-OCB).
/// المفاتيح السرية جواه لسه متشفّرة بكلمات سرها كمان.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _export(BuildContext context, {required bool all}) async {
    final l = context.l10n;
    final s = Session.instance;
    final pw = await askNewPassword(context, title: l.backupPassword, message: l.backupPasswordHelp);
    if (pw == null || !context.mounted) return;
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final who = all ? 'all' : s.active!.name.replaceAll(RegExp(r'[^\w؀-ۿ-]+'), '_');
    final out = await SystemBridge.pickCreate('shen-backup-$who-$date.shen');
    if (out == null || !context.mounted) return;
    final r = await busy(context, () => Core.exportBackup(all ? null : s.active!.id, pw, out.uri));
    if (r == null || !context.mounted) return;
    await infoDialog(
      context,
      title: l.backupDoneTitle,
      message: [
        l.backupDoneBody(r.profiles, r.keys, r.contacts),
        if (r.skipped.isNotEmpty) l.backupSkipped(r.skipped.join('، ')),
      ].join('\n\n'),
      icon: Icons.check_circle_rounded,
    );
  }

  Future<void> _import(BuildContext context) async {
    final l = context.l10n;
    final f = await SystemBridge.pickOpen();
    if (f == null || !context.mounted) return;
    BackupPreview? preview;
    String? password;
    password = await askSecret(
      context,
      title: l.backupPassword,
      label: l.backupPassword,
      confirmLabel: l.open,
      check: (v) async {
        try {
          preview = await Core.previewBackup(f.uri, v);
          return null;
        } catch (e) {
          return errorText(l, e);
        }
      },
    );
    final pv = preview;
    if (password == null || pv == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.restoreTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pv.created != null) Text(l.backupFrom(formatDate(ctx, pv.created!))),
              const SizedBox(height: 10),
              for (final p in pv.profiles)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${p.name}: ${l.profileCounts(p.keys, p.contacts)}${p.exists ? ' — ${l.willMerge}' : ' — ${l.willCreate}'}'),
                ),
              if (pv.shared > 0) Text('• ${l.sharedContactsCount(pv.shared)}'),
              const SizedBox(height: 10),
              Text(l.restoreNothingDeleted, style: TextStyle(color: ctx.palette.textMuted, fontSize: 13, height: 1.5)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.restore)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final r = await busy(context, () async {
      final r = await Core.importBackup(f.uri, password!);
      await Session.instance.refresh();
      return r;
    });
    if (r != null && context.mounted) showToast(context, l.importDone(r.added, r.updated));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final active = Session.instance.active;
    return AppScaffold(
      title: l.backup,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          AppCard(
            color: p.surfaceAlt,
            child: Text(l.backupIntro, style: const TextStyle(height: 1.6)),
          ),
          SectionLabel(l.exportSection),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingTile(
                  icon: Icons.inventory_2_rounded,
                  title: l.backupEverything,
                  subtitle: l.backupEverythingHelp,
                  onTap: () => _export(context, all: true),
                ),
                if (active != null && active.open)
                  SettingTile(
                    icon: Icons.folder_rounded,
                    title: l.backupThisProfile(active.name),
                    subtitle: l.backupThisProfileHelp,
                    onTap: () => _export(context, all: false),
                  ),
              ],
            ),
          ),
          SectionLabel(l.importSection),
          AppCard(
            padding: EdgeInsets.zero,
            child: SettingTile(icon: Icons.restore_rounded, title: l.restoreBackup, subtitle: l.restoreBackupHelp, onTap: () => _import(context)),
          ),
          const SizedBox(height: 16),
          Text(l.backupFormatNote, style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.6)),
        ],
      ),
    );
  }
}
