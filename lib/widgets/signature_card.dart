import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import 'fingerprint.dart';
import 'key_tile.dart';
import 'ui.dart';

/// نتيجة التحقق من التوقيع بلغة بسيطة:
/// - أخضر: توقيع سليم من حد اتأكدت منه (أو مني).
/// - أصفر: التوقيع سليم بس المفتاح لسه متأكدتش إنه بتاع الشخص ده، أو المفتاح مش عندي.
/// - أحمر: التوقيع غلط (الرسالة اتغيّرت أو التوقيع مزوّر).
class SignatureCard extends StatelessWidget {
  const SignatureCard({super.key, required this.sig});

  final SigResult sig;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    late Color color;
    late IconData icon;
    late String title;
    late String body;
    if (sig.good && (sig.verified || sig.mine)) {
      color = p.success;
      icon = Icons.verified_rounded;
      title = l.sigGoodVerified(sig.name ?? sig.keyId);
      body = sig.mine ? l.sigByMe : l.sigGoodVerifiedBody;
    } else if (sig.good) {
      color = p.warning;
      icon = Icons.gpp_maybe_rounded;
      title = l.sigGoodUnverified(sig.name ?? sig.keyId);
      body = l.sigGoodUnverifiedBody;
    } else if (sig.unknown) {
      color = p.warning;
      icon = Icons.help_outline_rounded;
      title = l.sigUnknown;
      body = l.sigUnknownBody(sig.keyId);
    } else {
      color = p.danger;
      icon = Icons.gpp_bad_rounded;
      title = l.sigBad;
      body = l.sigBadBody;
    }
    return AppCard(
      color: color.withValues(alpha: p.isDark ? 0.14 : 0.08),
      borderColor: color.withValues(alpha: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: p.text, height: 1.5, fontSize: 13.5)),
                if (sig.created != null) ...[
                  const SizedBox(height: 4),
                  Text(l.signedOn(formatDate(context, sig.created!)), style: TextStyle(color: p.textMuted, fontSize: 12.5)),
                ],
                if (sig.fp != null) ...[
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(formatFingerprint(sig.fp!), style: TextStyle(color: p.textMuted, fontSize: 11.5, fontFamily: 'monospace')),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// لو مفيش توقيع خالص.
class NoSignatureCard extends StatelessWidget {
  const NoSignatureCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: p.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(context.l10n.notSigned, style: TextStyle(color: p.textMuted, height: 1.5))),
        ],
      ),
    );
  }
}
