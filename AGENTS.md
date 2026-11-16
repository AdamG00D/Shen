# Shen (شِن) — guide for AI coding agents

Shen is an OpenPGP key manager for Android, in the spirit of Kleopatra (Flutter UI, Arabic + English, RTL / LTR).
People keep their keys in **profiles** (personal, work...), each with its own keys and contacts and an optional own
password; contacts' public keys live in one profile by default and can be shown in all of them. It encrypts, decrypts,
signs and verifies text and files, verifies contacts by QR or by comparing fingerprints, certifies keys and makes
encrypted backups. Package `com.adam.shen`. Open source, **GPL-3.0-or-later** (`LICENSE`). The app has **no INTERNET
permission** — never add network code, analytics or SDKs that need it (online key lookup was decided against, see
`ROADMAP.md`). Android only — no desktop builds.

Human-facing docs come in English + Arabic pairs, keep both in sync: `README.md` is **Arabic** (the main one) with
`README.en.md`; `CONTRIBUTING`, `SECURITY` (threat model + known limits) and `CODE_OF_CONDUCT` are English `X.md` with
Arabic `X.ar.md`; `ROADMAP.md` and `PRIVACY.md` hold both languages. `docs/BACKUP_FORMAT.md` and
`docs/ARCHITECTURE.md` are English only — keep them in sync with the code.

## Working with the owner

- The owner writes in **Egyptian Arabic**. Reply in Egyptian Arabic.
- **Explain the plan first and wait for approval** before implementing anything non-trivial.
- **Never choose names, package ids, colours of the brand or other identity on your own** — propose and ask.
- **Don't build the APK after each step.** Finish every change, run the checks, then build once at the end.
- **Never add AI attribution** (`Co-Authored-By`, "Generated with…") to commits or anything else.
- When a request is ambiguous, ask instead of guessing.

## Commands

```bash
flutter analyze                      # must say "No issues found!"
flutter test                         # l10n parity, logic, UI (fake core)
cd android && ./gradlew :app:testDebugUnitTest   # the real crypto core on the JVM, incl. interop with GnuPG
python3 tool/generate_icon.py        # regenerate the launcher icon (needs Pillow)
./scripts/build_release.sh           # signed + obfuscated → Releases/<ver>v/ (JDK 21 from ~/Downloads/Files/toolchains)
```

The Gradle tests need `flutter pub get` first (Gradle reads the Flutter SDK path from `android/local.properties`).
`GpgInteropTest` is skipped when `gpg` is not installed; CI installs it.

New version: bump `version` in `pubspec.yaml` **and** `AppConfig.appVersion` in `lib/core/config.dart`, and write
`release_notes/<X.Y>v.txt` (Arabic) + `release_notes/<X.Y>v.en.md` (English, with the download table). The build
script refuses to run without both. It builds arm64-v8a / armeabi-v7a / x86_64 / universal APKs with one shared
versionCode, checks that no INTERNET permission slipped in, writes `SHA256SUMS.txt`, signs it with the release OpenPGP
key (`SHA256SUMS.txt.asc`) and prints the `gh release create` command.

Folder layout on disk: `Shen/Shen_App/` (this repo) and `Shen/Signing_Key/` (APK keystore + passwords + the release
OpenPGP key — outside the repo on purpose, never commit or print them). Without the key Gradle signs with the debug key
(so contributors and CI can build); only `build_release.sh` insists on it.

## Architecture (details in `docs/ARCHITECTURE.md`)

**All crypto and storage is in Kotlin** (`android/app/src/main/kotlin/com/adam/shen/core/`, plain JVM code with no
Android imports, so it is unit-tested on the JVM). Dart only shows things and calls `Api.call(method, args)` over the
`shen/core` method channel. Secret material never needs to exist in Dart except the passphrases the user types.

```
android/app/src/main/kotlin/com/adam/shen/
  core/Crypto.kt     Bytes, Aead (AES-256-GCM with AAD), Kdf (Argon2id via Bouncy Castle), KdfParams
  core/Vault.kt      master key = random 32 B, wrapped by Argon2id(master password) AND the device KeyWrapper;
                     encrypted files, attempt throttling, biometric blob
  core/Store.kt      profiles (own data key, optional own password), ProfileData (keys + contacts + default key),
                     shared contacts
  core/Pgp.kt        PGPainless 2.x: generate, parse, summary, encrypt/decrypt, sign/verify, password encryption,
                     edit keys, certify, merge. Maps library exceptions to Err codes only.
  core/Api.kt        the method-channel API, input limits, passphrase cache, Streams interface (files)
  core/Backup.kt     backup bundle (see docs/BACKUP_FORMAT.md)
  core/Errors.kt     Err codes (mirrored in lib/core/errors.dart)
  KeyVault.kt        AndroidKeyWrapper (Keystore AES-GCM, StrongBox / unlocked-device when available), BioUnlock
  CoreChannel.kt     `shen/core`: one background thread, AndroidStreams (SAF content:// URIs)
  SystemChannel.kt   `shen/system`: SAF pickers, small file read/write, share, sensitive clipboard, incoming intents
  QrScanner.kt       ZXing scanner (no Google services)
  MainActivity.kt    FlutterFragmentActivity, FLAG_SECURE
lib/
  main.dart, app.dart        start → Gate (setup / lock / home by Session.phase)
  l10n/                      app_ar.arb (template) + app_en.arb → AppLocalizations; l10n.dart (context.l10n, tr)
  core/                      core_api.dart (typed calls), models.dart, session.dart (state + auto-lock),
                             settings.dart (shared_preferences: language, theme, timeouts), system.dart, errors.dart,
                             config.dart (version, repo, release key fingerprint), theme/app_theme.dart
  features/                  lock/ (setup, lock), home/ (tabs + profile switcher), keys/, contacts/ (incl. import),
                             tools/ (text + file operations, incoming shares), profiles/, backup/, settings/
  widgets/                   ui.dart, feedback.dart (toast, dialogs, action sheet), prompts.dart (busy(), passphrase
                             and password dialogs), key_tile.dart, key_picker.dart, fingerprint.dart (+ QR),
                             signature_card.dart, output_view.dart, password_field.dart, shen_mark.dart
```

