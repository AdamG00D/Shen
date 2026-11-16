// موديلات بسيطة بتتقري من الـ Maps اللي جاية من الـ core.

DateTime? _date(Object? ms) => ms == null ? null : DateTime.fromMillisecondsSinceEpoch((ms as num).toInt());

List<String> _strings(Object? o) => (o as List? ?? const []).map((e) => '$e').toList();

class VaultStatus {
  const VaultStatus({required this.exists, required this.unlocked, required this.bio});

  final bool exists;
  final bool unlocked;
  final bool bio;

  factory VaultStatus.fromMap(Map<String, Object?> m) =>
      VaultStatus(exists: m['exists'] == true, unlocked: m['unlocked'] == true, bio: m['bio'] == true);
}

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.color,
    required this.hasPassword,
    required this.open,
    required this.active,
    this.keys,
    this.contacts,
  });

  final String id;
  final String name;
  final int color;
  final bool hasPassword;
  final bool open;
  final bool active;
  final int? keys;
  final int? contacts;

  factory Profile.fromMap(Map<String, Object?> m) => Profile(
        id: m['id'] as String,
        name: m['name'] as String,
        color: (m['color'] as num?)?.toInt() ?? 0,
        hasPassword: m['hasPassword'] == true,
        open: m['open'] == true,
        active: m['active'] == true,
        keys: (m['keys'] as num?)?.toInt(),
        contacts: (m['contacts'] as num?)?.toInt(),
      );
}

class SubkeyInfo {
  const SubkeyInfo({
    required this.fp,
    required this.algo,
    required this.created,
    required this.expires,
    required this.primary,
    required this.flags,
    required this.valid,
    required this.secret,
  });

  final String fp;
  final String algo;
  final DateTime created;
  final DateTime? expires;
  final bool primary;
  final List<String> flags;
  final bool valid;
  final bool secret;

  factory SubkeyInfo.fromMap(Map<String, Object?> m) => SubkeyInfo(
        fp: m['fp'] as String,
        algo: m['algo'] as String? ?? '',
        created: _date(m['created']) ?? DateTime(1970),
        expires: _date(m['expires']),
        primary: m['primary'] == true,
        flags: _strings(m['flags']),
        valid: m['valid'] == true,
        secret: m['secret'] == true,
      );
}

/// مفتاح (من مفاتيحي) أو جهة اتصال (مفتاح عام لحد تاني).
class KeyInfo {
  const KeyInfo({
    required this.fp,
    required this.keyId,
    required this.version,
    required this.uids,
    required this.primaryUid,
    required this.algo,
    required this.created,
    required this.expires,
    required this.expired,
    required this.revoked,
    required this.secret,
    required this.protected,
    required this.canEncrypt,
    required this.canSign,
    required this.canCertify,
    required this.subkeys,
    this.note = '',
    this.isDefault = false,
    this.hasRevocation = false,
    this.scope,
    this.verified = false,
    this.existing,
  });

  final String fp;
  final String keyId;
  final int version;
  final List<String> uids;
  final String? primaryUid;
  final String algo;
  final DateTime created;
  final DateTime? expires;
  final bool expired;
  final bool revoked;
  final bool secret;
  final bool protected;
  final bool canEncrypt;
  final bool canSign;
  final bool canCertify;
  final List<SubkeyInfo> subkeys;

  final String note;
  final bool isDefault;
  final bool hasRevocation;

  /// لجهات الاتصال: 'profile' أو 'shared'.
  final String? scope;
  final bool verified;

  /// في معاينة الاستيراد: موجود فين قبل كده ('key' / 'profile' / 'shared').
  final String? existing;

  bool get usable => !expired && !revoked;
  bool get shared => scope == 'shared';

  /// الاسم من غير الإيميل.
  String get name => UserIdParts.parse(primaryUid ?? '').name;

  String? get email => UserIdParts.parse(primaryUid ?? '').email;

  /// النص اللي بيظهر (الاسم، أو الإيميل لو مفيش اسم، أو آخر البصمة).
  String get label {
    final n = name;
    if (n.isNotEmpty) return n;
    return email ?? keyId;
  }

  factory KeyInfo.fromMap(Map<String, Object?> m) => KeyInfo(
        fp: m['fp'] as String,
        keyId: m['keyId'] as String? ?? '',
        version: (m['version'] as num?)?.toInt() ?? 4,
        uids: _strings(m['uids']),
        primaryUid: m['primaryUid'] as String?,
        algo: m['algo'] as String? ?? '',
        created: _date(m['created']) ?? DateTime(1970),
        expires: _date(m['expires']),
        expired: m['expired'] == true,
        revoked: m['revoked'] == true,
        secret: m['secret'] == true,
        protected: m['protected'] == true,
        canEncrypt: m['canEncrypt'] == true,
        canSign: m['canSign'] == true,
        canCertify: m['canCertify'] == true,
        subkeys: (m['subkeys'] as List? ?? const [])
            .map((e) => SubkeyInfo.fromMap(Map<String, Object?>.from(e as Map)))
            .toList(),
        note: m['note'] as String? ?? '',
        isDefault: m['default'] == true,
        hasRevocation: m['hasRevocation'] == true,
        scope: m['scope'] as String?,
        verified: m['verified'] == true,
        existing: m['existing'] as String?,
      );
}

/// `الاسم (تعليق) <email>`.
class UserIdParts {
  const UserIdParts(this.name, this.email, this.comment);

  final String name;
  final String? email;
  final String? comment;

