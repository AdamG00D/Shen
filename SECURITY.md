**English** | [العربية](SECURITY.ar.md)

# Security

## Reporting a vulnerability

**Please don't open a public issue.** Use GitHub's private reporting: the repository's **Security** tab →
**Report a vulnerability**. Include what the problem is, how to reproduce it and its impact. We'll reply as soon as we
can and, if you like, credit you in the release notes. You may encrypt details to the release key
([docs/shen-release-key.asc](docs/shen-release-key.asc), `B2D4 53B8 5430 D721 C173 3C1F B0E8 ADA6 3BD7 84BC`).

## What Shen protects against

| Threat | Protection |
|---|---|
| Someone copies the app's files (backup tool, forensic image, malware without root) | Everything is AES-256-GCM encrypted; the master key needs **both** the master password (Argon2id, 64 MiB) **and** a non-exportable Android Keystore key (StrongBox when available, usable only while the device is unlocked) |
| Guessing the master password on the phone | 4 free attempts, then waits of 30 s doubling up to 15 min |
| A stolen secret key file (e.g. an exported `.asc` or a backup) | Secret keys stay encrypted with their own passphrase; backups are additionally encrypted with an Argon2 + AES-256-OCB password message |
| Someone with the unlocked phone in their hands | Auto-lock when leaving the app; the master password is asked again to export a secret key, save the revocation certificate, delete keys / profiles or wipe; key passphrases are asked for every use unless you enable the short in-memory cache |
| A profile you want kept apart (e.g. work) | Its own data key, optionally its own password; while locked its data isn't even in memory |
| Swapping files between profiles or tampering with them | Every file is authenticated with an AAD naming the file and its profile |
| Tampered or forged messages | Integrity-protected decryption only (MDC / AEAD); partial output is deleted on failure; signatures are checked with PGPainless's policy (no SHA-1, no weak algorithms) |
| Malicious keys, messages, QR codes or backups | Size limits, decompression-bomb limits, every library error mapped to "bad data" — tested with hostile input |
| Screenshots, the recent-apps preview, screen recording | `FLAG_SECURE` |
| Copied secrets lingering | Copies are marked sensitive (hidden from clipboard previews) and cleared after 20–90 s |
| Leaks through Android backups or device transfer | Disabled (`allowBackup=false`, data-extraction rules, data under `noBackupFilesDir`) |
| Network leaks | There is no INTERNET permission; the release build script fails if one appears |
| A fake download | Releases come with `SHA256SUMS.txt` signed by the release key |

## Known limitations — please read

1. **A compromised or rooted phone.** Malware with root, or a modified OS, can read the screen, the keyboard and the
   app's memory. No app can protect you there.
2. **The keyboard sees what you type.** Shen turns off suggestions and learning for passwords and messages, but the
   keyboard app still receives the keystrokes. Use a keyboard you trust.
3. **Text in memory.** Passphrases you type and decrypted text you display pass through Dart strings, which can't be
   wiped explicitly; they disappear when the memory is reused. The Kotlin core wipes the keys it handles.
4. **Weak master password + weak device.** On phones whose Keystore is not hardware-backed (rare today), someone with a
   full copy of the phone's storage could try to guess the master password offline. Argon2id makes that slow, not
   impossible: choose a long password. The attempt counter is stored in the app's files, so it slows down guessing
   in the app, not an attacker who already has root.
5. **Fingerprint unlock** is convenient but weaker against coercion or a sleeping owner. It stays bound to this
   phone's fingerprints: enrolling a new fingerprint turns it off.
6. **Trust is simple.** "Verified" means *you* checked the fingerprint. Certifications made by other people are kept in
   the key but Shen doesn't compute a Web of Trust from them.
7. **No automatic updates of other people's keys.** Without internet, new expiry dates and revocations only arrive when
   you import the updated key. Re-import keys you rely on from time to time.
8. **OpenPGP metadata.** As in any OpenPGP message, the key ids of the recipients are visible to anyone who sees the
   encrypted message; the original file name travels inside the encryption.
9. **No forward secrecy.** Whoever gets a secret key and its passphrase can decrypt every past message sent to it —
   that's how OpenPGP works.
10. **QR verification trusts the screen you scan.** Scan the QR code from the person's own phone, in person.
11. **Shared contacts** are protected by the master key only (they are visible in every profile by design); a
    profile's own password doesn't cover them.
12. **No external audit of Shen yet.** PGPainless was audited by Cure53 (2021) and Bouncy Castle is widely reviewed,
    but Shen's own code hasn't been audited. The code is open so anyone can review it.