## Conventions

- **UI text is localized**: every user-visible string goes in **both** `lib/l10n/app_ar.arb` (template, Egyptian
  Arabic, short and friendly) and `lib/l10n/app_en.arb`; `test/l10n_test.dart` fails if keys or placeholders differ.
  Use `context.l10n.key` in widgets and `tr.key` where there's no context. Language: `AppSettings.language` = null
  (follow the phone: Arabic if the phone is Arabic, otherwise English) / 'ar' / 'en'. Code comments stay in Egyptian
  Arabic.
- Layout flips RTL / LTR — always `EdgeInsetsDirectional` / `AlignmentDirectional`, never fixed left / right.
  Fingerprints, key ids, emails and armored text are always shown LTR.
- **Identity ("stone and seal")**: limestone / basalt grounds, ink for primary buttons (brass in dark mode), brass
  (`palette.accent` / `accentText`) only for marks that matter — the cartouche bar, the selected tab, the default key —
  malachite for verified, carnelian for danger. Hairline borders, 12 px radius, no coloured icon tiles (`IconBadge` is a
  thin ring), statuses are a dot + coloured text (`Chip2`). Names of keys and the profile switcher sit in a `Cartouche`;
  signature results use `Seal`. One fixed identity: there is no accent picker.
- Colours only through `context.palette`. Fonts: IBM Plex Sans Arabic (`Plex`, 400–700) for all text, IBM Plex Mono
  (`AppTheme.monoFamily`) only for fingerprints, key ids and armored text. No display/Kufi font.
- Messages: `showToast` (never `SnackBar`). Dialogs: `confirmDialog` / `infoDialog` / `warnDialog` (dangerous actions,
  needs "I understand"). Bottom sheets: `showActionSheet`. Long work: `busy(context, () async {...})` — it shows the
  spinner, maps errors to text and swallows `Cancelled`.
- Close the keyboard with `hideKeyboard()`, never `FocusScope.of(context).unfocus()`.
- Line width 120. Don't run a formatter over files you aren't otherwise changing.

## Security rules (covered by tests — keep them green)

- **Never log** keys, passphrases, messages or file contents — not in Kotlin, not in Dart. Errors cross the channel as
  `Err` codes; exception messages are never forwarded (`CoreChannel.run`).
- **Vault**: the master key is unusable without both the master password (Argon2id, params stored per vault) and the
  device key (Keystore). Every encrypted file has an AAD naming the file and its profile — files can't be swapped
  between profiles. Writes are atomic (tmp + rename). Throttling: 4 free attempts, then 30 s doubling to 15 min.
- **Profiles**: each profile has its own random data key, wrapped by the master key (and, with an own password, by
  Argon2id of that password inside). A locked profile's data is not in memory.
- **Dangerous actions need the master password again**: exporting a secret key, saving the revocation certificate,
  deleting a key or a profile, wiping everything.
- **Key passphrases** are never stored. The optional in-memory cache (`PassCache`) is off by default and cleared on
  lock.
- **Decryption output**: plaintext is written while decrypting and integrity is checked at the end — on any failure
  the partial output is deleted (`Api.withOutput`). Text results are bounded (`LimitedBuffer`, 16 MiB) against
  decompression bombs; imports are bounded (8 MiB, 2000 certificates).
- **Everything from outside is hostile**: imported keys, messages, QR codes, shared files and backups. Library
  exceptions (incl. `AssertionError`) are mapped to `BAD_DATA`; `ApiTest.hostileInputDoesNotCrash` must keep passing.
- **Interop**: v4 keys advertise SEIPDv1 only (like gpg / Kleopatra keys) so messages sent to them stay readable by
  GnuPG; `GpgInteropTest` checks both directions. Backups use RFC 9580 (SEIPDv2 + Argon2) on purpose.
- Android: `FLAG_SECURE`, `allowBackup=false` + data-extraction rules, data under `noBackupFilesDir`, no INTERNET.

## Pinned dependencies

- Bouncy Castle is pinned to **1.85** in `android/app/build.gradle.kts` (PGPainless 2.0.4 asks for 1.84, which has
  CVE-2026-8763 / CVE-2026-13506). **1.87 breaks v6 encryption** with PGPainless 2.0.4 — `PgpTest` catches it. Upgrade
  BC together with PGPainless and run the JVM tests.

## Don't touch / never commit

- `../Signing_Key/` (keystore, passwords, release OpenPGP key).
- Generated: `lib/l10n/app_localizations*.dart` (from the ARB files), launcher icons from `tool/generate_icon.py`.
