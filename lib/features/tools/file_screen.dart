import 'package:flutter/material.dart';

import '../../core/core_api.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/system.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/key_picker.dart';
import '../../widgets/prompts.dart';
import '../../widgets/ui.dart';
import 'common.dart';

enum FileMode { encrypt, decrypt, sign, verify }

/// اسم الملف من غير امتداد OpenPGP (.pgp / .gpg / .asc).
String stripPgpExt(String name) {
  final lower = name.toLowerCase();
  for (final e in ['.pgp', '.gpg', '.asc']) {
    if (lower.endsWith(e) && name.length > e.length) return name.substring(0, name.length - e.length);
  }
  return '$name.out';
}

String _size(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

/// كل عمليات الملفات في شاشة واحدة. الملفات بتتقري وتتكتب مباشرة في المكان اللي المستخدم اختاره
/// (من غير نسخ مؤقتة جوه التطبيق)، ولو العملية فشلت الملف الناتج بيتمسح.
class FileScreen extends StatefulWidget {
  const FileScreen({super.key, required this.mode, this.input});

  final FileMode mode;
  final PickedFile? input;

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  late PickedFile? _in = widget.input;
  PickedFile? _sig;
  final _opts = EncryptOptions();
  KeyInfo? _key = Session.instance.signingKeys.isEmpty ? null : Session.instance.defaultKey;
  bool _armor = false;
  List<SigResult>? _sigs;
  String? _doneName;

  String get _profile => Session.instance.active!.id;

  Future<void> _pick() async {
    final f = await SystemBridge.pickOpen();
    if (f != null) {
      setState(() {
        _in = f;
        _sigs = null;
        _doneName = null;
      });
    }
  }

  Future<void> _pickSig() async {
    final f = await SystemBridge.pickOpen();
    if (f != null) setState(() => _sig = f);
  }

  Future<void> _run() async {
    final l = context.l10n;
    final input = _in;
    if (input == null) return showToast(context, l.chooseFileFirst, error: true);
    switch (widget.mode) {
      case FileMode.encrypt:
        await _encrypt(input);
      case FileMode.decrypt:
        await _decrypt(input);
      case FileMode.sign:
        await _sign(input);
      case FileMode.verify:
        await _verify(input);
    }
  }

  Future<void> _encrypt(PickedFile input) async {
    if (!checkRecipients(context, _opts)) return;
    final out = await SystemBridge.pickCreate(
      '${input.name}${_armor ? '.asc' : '.pgp'}',
      mime: 'application/pgp-encrypted',
    );
    if (out == null || !mounted) return;
    final ok = await busy(context, () async {
      String? password;
      String? pass;
      if (_opts.usePassword) {
        password = await newMessagePassword(context);
      } else {
        pass = await signerPassphrase(context, _opts);
      }
      await Core.encryptFile(
        profile: _profile,
        input: input.uri,
        output: out.uri,
        recipients: _opts.recipients.toList(),
        signWith: _opts.usePassword ? null : _opts.signWith,
        passphrase: pass,
        password: password,
        fileName: input.name,
        armor: _armor,
        self: _opts.self,
      );
      return true;
    });
    if (ok == true && mounted) setState(() => _doneName = out.name);
  }

  Future<void> _decrypt(PickedFile input) async {
    final ins = await busy(context, () => Core.inspectFile(_profile, input.uri));
    if (ins == null || !mounted) return;
    if (ins.kind != 'encrypted') {
      return showToast(
        context,
        ins.kind == 'signed' ? context.l10n.fileIsSignedOnly : context.l10n.fileNotEncrypted,
        error: true,
      );
    }
    DecryptMethod? m;
    try {
      m = await chooseDecryption(context, ins);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final out = await SystemBridge.pickCreate(stripPgpExt(input.name));
    if (out == null || !mounted) return;
    final r = await busy(
      context,
      () => Core.decryptFile(
        _profile,
        input.uri,
        out.uri,
        keyFp: m!.keyFp,
        passphrase: m.passphrase,
        password: m.password,
      ),
    );
    if (r != null && mounted) {
      setState(() {
        _sigs = r.signatures;
        _doneName = out.name;
      });
    }
  }

  Future<void> _sign(PickedFile input) async {
    final k = _key;
    if (k == null) return showToast(context, context.l10n.needOwnKey, error: true);
    final out = await SystemBridge.pickCreate('${input.name}.sig', mime: 'application/pgp-signature');
    if (out == null || !mounted) return;
    final ok = await busy(context, () async {
      final pass = await keyPassphrase(context, k);
      await Core.signFile(_profile, input.uri, out.uri, k.fp, pass);
      return true;
    });
    if (ok == true && mounted) setState(() => _doneName = out.name);
  }

  Future<void> _verify(PickedFile input) async {
    final sig = _sig;
    if (sig != null) {
      final r = await busy(context, () => Core.verifyFile(_profile, input.uri, signature: sig.uri));
      if (r != null && mounted) setState(() => _sigs = r);
      return;
    }
    // من غير ملف توقيع: يمكن الملف موقّع جوه نفسه (gpg --sign)
    final ins = await busy(context, () => Core.inspectFile(_profile, input.uri));
    if (ins == null || !mounted) return;
    if (ins.kind != 'signed') return showToast(context, context.l10n.chooseSignatureFile, error: true);
    final out = await SystemBridge.pickCreate(stripPgpExt(input.name));
    if (out == null || !mounted) return;
    final r = await busy(context, () => Core.verifyFile(_profile, input.uri, output: out.uri));
    if (r != null && mounted) {
      setState(() {
        _sigs = r;
        _doneName = out.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final (title, help, action, icon) = switch (widget.mode) {
      FileMode.encrypt => (l.encryptFile, l.encryptFileHelp, l.encrypt, Icons.lock_rounded),
      FileMode.decrypt => (l.decryptFile, l.decryptFileHelp, l.decrypt, Icons.lock_open_rounded),
      FileMode.sign => (l.signFile, l.signFileHelp, l.sign, Icons.draw_rounded),
      FileMode.verify => (l.verifyFile, l.verifyFileHelp, l.verify, Icons.fact_check_rounded),
    };
    final k = _key;
    return AppScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(help, style: TextStyle(color: p.textMuted, height: 1.5)),
          const SizedBox(height: 12),
          _FileCard(file: _in, label: l.chooseFile, onTap: _pick),
          if (widget.mode == FileMode.verify) ...[
            const SizedBox(height: 10),
            _FileCard(file: _sig, label: l.chooseSignatureFileOptional, onTap: _pickSig, icon: Icons.verified_outlined),
          ],
          if (widget.mode == FileMode.encrypt) ...[
            const SizedBox(height: 12),
            EncryptOptionsView(options: _opts, onChanged: () => setState(() {})),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _armor,
              title: Text(l.asciiArmor),
              subtitle: Text(l.asciiArmorHelp),
              onChanged: (v) => setState(() => _armor = v),
            ),
          ],
          if (widget.mode == FileMode.sign) ...[
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
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: action, icon: icon, onPressed: _in == null ? null : _run),
          if (_doneName != null) ...[
            const SizedBox(height: 16),
            AppCard(
              color: p.success.withValues(alpha: p.isDark ? 0.14 : 0.08),
              borderColor: p.success.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: p.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.savedAs(_doneName!), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
          if (_sigs != null) ...[SectionLabel(l.signature), SignaturesView(sigs: _sigs!)],
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.file,
    required this.label,
    required this.onTap,
    this.icon = Icons.insert_drive_file_rounded,
  });

  final PickedFile? file;
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final f = file;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: f == null ? Icons.add_rounded : icon, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f?.name ?? label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (f != null) Text(_size(f.size), style: TextStyle(color: p.textMuted, fontSize: 12.5)),
              ],
            ),
          ),
          Icon(Icons.folder_open_rounded, color: p.textMuted),
        ],
      ),
    );
  }
}
