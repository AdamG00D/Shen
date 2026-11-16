# Shen backup format (version 1)

A Shen backup (`*.shen`) is a standard **OpenPGP message encrypted with a password** (RFC 9580):

- SKESK v6 with an **Argon2** S2K (Bouncy Castle `memoryConstrainedParameters`: 64 MiB, 3 passes, 4 lanes)
- SEIPD v2 with **AES-256 / OCB** (authenticated: any change to the file makes decryption fail)
- binary (not armored), no compression

So a backup can be opened without Shen, for example with Sequoia PGP:

```bash
sq decrypt --password-file pw.txt backup.shen > backup.json
```

(GnuPG 2.4 does not implement RFC 9580 messages yet.)

## Content

The decrypted content is UTF-8 JSON:

```json
{
  "format": "shen-backup",
  "version": 1,
  "created": 1794000000000,
  "scope": "all",
  "profiles": [
    {
      "name": "Personal",
      "color": 0,
      "default": "FINGERPRINT-OF-THE-DEFAULT-KEY",
      "keys": [
        {
          "key": "-----BEGIN PGP PRIVATE KEY BLOCK----- ...",
          "rev": "-----BEGIN PGP PUBLIC KEY BLOCK----- ... (revocation certificate) or null",
          "note": "",
          "added": 1794000000000
        }
      ],
      "contacts": [
        { "cert": "-----BEGIN PGP PUBLIC KEY BLOCK----- ...", "verified": true, "note": "", "added": 1794000000000 }
      ]
    }
  ],
  "shared": [
    { "cert": "-----BEGIN PGP PUBLIC KEY BLOCK----- ...", "verified": false, "note": "", "added": 1794000000000 }
  ]
}
```

| Field | Meaning |
|---|---|
| `scope` | `all` (every unlocked profile + `shared`) or `profile` (one profile, no `shared`) |
| `profiles[].keys[].key` | the secret key, ASCII-armored, **still protected by its own passphrase** |
| `profiles[].keys[].rev` | the revocation certificate made when the key was created (a revoked copy of the public key) |
| `profiles[].contacts` | public keys that are visible in this profile only |
| `shared` | public keys that are visible in every profile |
| `verified` | the user verified the fingerprint with the key's owner |
| `created`, `added` | milliseconds since the Unix epoch |

Profile passwords are **not** part of a backup: restored profiles have no own password until you set one.

## Restoring

Restoring merges, it never deletes: each profile goes into the profile with the same name (or a new one); keys and
contacts that already exist are merged with `PGPainless.mergeCertificate` (new user ids, expiry changes,
revocations), never replaced. A profile with the same name that is locked must be unlocked first.

Readers must reject a file whose `format` is not `shen-backup` or whose `version` is newer than they understand.
