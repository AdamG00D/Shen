import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';

/// خانة كلمة سر: إخفاء / إظهار، ومن غير اقتراحات الكيبورد ولا حفظ.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.onSubmitted,
    this.textInputAction,
    this.showStrength = false,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool showStrength;
  final String? errorText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          obscureText: !_visible,
          enableSuggestions: false,
          autocorrect: false,
          enableIMEPersonalizedLearning: false,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          onChanged: (v) {
            if (widget.showStrength) setState(() {});
            widget.onChanged?.call(v);
          },
          decoration: InputDecoration(
            labelText: widget.label,
            errorText: widget.errorText,
            prefixIcon: const Icon(Icons.key_rounded),
            suffixIcon: IconButton(
              tooltip: _visible ? l.hide : l.show,
              icon: Icon(_visible ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () => setState(() => _visible = !_visible),
            ),
          ),
        ),
        if (widget.showStrength && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          StrengthMeter(password: widget.controller.text),
        ],
      ],
    );
  }
}

/// تقدير تقريبي لقوة كلمة السر (0..4) — الطول أهم حاجة.
int passwordStrength(String p) {
  if (p.isEmpty) return 0;
  final classes = [
    RegExp(r'[a-z]'),
    RegExp(r'[A-Z]'),
    RegExp(r'[0-9]'),
    RegExp(r'[^a-zA-Z0-9\s]'),
    RegExp(r'\s'),
  ].where((r) => r.hasMatch(p)).length;
  final unique = p.runes.toSet().length;
  var bits = p.runes.length * (classes <= 1 ? 3.0 : classes == 2 ? 4.2 : 5.2);
  if (unique < p.runes.length / 2) bits *= 0.6;
  if (bits < 30) return 0;
  if (bits < 45) return 1;
  if (bits < 60) return 2;
  if (bits < 80) return 3;
  return 4;
}

class StrengthMeter extends StatelessWidget {
  const StrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final s = passwordStrength(password);
    final color = [p.danger, p.danger, p.warning, p.success, p.success][s];
    final label = [l.strengthVeryWeak, l.strengthWeak, l.strengthOk, l.strengthGood, l.strengthStrong][s];
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (s + 1) / 5,
              minHeight: 6,
              color: color,
              backgroundColor: p.surfaceAlt,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
