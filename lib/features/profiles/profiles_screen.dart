import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/prompts.dart';
import '../../widgets/ui.dart';
import '../home/home_screen.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final list = Session.instance.profiles;
        return AppScaffold(
          title: l.profiles,
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add_rounded),
            label: Text(l.newProfile),
            onPressed: () => _create(context),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              Text(l.profilesHelp, style: TextStyle(color: context.palette.textMuted, height: 1.6)),
              const SizedBox(height: 12),
              for (final p in list) ...[
                AppCard(
                  onTap: () => _actions(context, p),
                  child: Row(
                    children: [
                      ProfileDot(name: p.name, color: p.color, size: 44, locked: !p.open),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                            Text(
                              [
                                if (p.open && p.keys != null) l.profileCounts(p.keys!, p.contacts ?? 0) else l.profileLockedShort,
                                if (p.hasPassword) l.hasOwnPassword,
                              ].join(' · '),
                              style: TextStyle(color: context.palette.textMuted, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      if (p.active) Chip2(l.current, color: context.palette.accent),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _create(BuildContext context) async {
    final l = context.l10n;
    final r = await showDialog<({String name, int color, bool password})>(context: context, builder: (_) => const _ProfileDialog());
    if (r == null || !context.mounted) return;
    String? pw;
    if (r.password) {
      pw = await askNewPassword(context, title: l.profilePassword, message: l.profilePasswordHelp);
      if (pw == null) return;
    }
    if (!context.mounted) return;
    await busy(context, () async {
      final id = await Core.createProfile(r.name, r.color, pw);
      await Session.instance.switchProfile(id);
    }, done: l.profileCreated);
  }

  Future<void> _actions(BuildContext context, Profile p) async {
    final l = context.l10n;
    final pal = context.palette;
    final a = await showActionSheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionLabel(p.name),
          if (!p.active || !p.open)
            ListTile(leading: const Icon(Icons.login_rounded), title: Text(l.switchTo), onTap: () => Navigator.pop(ctx, 'switch')),
          if (p.open) ...[
            ListTile(leading: const Icon(Icons.edit_rounded), title: Text(l.renameProfile), onTap: () => Navigator.pop(ctx, 'edit')),
            ListTile(
              leading: const Icon(Icons.password_rounded),
              title: Text(p.hasPassword ? l.changeProfilePassword : l.setProfilePassword),
              subtitle: Text(l.profilePasswordHelp),
              onTap: () => Navigator.pop(ctx, 'password'),
            ),
            if (p.hasPassword) ...[
              ListTile(leading: const Icon(Icons.no_encryption_rounded), title: Text(l.removeProfilePassword), onTap: () => Navigator.pop(ctx, 'nopassword')),
              ListTile(leading: const Icon(Icons.lock_rounded), title: Text(l.lockProfileNow), onTap: () => Navigator.pop(ctx, 'lock')),
            ],
          ],
          if (Session.instance.profiles.length > 1)
            ListTile(
              leading: Icon(Icons.delete_forever_rounded, color: pal.danger),
              title: Text(l.deleteProfile, style: TextStyle(color: pal.danger)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
        ],
      ),
    );
    if (a == null || !context.mounted) return;
    final s = Session.instance;
    switch (a) {
      case 'switch':
        await openProfile(context, p);
      case 'edit':
        final r = await showDialog<({String name, int color, bool password})>(
          context: context,
          builder: (_) => _ProfileDialog(name: p.name, color: p.color, editing: true),
        );
        if (r == null || !context.mounted) return;
        await busy(context, () async {
          await Core.updateProfile(p.id, r.name, r.color);
          await s.refresh();
        });
      case 'password':
        final pw = await askNewPassword(context, title: l.profilePassword, message: l.profilePasswordHelp);
        if (pw == null || !context.mounted) return;
        await busy(context, () async {
          await Core.setProfilePassword(p.id, pw);
          await s.refresh();
        }, done: l.saved);
      case 'nopassword':
        await busy(context, () async {
          await Core.setProfilePassword(p.id, null);
          await s.refresh();
        }, done: l.saved);
      case 'lock':
        await busy(context, () async {
          await Core.lockProfile(p.id);
          await s.refresh();
        });
      case 'delete':
        if (!await warnDialog(context, title: l.deleteProfileTitle(p.name), message: l.deleteProfileBody, confirm: l.delete)) return;
        if (!context.mounted) return;
        await busy(context, () async {
          final pw = await masterPassword(context, l.masterPasswordForDelete);
          await Core.deleteProfile(p.id, pw);
          await s.refresh();
        }, done: l.deleted);
    }
  }
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({this.name = '', this.color = 1, this.editing = false});

  final String name;
  final int color;
  final bool editing;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final _name = TextEditingController(text: widget.name);
  late int _color = widget.color;
  bool _password = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.editing ? l.renameProfile : l.newProfile),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 60,
              decoration: InputDecoration(labelText: l.profileName, hintText: l.profileNameHint),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < profileColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: profileColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(color: _color == i ? context.palette.text : Colors.transparent, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
            if (!widget.editing)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _password,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l.protectWithPassword),
                subtitle: Text(l.profilePasswordHelp),
                onChanged: (v) => setState(() => _password = v ?? false),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: () {
            final n = _name.text.trim();
            if (n.isEmpty) return showToast(context, l.nameRequired, error: true);
            Navigator.pop(context, (name: n, color: _color, password: _password));
          },
          child: Text(widget.editing ? l.save : l.create),
        ),
      ],
    );
  }
}
