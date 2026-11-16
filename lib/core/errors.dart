import '../l10n/l10n.dart';
import 'core_api.dart';

/// المستخدم قفل النافذة / لغى العملية — مش خطأ، مبنعرضش حاجة.
class Cancelled implements Exception {
  const Cancelled();
}

/// رسالة مفهومة للمستخدم من أي خطأ. مبنعرضش تفاصيل تقنية.
String errorText(AppLocalizations l, Object e) {
  if (e is! CoreException) return l.errUnknown;
  final base = switch (e.code) {
    'WRONG_PASSWORD' => l.errWrongPassword,
    'LOCKED_OUT' => l.errLockedOut,
    'LOCKED' => l.errLocked,
    'PROFILE_LOCKED' => e.detail != null && e.detail != 'PROFILE_LOCKED' ? l.errProfileLockedNamed(e.detail!) : l.errProfileLocked,
    'KEYSTORE' => l.errKeystore,
    'BAD_DATA' => l.errBadData,
    'INTEGRITY' => l.errIntegrity,
    'NO_KEY' => l.errNoKey,
    'CANNOT_ENCRYPT' => l.errCannotEncrypt,
    'CANNOT_SIGN' => l.errCannotSign,
    'NOT_FOUND' => l.errNotFound,
    'EXISTS' => l.errExists,
    'TOO_LARGE' => l.errTooLarge,
    'INVALID' => e.detail == 'encrypted' ? l.errEncryptedNotSigned : l.errInvalid,
    'NOT_BACKUP' => l.errNotBackup,
    'CANCELLED' => l.errCancelled,
    'IO' => l.errIo,
    'BIO_INVALIDATED' => l.errBioInvalidated,
    'BIO_UNAVAILABLE' => l.errBioUnavailable,
    _ => l.errUnknown,
  };
  if (e.waitMs > 0) return '$base ${l.tryAgainIn(waitText(l, e.waitMs))}';
  return base;
}

String waitText(AppLocalizations l, int ms) {
  final s = (ms / 1000).ceil();
  if (s < 60) return l.seconds(s);
  return l.minutes((s / 60).ceil());
}
