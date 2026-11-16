import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// علامة "شِن": حلقة حبل مقفولة (خط داخلي رفيع زي الحبل، وقرص الشمس في النص) معقودة فوق خط مستقيم —
/// رمز الحماية عند المصريين القدام. نفس رسمة أيقونة التطبيق (tool/generate_icon.py).
class ShenMark extends StatelessWidget {
  const ShenMark({super.key, this.size = 96, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: ShenPainter(color ?? context.palette.accent)),
    );
  }
}

class ShenPainter extends CustomPainter {
  const ShenPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // نفس إحداثيات الأيقونة (مساحة 160×160)
    final k = size.shortestSide / 160;
    canvas.save();
    canvas.translate((size.width - 160 * k) / 2, (size.height - 160 * k) / 2);
    canvas.scale(k);
    final fill = Paint()..color = color;
    canvas.drawCircle(
      const Offset(80, 68),
      33,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    canvas.drawCircle(
      const Offset(80, 68),
      22,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(const Offset(80, 68), 6, fill);
    canvas.drawRRect(RRect.fromLTRBR(71, 96, 89, 112, const Radius.circular(3)), fill);
    canvas.drawRRect(RRect.fromLTRBR(36, 110, 124, 121, const Radius.circular(5.5)), fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ShenPainter old) => old.color != color;
}