  static UserIdParts parse(String uid) {
    var rest = uid.trim();
    String? email;
    final lt = rest.lastIndexOf('<');
    if (lt >= 0 && rest.endsWith('>')) {
      email = rest.substring(lt + 1, rest.length - 1).trim();
      rest = rest.substring(0, lt).trim();
    } else if (rest.contains('@') && !rest.contains(' ')) {
      return UserIdParts('', rest, null);
    }
    String? comment;
    final lp = rest.lastIndexOf('(');
    if (lp >= 0 && rest.endsWith(')')) {
      comment = rest.substring(lp + 1, rest.length - 1).trim();
      rest = rest.substring(0, lp).trim();
    }
    return UserIdParts(rest, email?.isEmpty == true ? null : email, comment);
  }
}

class SigResult {
  const SigResult({
    required this.status,
    required this.fp,
    required this.keyId,
    required this.created,
    required this.name,
    required this.verified,
    required this.mine,
  });

  /// 'GOOD' / 'BAD' / 'UNKNOWN_KEY'.
  final String status;
  final String? fp;
  final String keyId;
  final DateTime? created;
  final String? name;
  final bool verified;
  final bool mine;

  bool get good => status == 'GOOD';
  bool get unknown => status == 'UNKNOWN_KEY';

  factory SigResult.fromMap(Map<String, Object?> m) => SigResult(
        status: m['status'] as String? ?? 'BAD',
        fp: m['fp'] as String?,
        keyId: m['keyId'] as String? ?? '',
        created: _date(m['created']),
        name: m['name'] as String?,
        verified: m['verified'] == true,
        mine: m['mine'] == true,
      );
}

class DecryptOutcome {
  const DecryptOutcome({this.text, this.fileName, this.signatures = const []});

  final String? text;
  final String? fileName;
  final List<SigResult> signatures;

  factory DecryptOutcome.fromMap(Map<String, Object?> m) => DecryptOutcome(
        text: m['text'] as String?,
        fileName: m['fileName'] as String?,
        signatures: (m['signatures'] as List? ?? const [])
            .map((e) => SigResult.fromMap(Map<String, Object?>.from(e as Map)))
            .toList(),
      );
}

class Recipient {
  const Recipient({required this.keyId, this.fp, this.uid, this.otherProfile});

  final String keyId;

  /// بصمة مفتاحي اللي يفك الرسالة (لو عندي).
  final String? fp;
  final String? uid;

  /// المفتاح ده في بروفايل تاني مفتوح.
  final String? otherProfile;

  factory Recipient.fromMap(Map<String, Object?> m) => Recipient(
        keyId: m['keyId'] as String? ?? '',
        fp: m['fp'] as String?,
        uid: m['uid'] as String?,
        otherProfile: m['otherProfile'] as String?,
      );
}

/// نوع البيانات: 'encrypted' / 'signed' / 'clearsigned' / 'signature' / 'keys' / 'unknown'.
class Inspection {
  const Inspection({required this.kind, this.recipients = const [], this.password = false});

  final String kind;
  final List<Recipient> recipients;
  final bool password;

  List<Recipient> get mine => recipients.where((r) => r.fp != null).toList();

  factory Inspection.fromMap(Map<String, Object?> m) => Inspection(
        kind: m['kind'] as String? ?? 'unknown',
        recipients: (m['recipients'] as List? ?? const [])
            .map((e) => Recipient.fromMap(Map<String, Object?>.from(e as Map)))
            .toList(),
        password: m['password'] == true,
      );
}

class ImportResult {
  const ImportResult(this.added, this.updated, this.unchanged, this.profiles);

  final int added;
  final int updated;
  final int unchanged;
  final int profiles;

  factory ImportResult.fromMap(Map<String, Object?> m) => ImportResult(
        (m['added'] as num?)?.toInt() ?? 0,
        (m['updated'] as num?)?.toInt() ?? 0,
        (m['unchanged'] as num?)?.toInt() ?? 0,
        (m['profiles'] as num?)?.toInt() ?? 0,
      );
}

class FingerprintMatch {
  const FingerprintMatch(this.kind, this.fp, this.verified);

  /// 'key' أو 'contact'.
  final String kind;
  final String fp;
  final bool verified;

  factory FingerprintMatch.fromMap(Map<String, Object?> m) =>
      FingerprintMatch(m['kind'] as String, m['fp'] as String, m['verified'] == true);
}

class BackupResult {
  const BackupResult(this.profiles, this.keys, this.contacts, this.skipped);

  final int profiles;
  final int keys;
  final int contacts;
  final List<String> skipped;

  factory BackupResult.fromMap(Map<String, Object?> m) => BackupResult(
        (m['profiles'] as num?)?.toInt() ?? 0,
        (m['keys'] as num?)?.toInt() ?? 0,
        (m['contacts'] as num?)?.toInt() ?? 0,
        _strings(m['skipped']),
      );
}

class BackupPreview {
  const BackupPreview(this.created, this.profiles, this.shared);

  final DateTime? created;
  final List<({String name, int keys, int contacts, bool exists})> profiles;
  final int shared;

  factory BackupPreview.fromMap(Map<String, Object?> m) => BackupPreview(
        _date(m['created']),
        (m['profiles'] as List? ?? const []).map((e) {
          final p = Map<String, Object?>.from(e as Map);
          return (
            name: p['name'] as String? ?? '',
            keys: (p['keys'] as num?)?.toInt() ?? 0,
            contacts: (p['contacts'] as num?)?.toInt() ?? 0,
            exists: p['exists'] == true,
          );
        }).toList(),
        (m['shared'] as num?)?.toInt() ?? 0,
      );
}
