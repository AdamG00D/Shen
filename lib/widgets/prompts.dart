import 'package:flutter/material.dart';

import '../core/core_api.dart';
import '../core/errors.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import 'feedback.dart';
import 'password_field.dart';

/// بيشغّل عملية مع مؤشر انتظار؛ لو فشلت بيعرض رسالة ويرجّع null.
Future<T?> busy<T>(BuildContext context, Future<T> Function() task, {String? done}) async {
  final nav = Navigator.of(context, rootNavigator: true);
  var shown = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
  ).whenComplete(() => shown = false);
  try {
    final r = await task();
    if (shown) nav.pop();
    if (done != null && context.mounted) showToast(context, done);
    return r;
  } on Cancelled {
    if (shown) nav.pop();
    return null;
  } catch (e) {
    if (shown) nav.pop();
    if (context.mounted) showToast(context, errorText(context.l10n, e), error: true);
    return null;
  }
}

/// نافذة كلمة سر عامة. [check] بيتحقق قبل ما النافذة تتقفل (يرجّع رسالة خطأ أو null).
Future<String?> askSecret(
  BuildContext context, {
  required String title,
  String? message,
  required String label,
  String? confirmLabel,
  Future<String?> Function(String value)? check,
  bool allowEmpty = false,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _SecretDialog(
        title: title,
        message: message,
        label: label,
        confirmLabel: confirmLabel,
        check: check,
        allowEmpty: allowEmpty,
      ),
    );

class _SecretDialog extends StatefulWidget {
  const _SecretDialog({
    required this.title,
    required this.message,
    required this.label,
    required this.confirmLabel,
    required this.check,
    required this.allowEmpty,
  });

  final String title;
  final String? message;
  final String label;
  final String? confirmLabel;
  final Future<String?> Function(String value)? check;
  final bool allowEmpty;

  @override
  State<_SecretDialog> createState() => _SecretDialogState();
}

class _SecretDialogState extends State<_SecretDialog> {
  final _c = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _c.clear();
    _c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final v = _c.text;
    if (v.isEmpty && !widget.allowEmpty) return;
    if (widget.check != null) {
      setState(() => _busy = true);
      final err = await widget.check!(v);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = err;
      });
      if (err != null) return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message != null) ...[Text(widget.message!), const SizedBox(height: 14)],
          PasswordField(
            controller: _c,
            label: widget.label,
            autofocus: true,
            errorText: _error,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.confirmLabel ?? l.ok),
        ),
      ],
    );
  }
}

/// كلمة سر المفتاح لو محتاجها (null = ملوش كلمة سر أو محفوظة مؤقتاً). بيرمي [Cancelled] لو اتلغت.
Future<String?> keyPassphrase(BuildContext context, KeyInfo key) async {
  final profile = Session.instance.active!.id;
  if (!await Core.needsPassphrase(profile, key.fp)) return null;
  if (!context.mounted) throw const Cancelled();
  final l = context.l10n;
  final p = await askSecret(
    context,
    title: l.keyPassphraseTitle,
    message: l.keyPassphraseFor(key.primaryUid ?? key.keyId),
    label: l.keyPassphrase,
    check: (v) async => await Core.checkKeyPassphrase(profile, key.fp, v) ? null : l.errWrongPassword,
  );
  if (p == null) throw const Cancelled();
  return p;
}

/// كلمة السر الرئيسية (للحاجات الخطيرة: تصدير مفتاح سري، حذف...). بيرمي [Cancelled].
Future<String> masterPassword(BuildContext context, String reason) async {
  final l = context.l10n;
  final p = await askSecret(
    context,
    title: l.masterPasswordTitle,
    message: reason,
    label: l.masterPassword,
    check: (v) async => await Core.verifyMasterPassword(v) ? null : l.errWrongPassword,
  );
  if (p == null) throw const Cancelled();
  return p;
}

/// كلمة سر جديدة مع تأكيد. [min] = أقل طول.
Future<String?> askNewPassword(BuildContext context, {required String title, String? message, int min = 8}) =>
    showDialog<String>(context: context, builder: (_) => _NewPasswordDialog(title: title, message: message, min: min));

class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog({required this.title, required this.message, required this.min});

  final String title;
  final String? message;
  final int min;

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _a.clear();
    _b.clear();
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _submit() {
    final l = context.l10n;
    if (_a.text.length < widget.min) return setState(() => _error = l.passwordTooShort(widget.min));
    if (_a.text != _b.text) return setState(() => _error = l.passwordsDontMatch);
    Navigator.pop(context, _a.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.message != null) ...[Text(widget.message!), const SizedBox(height: 14)],
            PasswordField(controller: _a, label: l.newPassword, autofocus: true, showStrength: true, textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            PasswordField(
              controller: _b,
              label: l.confirmPassword,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(90, 44)), onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}

/// نافذة نص قصير (اسم، ملاحظة، هوية...).
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  int maxLength = 100,
  int maxLines = 1,
  TextInputType? keyboard,
}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: 1,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: Text(ctx.l10n.save),
        ),
      ],
    ),
  ).whenComplete(c.dispose);
}

/// تحذير قبل حاجة خطيرة، بخانة "فهمت" لازم تتعلّم.
Future<bool> warnDialog(BuildContext context, {required String title, required String message, required String confirm}) async {
  var ok = false;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final p = ctx.palette;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: p.danger, size: 34),
          title: Text(title, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 10),
              CheckboxListTile(
                value: ok,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(ctx.l10n.iUnderstand),
                onChanged: (v) => set(() => ok = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.cancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: p.danger, foregroundColor: Colors.white, minimumSize: const Size(90, 44)),
              onPressed: ok ? () => Navigator.pop(ctx, true) : null,
              child: Text(confirm),
            ),
          ],
        );
      },
    ),
  );
  return r ?? false;
}
