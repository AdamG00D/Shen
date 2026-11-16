import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/system.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/focus_guard.dart';
import '../../widgets/key_picker.dart';
import '../../widgets/output_view.dart';
import '../../widgets/prompts.dart';
import '../../widgets/ui.dart';
import '../contacts/import_screen.dart';
import 'common.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// خانة نص كبيرة مع زرار لصق ومسح.
class _TextArea extends StatelessWidget {
  const _TextArea({required this.controller, required this.hint, this.mono = false});

  final TextEditingController controller;
  final String hint;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          minLines: 6,
          maxLines: 14,
          enableSuggestions: !mono,
          autocorrect: false,
          enableIMEPersonalizedLearning: false,
          textDirection: mono ? TextDirection.ltr : null,
          style: mono ? const TextStyle(fontFamily: AppTheme.monoFamily, fontSize: 12.5) : null,
          decoration: InputDecoration(hintText: hint, alignLabelWithHint: true),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: Text(l.paste),
              onPressed: () async {
                final t = await SystemBridge.paste();
                if (t != null) controller.text = t;
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: Text(l.clear),
              onPressed: controller.clear,
            ),
          ],
        ),
      ],
    );
  }
}

// =================== تشفير نص ===================

class EncryptTextScreen extends StatefulWidget {
  const EncryptTextScreen({super.key, this.initial});

  final String? initial;

  @override
  State<EncryptTextScreen> createState() => _EncryptTextScreenState();
}

class _EncryptTextScreenState extends State<EncryptTextScreen> {
  late final _text = TextEditingController(text: widget.initial);
  final _opts = EncryptOptions();

  @override
  void dispose() {
    _text.clear();
    _text.dispose();
    super.dispose();
  }

