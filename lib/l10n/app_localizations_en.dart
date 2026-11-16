// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Shen';

  @override
  String get tagline => 'Your PGP keys, kept safe — no internet needed.';

  @override
  String get errUnknown => 'Something went wrong. Please try again.';

  @override
  String get errWrongPassword => 'Wrong password.';

  @override
  String get errLockedOut => 'Too many wrong attempts.';

  @override
  String get errLocked => 'Shen is locked. Unlock it again.';

  @override
  String get errProfileLocked =>
      'This profile is locked with a password. Unlock it first.';

  @override
  String errProfileLockedNamed(String name) {
    return 'Unlock the profile “$name” first, then try again.';
  }

  @override
  String get errKeystore =>
      'The device key is missing (the data may come from another phone). This data can\'t be opened on this phone.';

  @override
  String get errBadData => 'This isn\'t valid OpenPGP data, or it\'s damaged.';

  @override
  String get errIntegrity =>
      'This message was tampered with or is damaged — it was rejected and nothing was saved.';

  @override
  String get errNoKey => 'None of your keys can decrypt this message.';

  @override
  String get errCannotEncrypt =>
      'One of the recipients\' keys is expired, revoked or can\'t encrypt.';

  @override
  String get errCannotSign => 'This key can\'t sign (expired or revoked).';

  @override
  String get errNotFound => 'Not found.';

  @override
  String get errExists => 'Already exists.';

  @override
  String get errTooLarge => 'This is too large.';

  @override
  String get errInvalid => 'Some of the input is missing or invalid.';

  @override
  String get errEncryptedNotSigned =>
      'This message is encrypted — use “Decrypt / verify”.';

  @override
  String get errNotBackup => 'This file isn\'t a Shen backup.';

  @override
  String get errCancelled => 'Cancelled.';

  @override
  String get errIo => 'Couldn\'t read or write the file.';

  @override
  String get errBioInvalidated =>
      'The fingerprints on this phone changed, so fingerprint unlock was turned off. Unlock with your password and turn it on again.';

  @override
  String get errBioUnavailable => 'Fingerprint unlock isn\'t turned on.';

  @override
  String tryAgainIn(String time) {
    return 'Try again in $time.';
  }

  @override
  String seconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String minutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get save => 'Save';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get close => 'Close';

  @override
  String get share => 'Share';

  @override
  String get saveFile => 'Save as file';

  @override
  String get saved => 'Saved';

  @override
  String get search => 'Search';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete';

  @override
  String get deleted => 'Deleted';

  @override
  String get add => 'Add';

  @override
  String get paste => 'Paste';

  @override
  String get clear => 'Clear';

  @override
  String get open => 'Open';

  @override
  String get create => 'Create';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get current => 'Current';

  @override
  String get iUnderstand => 'I understand';

  @override
  String copiedSecure(int count) {
    return 'Copied — it will be cleared from the clipboard in $count seconds';
  }

  @override
  String get showQr => 'Show QR';

  @override
  String get invalid => 'invalid';

  @override
  String get strengthVeryWeak => 'Very weak';

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthOk => 'Fair';

  @override
  String get strengthGood => 'Good';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get keyPassphraseTitle => 'Key passphrase';

  @override
  String keyPassphraseFor(String name) {
    return 'Enter the passphrase for:\n$name';
  }

  @override
  String get keyPassphrase => 'Key passphrase';

  @override
  String get masterPasswordTitle => 'Master password';

  @override
  String get masterPassword => 'Master password';

  @override
  String passwordTooShort(int count) {
    return 'The password must be at least $count characters.';
  }

  @override
  String get passwordsDontMatch => 'The passwords don\'t match.';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Repeat it to confirm';

  @override
  String get revoked => 'Revoked';

  @override
  String get expired => 'Expired';

  @override
  String get expiresSoon => 'Expires soon';

  @override
  String get defaultKey => 'Default';

  @override
  String get noPassphrase => 'No passphrase';

  @override
  String get verified => 'Verified';

  @override
  String get allProfiles => 'All profiles';

  @override
  String sigGoodVerified(String name) {
    return 'Good signature from $name';
  }

  @override
  String get sigByMe => 'This was signed with one of your own keys.';

  @override
  String get sigGoodVerifiedBody =>
      'The message is unchanged, and you have verified that this key belongs to this person.';

  @override
  String sigGoodUnverified(String name) {
    return 'Good signature from $name — but the key isn\'t verified';
  }

  @override
  String get sigGoodUnverifiedBody =>
      'The message is unchanged, but you haven\'t verified that this key really belongs to this person. Compare the fingerprint with them (in person or by QR).';

  @override
  String get sigUnknown => 'Signed with a key you don\'t have';

  @override
  String sigUnknownBody(String keyId) {
    return 'The signature can\'t be checked until you add the sender\'s public key ($keyId).';
  }

  @override
  String get sigBad => 'Bad signature!';

  @override
  String get sigBadBody =>
      'The message was changed after it was signed, or the signature is forged. Don\'t trust this content.';

  @override
  String signedOn(String date) {
    return 'Signed on $date';
  }

  @override
  String get notSigned =>
      'This message isn\'t signed — there\'s no way to know who sent it.';

  @override
  String get noRecipients =>
      'No contacts you can encrypt to. Add people\'s keys under “Contacts”.';

  @override
  String get contacts => 'Contacts';

  @override
  String get myKeys => 'My keys';

  @override
  String hiddenUnusable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keys are hidden because they are expired or revoked.',
      one: '1 key is hidden because it is expired or revoked.',
    );
    return '$_temp0';
  }

  @override
  String selectedCount(int count) {
    return 'Done ($count)';
  }

  @override
  String get chooseSigningKey => 'Choose the key to sign with';

  @override
  String get defaultProfileName => 'Personal';

  @override
  String get nameRequired => 'Enter a name.';

  @override
  String get introOffline =>
      'Everything stays on your phone: no internet, no account, no server.';

  @override
  String get introProfiles =>
      'Separate profiles (personal, work...), each with its own keys and contacts.';

  @override
  String get introStandard =>
      'Standard OpenPGP: works with Kleopatra, gpg, Thunderbird and any other OpenPGP app.';

  @override
  String get setupTitle => 'Let\'s get started';

  @override
  String get firstProfileName => 'Name of your first profile';

  @override
  String get masterPasswordWarning =>
      'The master password locks the whole app. If you forget it there is no way to recover your data — choose something you will remember, and make a backup from Settings.';

  @override
  String get createVault => 'Create';

  @override
  String get bioTitle => 'Unlock Shen';

  @override
  String get bioSubtitle => 'Your fingerprint unlocks the vault key';

  @override
  String get usePassword => 'Use password';

  @override
  String get locked => 'Shen is locked';

  @override
  String get lockedHint => 'Enter your master password to unlock.';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockWithBio => 'Unlock with fingerprint';

  @override
  String get lockNow => 'Lock now';

  @override
  String get tools => 'Tools';

  @override
  String get settings => 'Settings';

  @override
  String profileLockedTitle(String name) {
    return 'The profile “$name” is locked';
  }

  @override
  String get profileLockedBody =>
      'This profile has its own password. Unlock it to see its keys and contacts.';

  @override
  String unlockProfile(String name) {
    return 'Unlock “$name”';
  }

  @override
  String get profilePassword => 'Profile password';

  @override
  String get profiles => 'Profiles';

  @override
  String profileCounts(int keys, int contacts) {
    String _temp0 = intl.Intl.pluralLogic(
      keys,
      locale: localeName,
      other: '$keys keys',
      one: '1 key',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contacts,
      locale: localeName,
      other: '$contacts contacts',
      one: '1 contact',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get profileLockedShort => 'Locked';

  @override
  String get manageProfiles => 'Manage profiles';

  @override
  String get newKey => 'New key';

  @override
  String get noKeysTitle => 'No keys yet';

  @override
  String get noKeysBody =>
      'Create a key so people can send you encrypted messages and check your signature, or import one you already have.';

  @override
  String get importKey => 'Import a key';

  @override
  String myKeysCount(int count) {
    return 'My keys ($count)';
  }

  @override
  String get nameOrEmailRequired => 'Enter at least a name or an email.';

  @override
  String get invalidEmail => 'This email doesn\'t look right.';

  @override
  String get invalidCharacters => 'Don\'t use < > ( ) in the name or comment.';

  @override
  String get keyCreatedTitle => 'Your key is ready';

  @override
  String get keyCreatedBody =>
      'Next:\n• Share your public key so people can encrypt to you.\n• Make a backup (Settings → Backup) in case you lose your phone.\n• A revocation certificate was created automatically — keep it somewhere safe.';

  @override
  String get newKeyIntro =>
      'A key has two parts: a public part you give to people, and a secret part that stays on your phone, protected by a passphrase.';

  @override
  String get name => 'Name';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get commentOptional => 'Comment (optional)';

  @override
  String get commentHelp => 'For example: work — shown next to your name';

  @override
  String get keyPassphraseHelp =>
      'Protects the secret part even if someone copies it. You\'ll need it to decrypt and sign.';

  @override
  String get noPassphraseOption => 'No passphrase';

  @override
  String get noPassphraseWarning =>
      'Not recommended: anyone with a copy of the key can use it.';

  @override
  String get expiry => 'Expiry';

  @override
  String get never => 'Never';

  @override
  String yearsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get expiryHelp =>
      'If you ever lose the key, the expiry makes it stop working on its own. You can extend it any time.';

  @override
  String get advanced => 'Advanced';

  @override
  String get algoCv25519 => 'Ed25519 / X25519 (recommended)';

  @override
  String get algoCv25519Help =>
      'Modern and fast, works with gpg, Kleopatra and everything else.';

  @override
  String get algoRsa => 'RSA 4096';

  @override
  String get algoRsaHelp =>
      'For old systems that don\'t support Ed25519. Slower and larger.';

  @override
  String get algoV6 => 'OpenPGP v6 (RFC 9580)';

  @override
  String get algoV6Help =>
      'The newest format. gpg and Kleopatra don\'t support it yet.';

  @override
  String get createKey => 'Create key';

  @override
  String get rsaSlow => 'RSA keys take a while... please wait.';

  @override
  String get sharePublicKey => 'Share public key';

  @override
  String get showAsQr => 'Show as QR';

  @override
  String get showAsQrHelp => 'The person in front of you scans it with Shen';

  @override
  String get qrKeyCaption =>
      'This is your full public key. Whoever scans it with Shen adds you and marks you as verified.';

  @override
  String get changeExpiry => 'Change expiry';

  @override
  String yearsFromNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years from today',
      one: '1 year from today',
    );
    return '$_temp0';
  }

  @override
  String get updatedShareAgain =>
      'Updated — share your public key again so people get the change.';

  @override
  String get changeKeyPassphrase => 'Change key passphrase';

  @override
  String get changeKeyPassphraseBody =>
      'The new passphrase protects the secret part of the key.';

  @override
  String get passphraseChanged => 'Passphrase changed';

  @override
  String get addIdentity => 'Add identity (name / email)';

  @override
  String get identityHint => 'Name <email@example.com>';

  @override
  String get exportSecretTitle => 'Export secret key';

  @override
  String get exportSecretBody =>
      'This is the part nobody but you should ever see. Even though it\'s protected by its passphrase, only store it somewhere safe (like a USB stick you keep) and never send it to anyone.';

  @override
  String get masterPasswordForExport => 'Enter your master password to export.';

  @override
  String get revocationCert => 'Revocation certificate';

  @override
  String get revocationCertBody =>
      'If your key is stolen or lost, this certificate tells people it\'s revoked — even if you no longer have the key. Keep it somewhere safe off the phone (anyone who has it can revoke your key).';

  @override
  String get revokeTitle => 'Revoke key';

  @override
  String get revokeBody =>
      'After revoking, nobody can encrypt to this key any more, and it can\'t be undone. Share your public key afterwards so people find out.';

  @override
  String get revoke => 'Revoke key';

  @override
  String get revokeReason => 'Why are you revoking it?';

  @override
  String get reasonCompromised => 'It was stolen or exposed';

  @override
  String get reasonSuperseded => 'I made a new key to replace it';

  @override
  String get reasonRetired => 'I no longer use it';

  @override
  String get reasonNone => 'No reason';

  @override
  String get revokedShareNow =>
      'The key is revoked — share your public key now so people know.';

  @override
  String get deleteKeyTitle => 'Delete key';

  @override
  String get deleteKeyBody =>
      'The secret key will be erased from this phone. Without a backup, every message encrypted to it will be lost forever.';

  @override
  String get masterPasswordForDelete => 'Enter your master password to delete.';

  @override
  String get note => 'Note';

  @override
  String get keyDetails => 'Key';

  @override
  String get keyRevokedNotice =>
      'This key is revoked. Nobody can encrypt to it and it can\'t sign, but you can still decrypt old messages with it.';

  @override
  String get keyExpiredNotice =>
      'This key has expired. Extend it with “Change expiry” and share your public key again.';

  @override
  String get fingerprint => 'Fingerprint';

  @override
  String get qrFingerprintCaption =>
      'The person in front of you scans this with Shen to confirm that the key they have is yours.';

  @override
  String get manage => 'Manage';

  @override
  String get makeDefault => 'Make default';

  @override
  String get makeDefaultHelp =>
      'Used to sign and to encrypt to yourself by default';

  @override
  String get backupAndSafety => 'Backup and safety';

  @override
  String get exportSecret => 'Export secret key';

  @override
  String get exportSecretHelp =>
      'An .asc file to move the key to Kleopatra or another device';

  @override
  String get revocationCertHelp =>
      'Keep it off the phone in case the key is stolen';

  @override
  String get revokeHelp => 'If the key was stolen or you stopped using it';

  @override
  String get deleteKey => 'Delete key';

  @override
  String get flagCertify => 'certify';

  @override
  String get flagSign => 'sign';

  @override
  String get flagEncrypt => 'encrypt';

  @override
  String get flagAuth => 'auth';

  @override
  String get details => 'Details';

  @override
  String get algorithm => 'Algorithm';

  @override
  String get created => 'Created';

  @override
  String get expires => 'Expires';

  @override
  String get keyIdLabel => 'Key ID';

  @override
  String get version => 'Version';

  @override
  String get identities => 'Identities';

  @override
  String get subkeys => 'Subkeys';

  @override
  String get fromClipboard => 'From clipboard';

  @override
  String get pasteText => 'Paste text';

  @override
  String get fromFile => 'From a file';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get scanQrHelp =>
      'A public key or fingerprint from the other person\'s phone';

  @override
  String get clipboardEmpty => 'The clipboard is empty.';

  @override
  String get pasteKeyHere => 'Paste the key here (-----BEGIN PGP...)';

  @override
  String get qrNotKey => 'This QR code isn\'t a key or a fingerprint.';

  @override
  String get fingerprintUnknownTitle => 'You don\'t have this key';

  @override
  String fingerprintUnknownBody(String fp) {
    return 'Fingerprint:\n$fp\n\nAdd this person\'s public key first (a file or their full-key QR), then scan the fingerprint again to verify.';
  }

  @override
  String get thisIsYourKey => 'This is one of your own keys.';

  @override
  String get verifiedTitle => 'Verified';

  @override
  String get verifiedByQr =>
      'The fingerprint you scanned matches the key you have, so this contact is now marked as verified.';

  @override
  String importDone(int added, int updated) {
    return '$added added, $updated updated';
  }

  @override
  String get importKeysTitle => 'Import keys';

  @override
  String importFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count keys.',
      one: 'Found 1 key.',
    );
    return '$_temp0 Choose what to add:';
  }

  @override
  String get alreadyHaveUpdate =>
      'You already have it — it will only be updated (nothing is removed)';

  @override
  String get secretGoesToMyKeys =>
      'Secret keys are added to “My keys” in this profile.';

  @override
  String get whereToShow => 'Where it shows';

  @override
  String thisProfileOnly(String name) {
    return 'Only in “$name”';
  }

  @override
  String get thisProfileOnlyHelp => 'Not visible in your other profiles';

  @override
  String get allProfilesHelp => 'Visible in every profile';

  @override
  String get importQrVerified =>
      'The key came by QR from the person\'s own phone, so it will be marked as verified.';

  @override
  String get verifyAfterImport =>
      'After importing, compare the fingerprint with the key\'s owner (or scan their QR) to make sure it\'s really theirs.';

  @override
  String get addContact => 'Add contact';

  @override
  String get noContactsTitle => 'No contacts';

  @override
  String get noContactsBody =>
      'Add someone\'s public key to encrypt messages to them and check their signatures.';

  @override
  String get searchContacts => 'Search by name, email or fingerprint';

  @override
  String contactsCount(int count) {
    return 'Contacts ($count)';
  }

  @override
  String get compareTitle => 'Compare the fingerprint';

  @override
  String compareBody(String fp) {
    return 'Ask the person to read their fingerprint from their own device (in person or on a call) and compare every character:\n\n$fp';
  }

  @override
  String get theyMatch => 'They match';

  @override
  String get markedVerified => 'Marked as verified';

  @override
  String get needOwnKey => 'You need a key of your own first (in My keys)';

  @override
  String get certifyTitle => 'Certify this key';

  @override
  String get certifyBody =>
      'You\'ll sign with your key that you\'re sure this key belongs to this person. If you share it later, people who trust you will see that you checked it. Only do this if you compared the fingerprint yourself.';

  @override
  String get certify => 'Certify';

  @override
  String get certified => 'Key certified';

  @override
  String get deleteContactTitle => 'Delete contact';

  @override
  String get deleteContactBody =>
      'Their public key will be removed from this profile.';

  @override
  String get deleteContactSharedBody =>
      'This contact is shown in every profile — it will be removed from all of them.';

  @override
  String get contact => 'Contact';

  @override
  String get contactVerified => 'You verified this key';

  @override
  String get contactNotVerified => 'This key isn\'t verified yet';

  @override
  String get contactVerifiedBody =>
      'You compared the fingerprint with its owner. Signatures made with this key show in green.';

  @override
  String get contactNotVerifiedBody =>
      'Anyone can create a key with anyone\'s name. Before you trust it, check the fingerprint with its real owner.';

  @override
  String get scanTheirQr => 'Scan their QR';

  @override
  String get compareManually => 'I compared the fingerprint';

  @override
  String get certifyWithMyKey => 'Certify with my key';

  @override
  String get unmarkVerified => 'Remove “verified”';

  @override
  String get showInAllProfiles => 'Show in all profiles';

  @override
  String get updateKey => 'Update key';

  @override
  String get updateKeyHelp =>
      'If the owner sent you a newer copy (new expiry / revocation)';

  @override
  String get deleteContact => 'Delete contact';

  @override
  String get messagePasswordTitle => 'Message password';

  @override
  String get messagePasswordBody =>
      'This message is encrypted with a password (not a key).';

  @override
  String get messagePassword => 'Password';

  @override
  String get otherProfileTitle => 'This message is for another profile';

  @override
  String otherProfileBody(String name) {
    return 'This message is encrypted to a key in the profile “$name”. Switch profiles at the top and try again.';
  }

  @override
  String get notForYouTitle => 'This message isn\'t for you';

  @override
  String get notForYouHidden =>
      'The sender hid the key IDs, and none of your keys could decrypt it.';

  @override
  String notForYouBody(String ids) {
    return 'It is encrypted to keys you don\'t have:\n$ids';
  }

  @override
  String get toPeople => 'To people';

  @override
  String get withPassword => 'With a password';

  @override
  String get passwordModeHelp =>
      'Anyone with the password can decrypt — even without Shen (gpg / Kleopatra). Send the password some other way than the message itself.';

  @override
  String get recipients => 'Recipients';

  @override
  String get noRecipientsChosen => 'Choose at least one recipient.';

  @override
  String get unverifiedRecipientWarning =>
      'One recipient\'s key isn\'t verified — if it\'s not really theirs, someone else could read the message.';

  @override
  String get encryptToSelf => 'Also encrypt to myself';

  @override
  String get encryptToSelfHelp => 'So you can read what you sent later';

  @override
  String get signMessage => 'Sign';

  @override
  String get signMessageHelp =>
      'The recipient can check that it\'s from you and unchanged';

  @override
  String get needSigningKey =>
      'You need a key of your own that can sign (in My keys)';

  @override
  String signingAs(String name) {
    return 'Signing as $name';
  }

  @override
  String get changeSigningKey => 'Change signing key';

  @override
  String get newMessagePasswordBody =>
      'Choose a strong password and give it to the recipient some other way.';

  @override
  String get writeSomething => 'Write something first.';

  @override
  String get encryptedMessage => 'Encrypted message';

  @override
  String get encryptedMessageHelp =>
      'Send it any way you like (chat, email...). Only the recipients can read it.';

  @override
  String get encryptText => 'Encrypt text';

  @override
  String get writeMessage => 'Write your message here';

  @override
  String get encrypt => 'Encrypt';

  @override
  String get pasteSomething => 'Paste a message or signature first.';

  @override
  String get detachedNeedsText =>
      'This is a detached signature: paste the original text in the new field and try again.';

  @override
  String get notPgpText => 'This text isn\'t an OpenPGP message.';

  @override
  String get decryptVerify => 'Decrypt / verify';

  @override
  String get decryptVerifyHelp =>
      'Paste an encrypted message, a signed message or a public key — Shen works out what to do.';

  @override
  String get pasteMessage => '-----BEGIN PGP MESSAGE-----';

  @override
  String get signedTextLabel => 'Original text';

  @override
  String get signedTextHint => 'Paste the text that was signed';

  @override
  String get signature => 'Signature';

  @override
  String get decryptedText => 'Message';

  @override
  String get signedContent => 'Content';

  @override
  String get signedMessage => 'Signed text';

  @override
  String get signText => 'Sign text';

  @override
  String get signingKey => 'Signing key';

  @override
  String get detachedSignature => 'Detached signature';

  @override
  String get detachedSignatureHelp =>
      'Only the signature, without the text (like .sig files)';

  @override
  String get sign => 'Sign';

  @override
  String get chooseFileFirst => 'Choose a file first.';

  @override
  String get fileIsSignedOnly =>
      'This file is only signed (not encrypted) — use “Verify a file”.';

  @override
  String get fileNotEncrypted => 'This file isn\'t OpenPGP-encrypted.';

  @override
  String get chooseSignatureFile => 'Choose the signature file (.sig / .asc).';

  @override
  String get encryptFile => 'Encrypt a file';

  @override
  String get encryptFileHelp =>
      'Any type and size. The encrypted file is saved where you choose.';

  @override
  String get decryptFile => 'Decrypt a file';

  @override
  String get decryptFileHelp =>
      'A .pgp / .gpg / .asc file. If it was tampered with, anything written is deleted automatically.';

  @override
  String get decrypt => 'Decrypt';

  @override
  String get signFile => 'Sign a file';

  @override
  String get signFileHelp =>
      'Creates a separate signature file (.sig) to send alongside the file.';

  @override
  String get verifyFile => 'Verify a file';

  @override
  String get verifyFileHelp =>
      'Choose the file and its signature. If the file is signed inside itself, leave the signature empty.';

  @override
  String get verify => 'Verify';

  @override
  String get chooseFile => 'Choose a file';

  @override
  String get chooseSignatureFileOptional => 'Signature file (.sig) — optional';

  @override
  String get asciiArmor => 'Text (ASCII armor)';

  @override
  String get asciiArmorHelp =>
      'A text .asc file instead of .pgp — a bit larger but can be sent as text';

  @override
  String savedAs(String name) {
    return 'Saved: $name';
  }

  @override
  String get text => 'Text';

  @override
  String get encryptTextHelp => 'A message only the people you choose can read';

  @override
  String get decryptVerifyShort => 'Open a message or check a signature';

  @override
  String get signTextHelp => 'Let people check that these words are from you';

  @override
  String get files => 'Files';

  @override
  String get encryptFileShort => 'Photos, documents, anything';

  @override
  String get decryptFileShort => '.pgp / .gpg / .asc';

  @override
  String get signFileShort => 'A .sig signature file';

  @override
  String get verifyFileShort => 'Check a file is unchanged and who signed it';

  @override
  String get newProfile => 'New profile';

  @override
  String get profilesHelp =>
      'Each profile has its own keys and contacts (personal, work...). Contacts stay in their profile unless you choose to show them in all profiles.';

  @override
  String get hasOwnPassword => 'Own password';

  @override
  String get profilePasswordHelp =>
      'An extra layer: the profile stays locked until you enter its password, even while the app is open.';

  @override
  String get profileCreated => 'Profile created';

  @override
  String get switchTo => 'Switch to it';

  @override
  String get renameProfile => 'Name and color';

  @override
  String get changeProfilePassword => 'Change profile password';

  @override
  String get setProfilePassword => 'Set a profile password';

  @override
  String get removeProfilePassword => 'Remove profile password';

  @override
  String get lockProfileNow => 'Lock this profile now';

  @override
  String get deleteProfile => 'Delete profile';

  @override
  String deleteProfileTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteProfileBody =>
      'All secret keys and contacts in this profile will be erased permanently. Make a backup first.';

  @override
  String get profileName => 'Profile name';

  @override
  String get profileNameHint => 'Personal, Work, University...';

  @override
  String get protectWithPassword => 'Its own password';

  @override
  String get backupPassword => 'Backup password';

  @override
  String get backupPasswordHelp =>
      'The backup is encrypted with it. Without it there\'s no way to open the backup — write it down somewhere safe.';

  @override
  String get backupDoneTitle => 'Backup saved';

  @override
  String backupDoneBody(int profiles, int keys, int contacts) {
    return 'Profiles: $profiles\nKeys: $keys\nContacts: $contacts\n\nKeep it somewhere off the phone (a computer, a USB stick).';
  }

  @override
  String backupSkipped(String names) {
    return 'These locked profiles were not included (unlock them and try again): $names';
  }

  @override
  String get restoreTitle => 'Restore this backup?';

  @override
  String backupFrom(String date) {
    return 'Backup from $date';
  }

  @override
  String get willMerge => 'merged into the profile with the same name';

  @override
  String get willCreate => 'new profile';

  @override
  String sharedContactsCount(int count) {
    return 'Contacts for all profiles: $count';
  }

  @override
  String get restoreNothingDeleted =>
      'Nothing you have is deleted: new keys are added and existing ones are only updated.';

  @override
  String get restore => 'Restore';

  @override
  String get backup => 'Backup';

  @override
  String get backupIntro =>
      'A backup is a .shen file encrypted with a password you choose (OpenPGP: Argon2 + AES-256). The secret keys inside stay protected by their own passphrases too. You can restore it on any phone.';

  @override
  String get exportSection => 'Export';

  @override
  String get backupEverything => 'Back up everything';

  @override
  String get backupEverythingHelp => 'All unlocked profiles + shared contacts';

  @override
  String backupThisProfile(String name) {
    return 'Back up “$name” only';
  }

  @override
  String get backupThisProfileHelp => 'Only this profile\'s keys and contacts';

  @override
  String get importSection => 'Restore';

  @override
  String get restoreBackup => 'Restore a backup';

  @override
  String get restoreBackupHelp => 'From a .shen file';

  @override
  String get backupFormatNote =>
      'The format is open and documented: you can decrypt a backup without Shen using sq decrypt (Sequoia PGP). Public keys can also be exported on their own as .asc files from each key\'s page.';

  @override
  String get immediately => 'Immediately';

  @override
  String get bioEnableTitle => 'Turn on fingerprint unlock';

  @override
  String get bioEnabled => 'Fingerprint unlock is on';

  @override
  String get currentMasterPassword => 'Enter your current master password.';

  @override
  String get newMasterPassword => 'New master password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get wipeTitle => 'Erase all data';

  @override
  String get wipeBody =>
      'Every key, profile and contact will be erased from this phone for good. Without a backup they can\'t be recovered.';

  @override
  String get wipe => 'Erase everything';

  @override
  String get masterPasswordForWipe =>
      'Enter your master password to erase everything.';

  @override
  String get security => 'Security';

  @override
  String get bioHelp =>
      'Your fingerprint decrypts the vault key itself (not just a yes/no)';

  @override
  String get autoLock => 'Auto-lock';

  @override
  String autoLockValue(String time) {
    return '$time after you leave the app';
  }

  @override
  String get rememberPassphrase => 'Remember key passphrases';

  @override
  String get rememberPassphraseOff => 'No — asked every time (safest)';

  @override
  String rememberPassphraseOn(int count) {
    return 'In memory only for $count minutes, cleared when the app locks';
  }

  @override
  String get dontRemember => 'Don\'t remember';

  @override
  String get clipboardClear => 'Clear clipboard';

  @override
  String clipboardClearValue(int count) {
    return 'Secret text is cleared after $count seconds';
  }

  @override
  String get changeMasterPassword => 'Change master password';

  @override
  String get data => 'Data';

  @override
  String get profilesShortHelp => 'Personal, work... each with its own keys';

  @override
  String get backupShortHelp => 'Export and restore an encrypted backup';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get followPhone => 'Same as phone';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Open source (GPL-3.0). No internet, no tracking, no ads.';

  @override
  String get sourceCode => 'Source code';

  @override
  String get releaseKey => 'Release signing key fingerprint';

  @override
  String get license => 'License';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get wipeHelp => 'Erases the keys and profiles from this phone';
}
