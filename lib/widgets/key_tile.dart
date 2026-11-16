import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../core/models.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import 'ui.dart';

String formatDate(BuildContext context, DateTime d) => DateFormat.yMMMd(context.l10n.localeName).format(d);

/// البصمة المختصرة: أول 8 وآخر 8 من رقم المفتاح ("96B9 3622 · 0BFC DDD6").
String shortKeyId(String keyId) {
  final id = keyId.toUpperCase();
  if (id.length < 16) return id;
  return '${id.substring(0, 4)} ${id.substring(4, 8)} · ${id.substring(8, 12)} ${id.substring(12, 16)}';
}

/// الحالات: منتهي / ملغي / هيخلص قريب / الافتراضي / من غير كلمة سر / متأكد منه / كل البروفايلات.
List<Widget> keyChips(BuildContext context, KeyInfo k, {bool showScope = true}) {
  final p = context.palette;
  final l = context.l10n;
  return [
    if (k.revoked) Chip2(l.revoked, color: p.danger),
    if (!k.revoked && k.expired) Chip2(l.expired, color: p.danger),
    if (!k.revoked && !k.expired && k.expires != null && k.expires!.difference(DateTime.now()).inDays < 30)
      Chip2(l.expiresSoon, color: p.warning),
    if (k.isDefault) Chip2(l.defaultKey, color: p.accentText),
    if (k.secret && !k.protected) Chip2(l.noPassphrase, color: p.warning),
    if (!k.secret && k.verified) Chip2(l.verified, color: p.success),
    if (!k.secret && showScope && k.shared) Chip2(l.allProfiles),
  ];
}

/// لون حلقة الختم: نحاس لمفاتيحي، ملكيت لجهة اتصال متأكد منها، رمادي للباقي أو للمنتهي.
Color keyRing(Palette p, KeyInfo k) {
  if (!k.usable) return p.border;
  if (k.secret) return p.accent;
  return k.verified ? p.success : p.border;
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
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      borderColor: selected == true ? p.text : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Monogram(name: k.label, ring: keyRing(p, k)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: dim ? p.textMuted : p.text),
                ),
                if (k.email != null && k.name.isNotEmpty)
                  Text(
                    k.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: p.textMuted, fontSize: 13),
                  ),
                const SizedBox(height: 6),
                Text(
                  shortKeyId(k.keyId),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: p.textMuted, fontSize: 12.5, fontFamily: AppTheme.monoFamily),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 14, runSpacing: 6, children: chips),
                ],
              ],
            ),
          ),
          if (selected != null)
            Icon(
              selected! ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: selected! ? p.text : p.textMuted,
            )
          else
            trailing ?? Icon(Icons.chevron_right_rounded, color: p.textMuted, size: 20),
        ],
      ),
    );
  }
}
