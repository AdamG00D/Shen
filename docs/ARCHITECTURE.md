# Architecture and storage

## Layers

```
Flutter (Dart)                       Kotlin
──────────────                       ──────
screens / widgets                    CoreChannel  ── one background thread ──►  core.Api
lib/core/core_api.dart  ── shen/core ─────────►                                   │
lib/core/system.dart    ── shen/system ─► SystemChannel (SAF, share, clipboard)   ├─ core.Vault   (master key, files)
                                         QrScanner (ZXing)                         ├─ core.Store   (profiles, data)
                                         BioUnlock / AndroidKeyWrapper (Keystore)  ├─ core.Pgp     (PGPainless)
                                                                                   └─ core.Backup
```

`core/*` is plain JVM Kotlin (no Android imports): it is tested on the JVM in `android/app/src/test`, including
interoperability with GnuPG.

## What is stored, and how

All files live in `noBackupFilesDir/shen/` (excluded from Android backups; `allowBackup=false` as well).

| File | Content | Encrypted with | AAD |
|---|---|---|---|
| `vault.json` | KDF params + salt, wrapped master key, check value, biometric blob, attempt counter | — (contains no secret in the clear) | — |
| `profiles.bin` | list of profiles: id, name, colour, wrapped data key, own-password KDF params | master key | `shen/profiles/v1` |
| `p/<id>.bin` | the profile's keys (secret keys still passphrase-protected), contacts, default key | profile data key | `shen/profile/v1\|<id>` |
| `shared.bin` | contacts visible in every profile | master key | `shen/shared/v1` |

All encryption is AES-256-GCM with a random 96-bit nonce per write.

### Master key

```
MK          = 32 random bytes
KEK         = Argon2id(NFC(master password), salt, 64 MiB, t=3, p=1)
inner       = AES-GCM(KEK, MK, aad "shen/master-key/v1")
vault.json  "mk" = Keystore-AES-GCM(inner)          # key "shen_vault": StrongBox + unlocked-device when available
            "check" = AES-GCM(MK, "shen-vault-ok")
```

Opening needs the device's Keystore key **and** the master password. Copying the app's files to another device is
useless (`KEYSTORE` error), and brute-forcing the password offline requires extracting the Keystore key first.

Fingerprint unlock (optional) stores `bio = Keystore-AES-GCM_bio(MK)` with a second Keystore key that requires a
Class 3 biometric for every use and is invalidated when a new fingerprint is enrolled. The decrypted MK is checked
against `check` before use.

### Profile data keys

```
DEK_p                = 32 random bytes per profile
without own password: profiles.bin "dek" = AES-GCM(MK, DEK_p, aad "shen/dek/v1|<id>")
with own password:    profiles.bin "dek" = AES-GCM(MK, AES-GCM(Argon2id(pw), DEK_p, aad "shen/profile-dek/v1|<id>"), ...)
```

A profile with its own password is not decrypted when the vault opens; its data is only in memory after the user
enters its password, and is dropped again with "lock profile" or when the vault locks.

## OpenPGP

PGPainless 2.0.x on Bouncy Castle 1.84, with PGPainless's default policy (rejects SHA-1 signatures, weak algorithms,
unauthenticated encryption).

| Thing | Choice |
|---|---|
| New keys (default) | v4, Ed25519 primary (certify) + Ed25519 signing + X25519 encryption subkeys, 2-year expiry, features: SEIPDv1 only |
| Other key types | RSA-4096 v4; v6 Ed25519/X25519 (RFC 9580) |
| Secret key protection | Bouncy Castle / PGPainless secure defaults for S2K |
| Encrypting to people | the strongest mechanism every recipient advertises (SEIPDv1 for gpg-style keys, SEIPDv2 when all support it) |
| Encrypting with a password (messages) | gpg-compatible (SEIPDv1, iterated S2K) so recipients without Shen can open it |
| Backups | RFC 9580: SKESK v6 + Argon2, SEIPDv2 AES-256-OCB (see `BACKUP_FORMAT.md`) |
| Revocation certificate | created with every new key, kept in the vault, exportable |

## Files

Files are never copied into the app: input and output are `content://` URIs from the Storage Access Framework and
are streamed. Decryption writes the output while it reads; if the message turns out to be tampered with (or anything
else fails) the output document is deleted.