  Future<void> _encrypt() async {
    hideKeyboard();
    final l = context.l10n;
    if (_text.text.isEmpty) return showToast(context, l.writeSomething, error: true);
    if (!checkRecipients(context, _opts)) return;
    final out = await busy(context, () async {
      if (_opts.usePassword) {
        final pw = await newMessagePassword(context);
        return Core.encryptTextWithPassword(_text.text, pw);
      }
      final pass = await signerPassphrase(context, _opts);
      return Core.encryptText(
        profile: Session.instance.active!.id,
        text: _text.text,
        recipients: _opts.recipients.toList(),
        signWith: _opts.signWith,
        passphrase: pass,
        self: _opts.self,
      );
    });
    if (out == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutputScreen(
          title: l.encryptedMessage,
          text: out,
          fileName: 'message.asc',
          header: Text(l.encryptedMessageHelp, style: TextStyle(color: context.palette.textMuted, height: 1.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppScaffold(
      title: l.encryptText,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _TextArea(controller: _text, hint: l.writeMessage),
          EncryptOptionsView(options: _opts, onChanged: () => setState(() {})),
          const SizedBox(height: 16),
          PrimaryButton(label: l.encrypt, icon: Icons.lock_rounded, onPressed: _encrypt),
        ],
      ),
    );
  }
}

// =================== فك / تحقق ===================

class DecryptTextScreen extends StatefulWidget {
  const DecryptTextScreen({super.key, this.initial});

  final String? initial;

  @override
  State<DecryptTextScreen> createState() => _DecryptTextScreenState();
}

class _DecryptTextScreenState extends State<DecryptTextScreen> {
  late final _input = TextEditingController(text: widget.initial);
  final _sig = TextEditingController();
  DecryptOutcome? _result;
  bool _wasEncrypted = false;
  bool _needsSig = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null && widget.initial!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  @override
  void dispose() {
    _input.clear();
    _input.dispose();
    _sig.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    hideKeyboard();
    final l = context.l10n;
    final text = _input.text.trim();
    if (text.isEmpty) return showToast(context, l.pasteSomething, error: true);
    final profile = Session.instance.active!.id;
    setState(() => _result = null);
    final data = _bytes(text);
    final ins = await busy(context, () => Core.inspect(profile, data));
    if (ins == null || !mounted) return;
    switch (ins.kind) {
      case 'keys':
        await openImport(context, data);
        return;
      case 'signature':
        if (_sig.text.isEmpty) {
          setState(() => _needsSig = true);
          return showToast(context, l.detachedNeedsText);
        }
        final r = await busy(context, () => Core.verifyText(profile, _bytes(_sig.text), signature: data));
        if (r != null && mounted) {
          setState(() {
            _result = r;
            _wasEncrypted = false;
          });
        }
        return;
      case 'encrypted':
        final r = await busy(context, () async {
          final m = await chooseDecryption(context, ins);
          return Core.decryptText(profile, data, keyFp: m.keyFp, passphrase: m.passphrase, password: m.password);
        });
        if (r != null && mounted) {
          setState(() {
            _result = r;
            _wasEncrypted = true;
          });
        }
        return;
      case 'clearsigned':
      case 'signed':
        final r = await busy(context, () => Core.verifyText(profile, data));
        if (r != null && mounted) {
          setState(() {
            _result = r;
            _wasEncrypted = false;
          });
        }
        return;
      default:
        showToast(context, l.notPgpText, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final r = _result;
    return AppScaffold(
      title: l.decryptVerify,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(l.decryptVerifyHelp, style: TextStyle(color: p.textMuted, height: 1.5)),
          const SizedBox(height: 10),
          _TextArea(controller: _input, hint: l.pasteMessage, mono: true),
          if (_needsSig) ...[SectionLabel(l.signedTextLabel), _TextArea(controller: _sig, hint: l.signedTextHint)],
          const SizedBox(height: 8),
          PrimaryButton(label: l.decryptVerify, icon: Icons.lock_open_rounded, onPressed: _run),
          if (r != null) ...[
            SectionLabel(l.signature),
            SignaturesView(sigs: r.signatures),
            if (r.text != null) ...[
              SectionLabel(_wasEncrypted ? l.decryptedText : l.signedContent),
              OutputBox(text: r.text!, fileName: r.fileName ?? 'message.txt', sensitive: _wasEncrypted, mono: false),
            ],
          ],
        ],
      ),
    );
  }
}

// =================== توقيع نص ===================

class SignTextScreen extends StatefulWidget {
  const SignTextScreen({super.key});

  @override
  State<SignTextScreen> createState() => _SignTextScreenState();
}

class _SignTextScreenState extends State<SignTextScreen> {
  final _text = TextEditingController();
  KeyInfo? _key = Session.instance.signingKeys.isEmpty ? null : Session.instance.defaultKey;
  bool _detached = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _sign() async {
    hideKeyboard();
    final l = context.l10n;
    final k = _key;
    if (k == null) return showToast(context, l.needOwnKey, error: true);
    if (_text.text.isEmpty) return showToast(context, l.writeSomething, error: true);
    final out = await busy(context, () async {
      final pass = await keyPassphrase(context, k);
      return Core.signText(Session.instance.active!.id, _text.text, k.fp, pass, detached: _detached);
    });
    if (out == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OutputScreen(title: l.signedMessage, text: out, fileName: _detached ? 'message.sig' : 'message.asc'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final k = _key;
    return AppScaffold(
      title: l.signText,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _TextArea(controller: _text, hint: l.writeMessage),
          SectionLabel(l.signingKey),
          if (k == null)
            Text(l.needOwnKey)
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.vpn_key_rounded),
              title: Text(k.label),
              subtitle: Text(k.email ?? k.keyId),
              trailing: Session.instance.signingKeys.length > 1 ? const Icon(Icons.swap_horiz_rounded) : null,
              onTap: Session.instance.signingKeys.length > 1
                  ? () async {
                      final n = await pickSigningKey(context, current: k.fp);
                      if (n != null) setState(() => _key = n);
                    }
                  : null,
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _detached,
            title: Text(l.detachedSignature),
            subtitle: Text(l.detachedSignatureHelp),
            onChanged: (v) => setState(() => _detached = v),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: l.sign, icon: Icons.draw_rounded, onPressed: _sign),
        ],
      ),
    );
  }
}
