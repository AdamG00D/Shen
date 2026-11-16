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
  int _tab = Session.instance.lastTab;
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
            titleSpacing: 16,
            toolbarHeight: 64,
            title: active == null ? Text(l.appName) : _ProfileChip(profile: active),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: IconButton.outlined(
                  tooltip: l.lockNow,
                  style: IconButton.styleFrom(side: BorderSide(color: context.palette.border)),
                  icon: const Icon(Icons.lock_outline_rounded, size: 21),
                  onPressed: s.lock,
                ),
              ),
            ],
          ),
          body: !open && _tab != 3
              ? _ProfileLocked(profile: active)
              : IndexedStack(
                  index: _tab,
                  children: const [KeysTab(), ContactsTab(), ToolsTab(), SettingsTab()],
                ),
          bottomNavigationBar: _ShenNavBar(
            selected: _tab,
            onSelect: (i) => setState(() => _tab = Session.instance.lastTab = i),
            items: [
              (Icons.vpn_key_outlined, l.myKeys),
              (Icons.people_outline_rounded, l.contacts),
              (Icons.lock_outline_rounded, l.tools),
              (Icons.settings_outlined, l.settings),
            ],
          ),
        );
      },
    );
  }
}

/// زرار البروفايل على شكل خرطوش.
class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Cartouche(
        onTap: () => showProfileSwitcher(context),
        barColor: profileColor(profile.color),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!profile.open) ...[Icon(Icons.lock_rounded, size: 16, color: p.textMuted), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                profile.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, color: p.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// شريط التنقل: من غير كبسولة ملوّنة — التاب المختار عليه خط نحاسي فوقه.
class _ShenNavBar extends StatelessWidget {
  const _ShenNavBar({required this.selected, required this.onSelect, required this.items});

  final int selected;
  final ValueChanged<int> onSelect;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.border))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == selected,
                    button: true,
                    child: InkWell(
                      onTap: () => onSelect(i),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 3,
                            width: i == selected ? 36 : 0,
                            decoration: BoxDecoration(
                              color: p.accent,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                            ),
                          ),
                          const Spacer(),
                          Icon(items[i].$1, size: 23, color: i == selected ? p.text : p.textMuted),
                          const SizedBox(height: 4),
                          Text(
                            items[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                              color: i == selected ? p.text : p.textMuted,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
              trailing: pr.active ? Icon(Icons.check_rounded, color: p.text) : null,
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
