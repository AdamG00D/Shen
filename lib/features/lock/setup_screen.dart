import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/session.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/focus_guard.dart';
import '../../widgets/password_field.dart';
import '../../widgets/shen_mark.dart';
import '../../widgets/ui.dart';

/// أول تشغيل: كلمة السر الرئيسية + اسم أول بروفايل.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_name.text.isEmpty) _name.text = context.l10n.defaultProfileName;
  }

  @override
  void dispose() {
    _pw.clear();
    _pw2.clear();
    _name.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = context.l10n;
    hideKeyboard();
    if (_name.text.trim().isEmpty) return setState(() => _error = l.nameRequired);
    if (_pw.text.length < 8) return setState(() => _error = l.passwordTooShort(8));
    if (_pw.text != _pw2.text) return setState(() => _error = l.passwordsDontMatch);
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await Session.instance.setup(_pw.text, _name.text.trim(), 0);
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
      showAppBar: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
        children: [
          const Center(child: ShenMark(size: 110)),
          const SizedBox(height: 18),
          Text(l.appName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(l.tagline, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, height: 1.6)),
          const SizedBox(height: 22),
          _Point(icon: Icons.wifi_off_rounded, text: l.introOffline),
          _Point(icon: Icons.folder_shared_rounded, text: l.introProfiles),
          _Point(icon: Icons.handshake_rounded, text: l.introStandard),
          const SizedBox(height: 22),
          SectionLabel(l.setupTitle),
          TextField(
            controller: _name,
            maxLength: 60,
            decoration: InputDecoration(labelText: l.firstProfileName, prefixIcon: const Icon(Icons.person_rounded)),
          ),
          const SizedBox(height: 6),
          PasswordField(controller: _pw, label: l.masterPassword, showStrength: true, textInputAction: TextInputAction.next),
          const SizedBox(height: 12),
          PasswordField(
            controller: _pw2,
            label: l.confirmPassword,
            errorText: _error,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 14),
          AppCard(
            color: p.warning.withValues(alpha: p.isDark ? 0.14 : 0.08),
            borderColor: p.warning.withValues(alpha: 0.4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_rounded, color: p.warning),
                const SizedBox(width: 10),
                Expanded(child: Text(l.masterPasswordWarning, style: const TextStyle(height: 1.6, fontSize: 13.5))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: l.createVault, icon: Icons.lock_rounded, loading: _busy, onPressed: _create),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          IconBadge(icon: icon, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }
}
