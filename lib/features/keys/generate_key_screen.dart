import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/errors.dart';
import '../../core/session.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/focus_guard.dart';
import '../../widgets/password_field.dart';
import '../../widgets/ui.dart';
import 'key_details_screen.dart';

class GenerateKeyScreen extends StatefulWidget {
  const GenerateKeyScreen({super.key});

  @override
  State<GenerateKeyScreen> createState() => _GenerateKeyScreenState();
}

class _GenerateKeyScreenState extends State<GenerateKeyScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _comment = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String _algo = 'cv25519';
  int _years = 2;
  bool _noPass = false;
  bool _busy = false;
  String? _error;

  static final _emailRe = RegExp(r'^[^\s@<>()]+@[^\s@<>()]+\.[^\s@<>()]+$');

  @override
  void dispose() {
    _pw.clear();
    _pw2.clear();
    for (final c in [_name, _email, _comment, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    final l = context.l10n;
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty && email.isEmpty) return l.nameOrEmailRequired;
    if (email.isNotEmpty && !_emailRe.hasMatch(email)) return l.invalidEmail;
    if (RegExp(r'[<>()]').hasMatch(name + _comment.text)) return l.invalidCharacters;
    if (!_noPass) {
      if (_pw.text.length < 8) return l.passwordTooShort(8);
      if (_pw.text != _pw2.text) return l.passwordsDontMatch;
    }
    return null;
  }

  Future<void> _create() async {
    hideKeyboard();
    final err = _validate();
    setState(() => _error = err);
    if (err != null) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final k = await Core.generateKey(
        profile: Session.instance.active!.id,
        name: _name.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        passphrase: _noPass ? null : _pw.text,
        algo: _algo,
        expires: _years == 0 ? null : DateTime(now.year + _years, now.month, now.day),
      );
      _pw.clear();
      _pw2.clear();
      await Session.instance.refresh();
      if (!mounted) return;
      setState(() => _busy = false);
      await infoDialog(context, title: l.keyCreatedTitle, message: l.keyCreatedBody, icon: Icons.check_circle_rounded);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => KeyDetailsScreen(fp: k.fp)));
    } catch (e) {
      if (mounted) showToast(context, errorText(l, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    return AppScaffold(
      title: l.newKey,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l.newKeyIntro, style: TextStyle(color: p.textMuted, height: 1.6)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.name, prefixIcon: const Icon(Icons.person_rounded)),
          ),
          TextField(
            controller: _email,
            maxLength: 120,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: l.emailOptional, prefixIcon: const Icon(Icons.alternate_email_rounded)),
          ),
          TextField(
            controller: _comment,
            maxLength: 60,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.commentOptional,
              helperText: l.commentHelp,
              prefixIcon: const Icon(Icons.label_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          SectionLabel(l.keyPassphrase),
          Text(l.keyPassphraseHelp, style: TextStyle(color: p.textMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 10),
          if (!_noPass) ...[
            PasswordField(controller: _pw, label: l.keyPassphrase, showStrength: true, textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            PasswordField(controller: _pw2, label: l.confirmPassword, textInputAction: TextInputAction.done),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _noPass,
            title: Text(l.noPassphraseOption),
            subtitle: Text(l.noPassphraseWarning, style: TextStyle(color: p.warning, fontSize: 12.5)),
            onChanged: (v) => setState(() => _noPass = v),
          ),
          SectionLabel(l.expiry),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final y in [1, 2, 3, 5, 0])
                ChoiceChip(
                  label: Text(y == 0 ? l.never : l.yearsCount(y)),
                  selected: _years == y,
                  onSelected: (_) => setState(() => _years = y),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l.expiryHelp, style: TextStyle(color: p.textMuted, fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l.advanced, style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                RadioGroup<String>(
                  groupValue: _algo,
                  onChanged: (v) => setState(() => _algo = v ?? 'cv25519'),
                  child: Column(
                    children: [
                      RadioListTile<String>(value: 'cv25519', title: Text(l.algoCv25519), subtitle: Text(l.algoCv25519Help)),
                      RadioListTile<String>(value: 'rsa4096', title: Text(l.algoRsa), subtitle: Text(l.algoRsaHelp)),
                      RadioListTile<String>(value: 'v6', title: Text(l.algoV6), subtitle: Text(l.algoV6Help)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: p.danger, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: l.createKey, icon: Icons.vpn_key_rounded, loading: _busy, onPressed: _create),
          if (_busy && _algo == 'rsa4096') ...[
            const SizedBox(height: 10),
            Text(l.rsaSlow, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}
