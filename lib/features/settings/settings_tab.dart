import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/core_api.dart';
import '../../core/errors.dart';
import '../../core/session.dart';
import '../../core/settings.dart';
import '../../core/system.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fingerprint.dart';
import '../../widgets/prompts.dart';
import '../../widgets/ui.dart';
import '../backup/backup_screen.dart';
import '../profiles/profiles_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    Core.bioAvailable().then((v) {
      if (mounted) setState(() => _bioAvailable = v);
    }).catchError((_) {});
  }

  AppSettings get _s => AppSettings.instance;

  String _lockLabel(AppLocalizations l, int s) => s == 0 ? l.immediately : (s < 60 ? l.seconds(s) : l.minutes(s ~/ 60));

  Future<T?> _choose<T>(String title, List<T> values, String Function(T) label, T current) => showActionSheet<T>(
        context,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionLabel(title),
            for (final v in values)
              ListTile(
                title: Text(label(v)),
                trailing: v == current ? Icon(Icons.check_rounded, color: ctx.palette.text) : null,
                onTap: () => Navigator.pop(ctx, v),
              ),
          ],
        ),
      );

  Future<void> _toggleBio(bool on) async {
    final l = context.l10n;
    try {
      if (on) {
        await Core.bioEnable(l.bioEnableTitle, l.bioSubtitle, l.cancel);
        if (mounted) showToast(context, l.bioEnabled);
      } else {
        await Core.bioDisable();
      }
    } catch (e) {
      if (e is CoreException && e.code == 'CANCELLED') return;
      if (mounted) showToast(context, errorText(l, e), error: true);
    }
    await Session.instance.refreshBio();
    if (mounted) setState(() {});
  }

  Future<void> _changeMaster() async {
    final l = context.l10n;
    String old;
    try {
      old = await masterPassword(context, l.currentMasterPassword);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final n = await askNewPassword(context, title: l.newMasterPassword, message: l.masterPasswordWarning);
    if (n == null || !mounted) return;
    await busy(context, () => Core.changeMasterPassword(old, n), done: l.passwordChanged);
  }

  Future<void> _wipe() async {
    final l = context.l10n;
    if (!await warnDialog(context, title: l.wipeTitle, message: l.wipeBody, confirm: l.wipe)) return;
    if (!mounted) return;
    final ok = await busy(context, () async {
      final pw = await masterPassword(context, l.masterPasswordForWipe);
      await Core.wipeAll(pw);
      return true;
    });
    if (ok == true) Session.instance.wiped();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    return ListenableBuilder(
      listenable: Listenable.merge([_s, Session.instance]),
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          PageTitle(l.settings),
          SectionLabel(l.security),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (_bioAvailable)
                  SettingTile(
                    icon: Icons.fingerprint_rounded,
                    title: l.unlockWithBio,
                    subtitle: l.bioHelp,
                    trailing: Switch(value: Session.instance.bioEnabled, onChanged: _toggleBio),
                  ),
                SettingTile(
                  icon: Icons.timer_rounded,
                  title: l.autoLock,
                  subtitle: l.autoLockValue(_lockLabel(l, _s.autoLockSeconds)),
                  onTap: () async {
                    final v = await _choose(l.autoLock, AppSettings.autoLockChoices, (s) => _lockLabel(l, s), _s.autoLockSeconds);
                    if (v != null) await _s.update(autoLockSeconds: v);
                  },
                ),
                SettingTile(
                  icon: Icons.memory_rounded,
                  title: l.rememberPassphrase,
                  subtitle: _s.passCacheMinutes == 0 ? l.rememberPassphraseOff : l.rememberPassphraseOn(_s.passCacheMinutes),
                  onTap: () async {
                    final v = await _choose(
                      l.rememberPassphrase,
                      AppSettings.passCacheChoices,
                      (m) => m == 0 ? l.dontRemember : l.minutes(m),
                      _s.passCacheMinutes,
                    );
                    if (v == null) return;
                    await _s.update(passCacheMinutes: v);
                    await Core.setPassCache(v);
                  },
                ),
                SettingTile(
                  icon: Icons.content_paste_off_rounded,
                  title: l.clipboardClear,
                  subtitle: l.clipboardClearValue(_s.clipboardSeconds),
                  onTap: () async {
                    final v = await _choose(l.clipboardClear, AppSettings.clipboardChoices, (s) => l.seconds(s), _s.clipboardSeconds);
                    if (v != null) await _s.update(clipboardSeconds: v);
                  },
                ),
                SettingTile(icon: Icons.password_rounded, title: l.changeMasterPassword, onTap: _changeMaster),
              ],
            ),
          ),
          SectionLabel(l.data),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingTile(
                  icon: Icons.folder_shared_rounded,
                  title: l.manageProfiles,
                  subtitle: l.profilesShortHelp,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilesScreen())),
                ),
                SettingTile(
                  icon: Icons.backup_rounded,
                  title: l.backup,
                  subtitle: l.backupShortHelp,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
                ),
              ],
            ),
          ),
          SectionLabel(l.appearance),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingTile(
                  icon: Icons.translate_rounded,
                  title: l.language,
                  subtitle: _s.language == null ? l.followPhone : (_s.language == 'ar' ? 'العربية' : 'English'),
                  onTap: () async {
                    final v = await _choose<String>(
                      l.language,
                      const ['', 'ar', 'en'],
                      (c) => c.isEmpty ? l.followPhone : (c == 'ar' ? 'العربية' : 'English'),
                      _s.language ?? '',
                    );
                    if (v != null) await _s.update(language: () => v.isEmpty ? null : v);
                  },
                ),
                SettingTile(
                  icon: Icons.dark_mode_rounded,
                  title: l.theme,
                  subtitle: switch (_s.themeMode) { ThemeMode.light => l.themeLight, ThemeMode.dark => l.themeDark, _ => l.followPhone },
                  onTap: () async {
                    final v = await _choose<ThemeMode>(
                      l.theme,
                      ThemeMode.values,
                      (m) => switch (m) { ThemeMode.light => l.themeLight, ThemeMode.dark => l.themeDark, _ => l.followPhone },
                      _s.themeMode,
                    );
                    if (v != null) await _s.update(themeMode: v);
                  },
                ),
              ],
            ),
          ),
          SectionLabel(l.about),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingTile(icon: Icons.info_rounded, title: '${l.appName} ${AppConfig.appVersion}', subtitle: l.aboutBody),
                SettingTile(
                  icon: Icons.code_rounded,
                  title: l.sourceCode,
                  subtitle: AppConfig.repoUrl,
                  onTap: () => SystemBridge.openUrl(AppConfig.repoUrl),
                  onLongPress: () => copySecure(context, AppConfig.repoUrl, sensitive: false),
                ),
                SettingTile(
                  icon: Icons.verified_user_rounded,
                  title: l.releaseKey,
                  subtitle: formatFingerprint(AppConfig.releaseKeyFingerprint),
                  onLongPress: () => copySecure(context, AppConfig.releaseKeyFingerprint, sensitive: false),
                ),
                SettingTile(icon: Icons.gavel_rounded, title: l.license, subtitle: 'GPL-3.0-or-later'),
              ],
            ),
          ),
          SectionLabel(l.dangerZone),
          AppCard(
            padding: EdgeInsets.zero,
            child: SettingTile(icon: Icons.delete_forever_rounded, title: l.wipeTitle, subtitle: l.wipeHelp, color: p.danger, onTap: _wipe),
          ),
        ],
      ),
    );
  }
}
