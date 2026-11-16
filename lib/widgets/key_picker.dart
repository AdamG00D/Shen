import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import 'key_tile.dart';
import 'ui.dart';

bool _matches(KeyInfo k, String q) {
  if (q.isEmpty) return true;
  final s = q.toLowerCase();
  return k.uids.any((u) => u.toLowerCase().contains(s)) || k.fp.toLowerCase().contains(s.replaceAll(' ', ''));
}

/// اختيار المستلمين (جهات الاتصال + مفاتيحي). بيرجّع البصمات.
Future<Set<String>?> pickRecipients(BuildContext context, Set<String> initial) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RecipientsSheet(initial: initial),
  );
}

class _RecipientsSheet extends StatefulWidget {
  const _RecipientsSheet({required this.initial});

  final Set<String> initial;

  @override
  State<_RecipientsSheet> createState() => _RecipientsSheetState();
}

class _RecipientsSheetState extends State<_RecipientsSheet> {
  late final Set<String> _sel = {...widget.initial};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final s = Session.instance;
    final contacts = s.contacts.where((k) => k.usable && k.canEncrypt && _matches(k, _q)).toList();
    final mine = s.keys.where((k) => k.usable && k.canEncrypt && _matches(k, _q)).toList();
    final unusable = s.contacts.where((k) => !(k.usable && k.canEncrypt)).length;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                decoration: InputDecoration(hintText: l.search, prefixIcon: const Icon(Icons.search_rounded)),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  if (contacts.isEmpty && mine.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l.noRecipients, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
                    ),
                  if (contacts.isNotEmpty) SectionLabel(l.contacts),
                  for (final k in contacts) ...[
                    KeyTile(k: k, selected: _sel.contains(k.fp), onTap: () => _toggle(k.fp)),
                    const SizedBox(height: 8),
                  ],
                  if (mine.isNotEmpty) SectionLabel(l.myKeys),
                  for (final k in mine) ...[
                    KeyTile(k: k, selected: _sel.contains(k.fp), onTap: () => _toggle(k.fp)),
                    const SizedBox(height: 8),
                  ],
                  if (unusable > 0)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(l.hiddenUnusable(unusable), style: TextStyle(color: p.textMuted, fontSize: 12.5)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: PrimaryButton(
                label: _sel.isEmpty ? l.done : l.selectedCount(_sel.length),
                onPressed: () => Navigator.pop(context, _sel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(String fp) => setState(() => _sel.contains(fp) ? _sel.remove(fp) : _sel.add(fp));
}

/// اختيار مفتاح من مفاتيحي اللي تقدر توقّع.
Future<KeyInfo?> pickSigningKey(BuildContext context, {String? current}) {
  final keys = Session.instance.signingKeys;
  return showModalBottomSheet<KeyInfo>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            SectionLabel(ctx.l10n.chooseSigningKey),
            for (final k in keys) ...[
              KeyTile(k: k, selected: k.fp == current, onTap: () => Navigator.pop(ctx, k)),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}
