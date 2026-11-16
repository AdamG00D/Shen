import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/feedback.dart';
import '../../widgets/key_picker.dart';
import '../../widgets/prompts.dart';
import '../../widgets/signature_card.dart';
import '../../widgets/ui.dart';

/// طريقة فك رسالة: بمفتاح من مفاتيحي، أو بكلمة سر الرسالة.
typedef DecryptMethod = ({String? keyFp, String? passphrase, String? password});

/// بيقرر هنفك إزاي ويطلب كلمة السر لو لازم. بيرمي [Cancelled] لو المستخدم لغى أو الرسالة مش ليه.
Future<DecryptMethod> chooseDecryption(BuildContext context, Inspection ins) async {
  final l = context.l10n;
  final s = Session.instance;
  for (final r in ins.mine) {
    final key = s.keys.where((k) => k.fp == r.fp).firstOrNull;
    if (key == null) continue;
    final pass = await keyPassphrase(context, key);
    return (keyFp: key.fp, passphrase: pass, password: null);
  }
  if (!context.mounted) throw const Cancelled();
  if (ins.password) {
    final pw = await askSecret(context, title: l.messagePasswordTitle, message: l.messagePasswordBody, label: l.messagePassword);
    if (pw == null) throw const Cancelled();
    return (keyFp: null, passphrase: null, password: pw);
  }
  final other = ins.recipients.map((r) => r.otherProfile).whereType<String>().firstOrNull;
  if (other != null) {
    await infoDialog(context, title: l.otherProfileTitle, message: l.otherProfileBody(other), icon: Icons.folder_shared_rounded);
  } else {
    final ids = ins.recipients.map((r) => r.keyId).where((id) => id != '0000000000000000').join('\n');
    await infoDialog(
      context,
      title: l.notForYouTitle,
      message: ids.isEmpty ? l.notForYouHidden : l.notForYouBody(ids),
      icon: Icons.lock_person_rounded,
      error: true,
    );
  }
  throw const Cancelled();
}

/// نتايج التحقق من التوقيعات (أو "مش موقّعة").
class SignaturesView extends StatelessWidget {
  const SignaturesView({super.key, required this.sigs});

  final List<SigResult> sigs;

  @override
  Widget build(BuildContext context) {
    if (sigs.isEmpty) return const NoSignatureCard();
    return Column(
      children: [
        for (final s in sigs) ...[SignatureCard(sig: s), const SizedBox(height: 8)],
      ],
    );
  }
}

/// المستلمين + التوقيع + التشفير لنفسي — نفس الإعدادات في النص والملفات.
/// التوقيع والتشفير لنفسي بيبدأوا مقفولين — المستخدم يفعّلهم بنفسه.
class EncryptOptions {
  Set<String> recipients = {};
  String? signWith;
  bool self = false;
  bool usePassword = false;
}

class EncryptOptionsView extends StatefulWidget {
  const EncryptOptionsView({super.key, required this.options, required this.onChanged});

  final EncryptOptions options;
  final VoidCallback onChanged;

  @override
  State<EncryptOptionsView> createState() => _EncryptOptionsViewState();
}

class _EncryptOptionsViewState extends State<EncryptOptionsView> {
  EncryptOptions get o => widget.options;

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final s = Session.instance;
    final all = [...s.contacts, ...s.keys];
    final chosen = all.where((k) => o.recipients.contains(k.fp)).toList();
    final signer = s.keys.where((k) => k.fp == o.signWith).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, icon: const Icon(Icons.people_rounded), label: Text(l.toPeople)),
            ButtonSegment(value: true, icon: const Icon(Icons.password_rounded), label: Text(l.withPassword)),
          ],
          selected: {o.usePassword},
          onSelectionChanged: (v) {
            o.usePassword = v.first;
            _changed();
          },
        ),
        const SizedBox(height: 12),
        if (o.usePassword)
          Text(l.passwordModeHelp, style: TextStyle(color: p.textMuted, height: 1.5, fontSize: 13))
        else ...[
          SectionLabel(
            l.recipients,
            trailing: TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l.add),
              onPressed: () async {
                final r = await pickRecipients(context, o.recipients);
                if (r != null) {
                  o.recipients = r;
                  _changed();
                }
              },
            ),
          ),
          if (chosen.isEmpty)
            Text(l.noRecipientsChosen, style: TextStyle(color: p.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in chosen)
                  InputChip(
                    avatar: Icon(k.verified || k.secret ? Icons.verified_rounded : Icons.person_rounded, size: 18),
                    label: Text(k.label),
                    onDeleted: () {
                      o.recipients.remove(k.fp);
                      _changed();
                    },
                  ),
              ],
            ),
          if (chosen.any((k) => !k.secret && !k.verified)) ...[
            const SizedBox(height: 8),
            Text(l.unverifiedRecipientWarning, style: TextStyle(color: p.warning, fontSize: 12.5, height: 1.5)),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: o.self,
            title: Text(l.encryptToSelf),
            subtitle: Text(s.keys.isEmpty ? l.needOwnKey : l.encryptToSelfHelp),
            onChanged: s.keys.isEmpty
                ? null
                : (v) {
                    o.self = v;
                    _changed();
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: o.signWith != null,
            title: Text(l.signMessage),
            subtitle: Text(
              s.signingKeys.isEmpty
                  ? (s.keys.isEmpty ? l.needOwnKey : l.needSigningKey)
                  : signer == null
                      ? l.signMessageHelp
                      : l.signingAs(signer.primaryUid ?? signer.keyId),
            ),
            onChanged: s.signingKeys.isEmpty
                ? null
                : (v) {
                    final def = s.signingKeys.where((k) => k.fp == s.defaultKey?.fp).firstOrNull;
                    o.signWith = v ? (def ?? s.signingKeys.first).fp : null;
                    _changed();
                  },
          ),
          if (o.signWith != null && s.signingKeys.length > 1)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () async {
                  final k = await pickSigningKey(context, current: o.signWith);
                  if (k != null) {
                    o.signWith = k.fp;
                    _changed();
                  }
                },
                child: Text(l.changeSigningKey),
              ),
            ),
        ],
      ],
    );
  }
}

/// بيتأكد إن فيه مستلمين قبل التشفير.
bool checkRecipients(BuildContext context, EncryptOptions o) {
  if (o.usePassword || o.recipients.isNotEmpty || (o.self && Session.instance.keys.isNotEmpty)) return true;
  showToast(context, context.l10n.noRecipientsChosen, error: true);
  return false;
}

/// كلمة سر الرسالة (للتشفير بكلمة سر).
Future<String> newMessagePassword(BuildContext context) async {
  final l = context.l10n;
  final pw = await askNewPassword(context, title: l.messagePasswordTitle, message: l.newMessagePasswordBody);
  if (pw == null) throw const Cancelled();
  return pw;
}

/// كلمة سر مفتاح التوقيع لو هنوقّع.
Future<String?> signerPassphrase(BuildContext context, EncryptOptions o) async {
  if (o.usePassword || o.signWith == null) return null;
  final k = Session.instance.keys.firstWhere((k) => k.fp == o.signWith);
  return keyPassphrase(context, k);
}
