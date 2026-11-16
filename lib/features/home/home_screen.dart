import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/errors.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/system.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/prompts.dart';
import '../../widgets/ui.dart';
import '../contacts/contacts_tab.dart';
import '../keys/keys_tab.dart';
import '../profiles/profiles_screen.dart';
import '../settings/settings_tab.dart';
import '../tools/incoming.dart';
import '../tools/tools_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = SystemBridge.incomingEvents.listen((_) => _checkIncoming());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIncoming());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _checkIncoming() async {
    final inc = await SystemBridge.takeIncoming();
    if (inc == null || !mounted) return;
    await handleIncoming(context, inc);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final s = Session.instance;
        final active = s.active;
        final open = active?.open ?? false;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 12,
            title: active == null ? Text(l.appName) : _ProfileChip(profile: active),
            actions: [
              IconButton(tooltip: l.lockNow, icon: const Icon(Icons.lock_rounded), onPressed: s.lock),
            ],
          ),
          body: !open && _tab != 3
              ? _ProfileLocked(profile: active)
              : IndexedStack(
                  index: _tab,
                  children: const [KeysTab(), ContactsTab(), ToolsTab(), SettingsTab()],
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.vpn_key_outlined), selectedIcon: const Icon(Icons.vpn_key_rounded), label: l.myKeys),
              NavigationDestination(icon: const Icon(Icons.people_outline_rounded), selectedIcon: const Icon(Icons.people_rounded), label: l.contacts),
              NavigationDestination(icon: const Icon(Icons.enhanced_encryption_outlined), selectedIcon: const Icon(Icons.enhanced_encryption_rounded), label: l.tools),
              NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: l.settings),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => showProfileSwitcher(context),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 10, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileDot(name: profile.name, color: profile.color, size: 32, locked: !profile.open),
            const SizedBox(width: 10),
            Flexible(
              child: Text(profile.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.expand_more_rounded, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

/// البروفايل الحالي ليه كلمة سر ولسه مقفول.
class _ProfileLocked extends StatelessWidget {
  const _ProfileLocked({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EmptyState(
      icon: Icons.lock_rounded,
      title: l.profileLockedTitle(profile?.name ?? ''),
      message: l.profileLockedBody,
      action: SizedBox(
        width: 220,
        child: PrimaryButton(
          label: l.unlock,
          icon: Icons.lock_open_rounded,
          onPressed: profile == null ? null : () => openProfile(context, profile!),
        ),
      ),
    );
  }
}

/// يفتح بروفايل (لو ليه كلمة سر بيطلبها) ويخليه الحالي.
Future<void> openProfile(BuildContext context, Profile p) async {
  final l = context.l10n;
  if (!p.open) {
    final ok = await askSecret(
      context,
      title: l.unlockProfile(p.name),
      label: l.profilePassword,
      confirmLabel: l.unlock,
      check: (v) async {
        try {
          await Core.unlockProfile(p.id, v);
          return null;
        } catch (e) {
          return errorText(l, e);
        }
      },
    );
    if (ok == null) return;
  }
  if (!context.mounted) return;
  await busy(context, () => Session.instance.switchProfile(p.id));
}

Future<void> showProfileSwitcher(BuildContext context) {
  return showActionSheet<void>(
    context,
    builder: (ctx) {
      final l = ctx.l10n;
      final p = ctx.palette;
      final s = Session.instance;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(l.profiles),
          for (final pr in s.profiles)
            ListTile(
              leading: ProfileDot(name: pr.name, color: pr.color, locked: !pr.open),
              title: Text(pr.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: pr.open && pr.keys != null
                  ? Text(l.profileCounts(pr.keys!, pr.contacts ?? 0))
                  : Text(l.profileLockedShort, style: TextStyle(color: p.textMuted)),
              trailing: pr.active ? Icon(Icons.check_circle_rounded, color: p.accent) : null,
              onTap: () {
                Navigator.pop(ctx);
                openProfile(context, pr);
              },
            ),
          const Divider(height: 20),
          ListTile(
            leading: const Icon(Icons.manage_accounts_rounded),
            title: Text(l.manageProfiles),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilesScreen()));
            },
          ),
        ],
      );
    },
  );
}

/// رسالة لما مفيش بروفايل مفتوح والعملية محتاجاه.
void needOpenProfile(BuildContext context) => showToast(context, context.l10n.errProfileLocked, error: true);
