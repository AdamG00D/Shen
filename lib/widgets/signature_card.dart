import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import 'fingerprint.dart';
import 'key_tile.dart';
import 'ui.dart';

enum SealKind { good, unverified, bad }

/// ختم نتيجة التوقيع: ملكيت ✓ (سليم ومتأكد منه) / نحاس ! (سليم بس المفتاح مش متأكد منه أو مش عندك) / عقيق ✗.
class Seal extends StatelessWidget {
  const Seal({super.key, required this.kind, this.size = 48});

  final SealKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (kind) { SealKind.good => p.success, SealKind.unverified => p.warning, SealKind.bad => p.danger };
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SealPainter(kind, color, p.surface)),
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter(this.kind, this.color, this.on);

  final SealKind kind;
  final Color color;
  final Color on;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    // حلقة خارجية رفيعة + قرص (الختم)
    canvas.drawCircle(c, r - 1.4, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2);
    final inner = r * 0.72;
    final mark = Paint()
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (kind == SealKind.unverified) {
      canvas.drawCircle(c, inner, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1);
      mark.color = color;
      canvas.drawLine(c.translate(0, -inner * 0.45), c.translate(0, inner * 0.12), mark);
      canvas.drawCircle(c.translate(0, inner * 0.45), r * 0.07, Paint()..color = color);
      return;
    }
    canvas.drawCircle(c, inner, Paint()..color = color);
    mark.color = on;
    final s = inner * 0.45;
    if (kind == SealKind.good) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - s, c.dy + s * 0.05)
          ..lineTo(c.dx - s * 0.3, c.dy + s * 0.7)
          ..lineTo(c.dx + s, c.dy - s * 0.6),
        mark,
      );
    } else {
      canvas.drawLine(c.translate(-s * 0.75, -s * 0.75), c.translate(s * 0.75, s * 0.75), mark);
      canvas.drawLine(c.translate(s * 0.75, -s * 0.75), c.translate(-s * 0.75, s * 0.75), mark);
    }
  }

  @override
  bool shouldRepaint(_SealPainter old) => old.kind != kind || old.color != color || old.on != on;
}

/// نتيجة التحقق من التوقيع بلغة بسيطة.
class SignatureCard extends StatelessWidget {
  const SignatureCard({super.key, required this.sig});

  final SigResult sig;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    late SealKind kind;
    late String title;
    late String body;
    if (sig.good && (sig.verified || sig.mine)) {
      kind = SealKind.good;
      title = l.sigGoodVerified(sig.name ?? sig.keyId);
      body = sig.mine ? l.sigByMe : l.sigGoodVerifiedBody;
    } else if (sig.good) {
      kind = SealKind.unverified;
      title = l.sigGoodUnverified(sig.name ?? sig.keyId);
      body = l.sigGoodUnverifiedBody;
    } else if (sig.unknown) {
      kind = SealKind.unverified;
      title = l.sigUnknown;
      body = l.sigUnknownBody(sig.keyId);
    } else {
      kind = SealKind.bad;
      title = l.sigBad;
      body = l.sigBadBody;
    }
    final color = switch (kind) { SealKind.good => p.success, SealKind.unverified => p.warning, SealKind.bad => p.danger };
    return AppCard(
      borderColor: color.withValues(alpha: 0.45),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Seal(kind: kind),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15.5, height: 1.4)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: p.text, height: 1.55, fontSize: 13.5)),
                if (sig.created != null) ...[
                  const SizedBox(height: 6),
                  Text(l.signedOn(formatDate(context, sig.created!)), style: TextStyle(color: p.textMuted, fontSize: 12.5)),
                ],
                if (sig.fp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatFingerprint(sig.fp!),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: p.textMuted, fontSize: 11.5, fontFamily: AppTheme.monoFamily),
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
