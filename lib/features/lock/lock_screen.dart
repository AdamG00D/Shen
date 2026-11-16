import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/errors.dart';
import '../../core/session.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/focus_guard.dart';
import '../../widgets/password_field.dart';
import '../../widgets/shen_mark.dart';
import '../../widgets/ui.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pw = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _bioShowing = false;
  AppLifecycleListener? _resume;

  @override
  void initState() {
    super.initState();
    // البصمة تطلع لوحدها مرة واحدة بس — ولو اتقفل والتطبيق في الخلفية، تستنى لما يرجع للواجهة
    if (!Session.instance.bioEnabled) return;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
    } else {
      _resume = AppLifecycleListener(onResume: () {
        _resume?.dispose();
        _resume = null;
        if (mounted) _bio();
      });
    }
  }

  @override
  void dispose() {
    _resume?.dispose();
    _pw.clear();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_pw.text.isEmpty || _busy) return;
    hideKeyboard();
    setState(() => _busy = true);
    try {
      await Session.instance.unlock(_pw.text);
      _pw.clear();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bio() async {
    if (_bioShowing) return;
    _bioShowing = true;
    final l = context.l10n;
    try {
      await Session.instance.unlockWithBio(l.bioTitle, l.bioSubtitle, l.usePassword);
    } on CoreException catch (e) {
      if (e.code == 'CANCELLED') return;
      if (e.code == 'BIO_INVALIDATED') await Session.instance.refreshBio();
      if (mounted) setState(() => _error = errorText(l, e));
    } catch (e) {
      if (mounted) setState(() => _error = errorText(l, e));
    } finally {
      _bioShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    return AppScaffold(
      showAppBar: false,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: ShenMark(size: 120)),
              const SizedBox(height: 18),
              Text(l.locked, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(l.lockedHint, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
              const SizedBox(height: 26),
              PasswordField(
                controller: _pw,
                label: l.masterPassword,
                autofocus: !Session.instance.bioEnabled,
                errorText: _error,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _unlock(),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: l.unlock, icon: Icons.lock_open_rounded, loading: _busy, onPressed: _unlock),
              if (Session.instance.bioEnabled) ...[
                const SizedBox(height: 10),
                SecondaryButton(label: l.unlockWithBio, icon: Icons.fingerprint_rounded, onPressed: _bio),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
