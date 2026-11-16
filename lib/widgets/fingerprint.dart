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
  const FingerprintView({super.key, required this.fp, this.onQr, this.title});

  final String fp;
  final VoidCallback? onQr;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final groups = [for (var i = 0; i < fp.length; i += 4) fp.substring(i, (i + 4).clamp(0, fp.length))];
    // 10 مجموعات (v4) في صفين، 16 (v6) في 4 صفوف — آخر مجموعة نحاسي عشان العين تمسك فيها
    final perRow = groups.length > 10 ? 4 : 5;
    final rows = [for (var i = 0; i < groups.length; i += perRow) groups.sublist(i, (i + perRow).clamp(0, groups.length))];
    Widget action(IconData icon, String tip, VoidCallback onTap) => SizedBox(
          width: 44,
          height: 38,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 38),
              side: BorderSide(color: p.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Tooltip(message: tip, child: Icon(icon, size: 18, color: p.text)),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title ?? l.fingerprint,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textMuted),
                ),
              ),
              action(Icons.copy_rounded, l.copy, () {
                SystemBridge.copy(fp, sensitive: false);
                showToast(context, l.copied);
              }),
              if (onQr != null) ...[const SizedBox(width: 6), action(Icons.qr_code_2_rounded, l.showQr, onQr!)],
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: formatFingerprint(fp),
            excludeSemantics: true,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          for (final g in row)
                            Expanded(
                              child: Text(
                                g,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.monoFamily,
                                  fontSize: 16,
                                  height: 1.4,
                                  color: identical(g, groups.last) ? p.accentText : p.text,
                                ),
                              ),
                            ),
                          for (var i = row.length; i < perRow; i++) const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
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
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1C1B19)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1C1B19)),
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
