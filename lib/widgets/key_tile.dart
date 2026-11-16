import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../core/models.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import 'ui.dart';

String formatDate(BuildContext context, DateTime d) => DateFormat.yMMMd(context.l10n.localeName).format(d);

/// شارات الحالة: منتهي / ملغي / متأكد منه / كل البروفايلات / افتراضي.
List<Widget> keyChips(BuildContext context, KeyInfo k, {bool showScope = true}) {
  final p = context.palette;
  final l = context.l10n;
  return [
    if (k.revoked) Chip2(l.revoked, color: p.danger, icon: Icons.block_rounded),
    if (!k.revoked && k.expired) Chip2(l.expired, color: p.danger, icon: Icons.timer_off_rounded),
    if (!k.revoked && !k.expired && k.expires != null && k.expires!.difference(DateTime.now()).inDays < 30)
      Chip2(l.expiresSoon, color: p.warning, icon: Icons.timer_rounded),
    if (k.isDefault) Chip2(l.defaultKey, color: p.accent, icon: Icons.star_rounded),
    if (k.secret && !k.protected) Chip2(l.noPassphrase, color: p.warning, icon: Icons.lock_open_rounded),
    if (!k.secret && k.verified) Chip2(l.verified, color: p.success, icon: Icons.verified_rounded),
    if (!k.secret && showScope && k.shared) Chip2(l.allProfiles, icon: Icons.public_rounded),
  ];
}

class KeyTile extends StatelessWidget {
  const KeyTile({super.key, required this.k, this.onTap, this.trailing, this.selected});

  final KeyInfo k;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chips = keyChips(context, k);
    final dim = !k.usable;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      borderColor: selected == true ? p.accent : null,
      child: Row(
        children: [
          IconBadge(
            icon: k.secret ? Icons.vpn_key_rounded : (k.verified ? Icons.verified_user_rounded : Icons.person_rounded),
            color: dim ? p.textMuted : (k.secret ? p.accent : (k.verified ? p.success : p.second)),
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: dim ? p.textMuted : p.text),
                ),
                if (k.email != null && k.name.isNotEmpty)
                  Text(k.email!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textMuted, fontSize: 13)),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    k.keyId.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim(),
                    style: TextStyle(color: p.textMuted, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: chips),
                ],
              ],
            ),
          ),
          if (selected != null)
            Icon(selected! ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected! ? p.accent : p.textMuted)
          else
            trailing ?? Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
  }
}
