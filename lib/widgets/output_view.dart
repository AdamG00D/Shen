import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/system.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import 'feedback.dart';
import 'fingerprint.dart';
import 'prompts.dart';
import 'ui.dart';

/// نص ناتج (رسالة متشفّرة، توقيع، مفتاح عام...) مع نسخ / مشاركة / حفظ.
class OutputBox extends StatelessWidget {
  const OutputBox({super.key, required this.text, required this.fileName, this.sensitive = false, this.mono = true});

  final String text;
  final String fileName;

  /// نص مفكوك (سري): بيتنسخ "حساس" ومبنعرضش زرار المشاركة.
  final bool sensitive;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 340),
          decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            // النص السري مينفعش يتحدد ويتنسخ بنسخ النظام العادي (مش هيتمسح من الحافظة) — زرار "نسخ" بس
            child: sensitive
                ? Text(text, style: TextStyle(fontSize: 15, height: 1.5, color: p.text))
                : SelectableText(
                    text,
                    textDirection: mono ? TextDirection.ltr : null,
                    style: TextStyle(fontFamily: mono ? AppTheme.monoFamily : null, fontSize: mono ? 12.5 : 15, height: 1.5, color: p.text),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: l.copy,
                icon: Icons.copy_rounded,
                onPressed: () => copySecure(context, text, sensitive: sensitive),
              ),
            ),
            if (!sensitive) ...[
              const SizedBox(width: 8),
              Expanded(
                child: SecondaryButton(
                  label: l.share,
                  icon: Icons.share_rounded,
                  onPressed: () => SystemBridge.shareText(text, l.share),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                label: l.saveFile,
                icon: Icons.save_alt_rounded,
                onPressed: () => saveTextFile(context, text, fileName),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// حفظ نص في ملف يختاره المستخدم.
Future<void> saveTextFile(BuildContext context, String text, String fileName) async {
  final out = await SystemBridge.pickCreate(fileName);
  if (out == null || !context.mounted) return;
  await busy(context, () => SystemBridge.writeUri(out.uri, Uint8List.fromList(utf8.encode(text))), done: context.l10n.saved);
}

/// شاشة نتيجة كاملة.
class OutputScreen extends StatelessWidget {
  const OutputScreen({super.key, required this.title, required this.text, required this.fileName, this.header, this.sensitive = false});

  final String title;
  final String text;
  final String fileName;
  final Widget? header;
  final bool sensitive;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (header != null) ...[header!, const SizedBox(height: 14)],
          OutputBox(text: text, fileName: fileName, sensitive: sensitive, mono: !sensitive),
        ],
      ),
    );
  }
}

void showDone(BuildContext context, String message) => showToast(context, message);
