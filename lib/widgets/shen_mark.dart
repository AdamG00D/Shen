import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// علامة "شِن": حلقة حبل مقفولة فوق خط مستقيم — رمز الحماية عند المصريين القدام.
class ShenMark extends StatelessWidget {
  const ShenMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: p.accentGradient, borderRadius: BorderRadius.circular(size * 0.3)),
      child: CustomPaint(painter: ShenPainter(Palette.onColor(p.accent))),
    );
  }
}

class ShenPainter extends CustomPainter {
  const ShenPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.085;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final r = s * 0.22;
    final c = Offset(size.width / 2, size.height * 0.43);
    canvas.drawCircle(c, r, paint);
    final y = c.dy + r + stroke * 0.55;
    canvas.drawLine(Offset(c.dx - r * 1.15, y), Offset(c.dx + r * 1.15, y), paint);
    // فتحة مفتاح جوه الحلقة
    final fill = Paint()..color = color;
    final hr = r * 0.26;
    final hc = Offset(c.dx, c.dy - r * 0.14);
    canvas.drawCircle(hc, hr, fill);
    canvas.drawPath(
      Path()
        ..moveTo(hc.dx - hr * 0.55, hc.dy + hr * 0.3)
        ..lineTo(hc.dx + hr * 0.55, hc.dy + hr * 0.3)
        ..lineTo(hc.dx + hr * 0.9, hc.dy + hr * 2.2)
        ..lineTo(hc.dx - hr * 0.9, hc.dy + hr * 2.2)
        ..close(),
      fill,
    );
  }

  @override
  bool shouldRepaint(ShenPainter old) => old.color != color;
}
