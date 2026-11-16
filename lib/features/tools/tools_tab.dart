import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/ui.dart';
import 'file_screen.dart';
import 'text_screens.dart';

class ToolsTab extends StatelessWidget {
  const ToolsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void go(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SectionLabel(l.text),
        _Tool(icon: Icons.lock_rounded, title: l.encryptText, subtitle: l.encryptTextHelp, onTap: () => go(const EncryptTextScreen())),
        _Tool(icon: Icons.lock_open_rounded, title: l.decryptVerify, subtitle: l.decryptVerifyShort, onTap: () => go(const DecryptTextScreen())),
        _Tool(icon: Icons.draw_rounded, title: l.signText, subtitle: l.signTextHelp, onTap: () => go(const SignTextScreen())),
        SectionLabel(l.files),
        _Tool(icon: Icons.enhanced_encryption_rounded, title: l.encryptFile, subtitle: l.encryptFileShort, onTap: () => go(const FileScreen(mode: FileMode.encrypt))),
        _Tool(icon: Icons.no_encryption_gmailerrorred_rounded, title: l.decryptFile, subtitle: l.decryptFileShort, onTap: () => go(const FileScreen(mode: FileMode.decrypt))),
        _Tool(icon: Icons.history_edu_rounded, title: l.signFile, subtitle: l.signFileShort, onTap: () => go(const FileScreen(mode: FileMode.sign))),
        _Tool(icon: Icons.fact_check_rounded, title: l.verifyFile, subtitle: l.verifyFileShort, onTap: () => go(const FileScreen(mode: FileMode.verify))),
      ],
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            IconBadge(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: p.textMuted, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}
