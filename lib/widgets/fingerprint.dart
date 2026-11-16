import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/settings.dart';
import '../core/system.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import 'feedback.dart';

/// البصمة على شكل مجموعات من 4 حروف (أسهل في المقارنة بالعين أو في التليفون).
String formatFingerprint(String fp) {
  final b = StringBuffer();
  for (var i = 0; i < fp.length; i += 4) {
    if (i > 0) b.write(i == fp.length ~/ 2 ? '   ' : ' ');
    b.write(fp.substring(i, (i + 4).clamp(0, fp.length)));
  }
  return b.toString();
}

/// QR بصيغة OpenKeychain: `OPENPGP4FPR:<البصمة>`.
String fingerprintQr(String fp) => 'OPENPGP4FPR:$fp';

/// بيطلّع البصمة من نص QR (صيغة OpenKeychain، أو بصمة hex لوحدها). null = مش بصمة.
String? parseFingerprintQr(String text) {
  var t = text.trim();
  if (t.toUpperCase().startsWith('OPENPGP4FPR:')) t = t.substring(12);
  t = t.split('#').first.replaceAll(RegExp(r'\s'), '').toUpperCase();
  if (RegExp(r'^([0-9A-F]{40}|[0-9A-F]{64})$').hasMatch(t)) return t;
  return null;
}

class FingerprintView extends StatelessWidget {
  const FingerprintView({super.key, required this.fp, this.onQr});

  final String fp;
  final VoidCallback? onQr;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                formatFingerprint(fp),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  height: 1.6,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  color: p.text,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l.copy,
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              SystemBridge.copy(fp, sensitive: false);
              showToast(context, l.copied);
            },
          ),
          if (onQr != null) IconButton(tooltip: l.showQr, icon: const Icon(Icons.qr_code_2_rounded), onPressed: onQr),
        ],
      ),
    );
  }
}

/// نافذة QR. [data] = النص اللي هيتعمل QR (بصمة أو مفتاح عام كامل).
Future<void> showQrDialog(BuildContext context, {required String title, required String data, String? caption}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final l = ctx.l10n;
      return AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: data,
                  size: 260,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: data.length > 1200 ? QrErrorCorrectLevel.L : QrErrorCorrectLevel.M,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 12),
                Text(caption, textAlign: TextAlign.center, style: TextStyle(color: ctx.palette.textMuted, fontSize: 13, height: 1.5)),
              ],
            ],
          ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close))],
      );
    },
  );
}

/// نسخ نص حساس (بيتمسح من الحافظة لوحده).
Future<void> copySecure(BuildContext context, String text, {bool sensitive = true}) async {
  await SystemBridge.copy(text, sensitive: sensitive, clearAfter: AppSettings.instance.clipboardSeconds);
  if (context.mounted) {
    showToast(context, sensitive ? context.l10n.copiedSecure(AppSettings.instance.clipboardSeconds) : context.l10n.copied);
  }
}
