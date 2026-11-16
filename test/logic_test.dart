import 'package:flutter_test/flutter_test.dart';
import 'package:shen/core/models.dart';
import 'package:shen/features/tools/file_screen.dart';
import 'package:shen/widgets/fingerprint.dart';
import 'package:shen/widgets/password_field.dart';

void main() {
  group('UserIdParts', () {
    test('name, comment and email', () {
      final p = UserIdParts.parse('Alice Example (work) <alice@example.org>');
      expect(p.name, 'Alice Example');
      expect(p.comment, 'work');
      expect(p.email, 'alice@example.org');
    });
    test('email only', () {
      expect(UserIdParts.parse('<bob@example.org>').email, 'bob@example.org');
      expect(UserIdParts.parse('bob@example.org').email, 'bob@example.org');
      expect(UserIdParts.parse('bob@example.org').name, '');
    });
    test('arabic name', () {
      final p = UserIdParts.parse('آدم <adam@example.org>');
      expect(p.name, 'آدم');
    });
  });

  group('fingerprints', () {
    const fp = '816FF0364E219EC05C3AA9C70807A23E57FABE91';
    test('format in groups of 4 with a gap in the middle', () {
      expect(formatFingerprint(fp), '816F F036 4E21 9EC0 5C3A   A9C7 0807 A23E 57FA BE91');
    });
    test('QR round trip (OpenKeychain format)', () {
      expect(parseFingerprintQr(fingerprintQr(fp)), fp);
      expect(parseFingerprintQr('openpgp4fpr:${fp.toLowerCase()}'), fp);
      expect(parseFingerprintQr('816F F036 4E21 9EC0 5C3A A9C7 0807 A23E 57FA BE91'), fp);
      expect(parseFingerprintQr('AB' * 32), 'AB' * 32);
    });
    test('rejects things that are not fingerprints', () {
      expect(parseFingerprintQr('https://example.org'), isNull);
      expect(parseFingerprintQr('OPENPGP4FPR:1234'), isNull);
      expect(parseFingerprintQr('Z' * 40), isNull);
    });
  });

  test('password strength grows with length and variety', () {
    expect(passwordStrength(''), 0);
    expect(passwordStrength('12345678'), lessThanOrEqualTo(1));
    expect(passwordStrength('aaaaaaaaaaaa'), lessThanOrEqualTo(1));
    expect(passwordStrength('correct horse battery staple'), greaterThanOrEqualTo(3));
    expect(passwordStrength('Tr0ub4dor&3xY!'), greaterThanOrEqualTo(3));
  });

  test('output file names drop the OpenPGP extension', () {
    expect(stripPgpExt('report.pdf.pgp'), 'report.pdf');
    expect(stripPgpExt('a.GPG'), 'a');
    expect(stripPgpExt('note.txt.asc'), 'note.txt');
    expect(stripPgpExt('photo.jpg'), 'photo.jpg.out');
    expect(stripPgpExt('.pgp'), '.pgp.out');
  });

  test('key models parse what the core sends', () {
    final k = KeyInfo.fromMap({
      'fp': 'AA' * 20,
      'keyId': 'AA' * 8,
      'version': 4,
      'uids': ['Alice <a@b.c>'],
      'primaryUid': 'Alice <a@b.c>',
      'algo': 'Ed25519',
      'created': 0,
      'expires': null,
      'expired': false,
      'revoked': true,
      'secret': false,
      'subkeys': [
        {'fp': 'BB' * 20, 'algo': 'Cv25519', 'created': 0, 'flags': ['ENCRYPT_COMMS'], 'valid': true},
      ],
      'scope': 'shared',
      'verified': true,
    });
    expect(k.label, 'Alice');
    expect(k.email, 'a@b.c');
    expect(k.usable, isFalse);
    expect(k.shared, isTrue);
    expect(k.subkeys.single.flags, ['ENCRYPT_COMMS']);
  });
}
