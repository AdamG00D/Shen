**English** | [العربية](CONTRIBUTING.ar.md)

# Contributing to Shen

Thanks for your interest! This guide helps your change get in smoothly.

## Before you start

- Small change (a fix, a UI tweak, a translation)? Open a pull request directly.
- New feature, or anything touching crypto or storage? Open an issue first and describe the idea.
- Security issue? **Not here** — see [SECURITY.md](SECURITY.md).

## Setup

```bash
flutter pub get
flutter analyze                                    # must report: No issues found!
flutter test                                       # UI, l10n and logic tests
(cd android && ./gradlew :app:testDebugUnitTest)   # the crypto core, incl. interop with GnuPG (install gpg)
```

You don't need the signing key: the project builds with the debug key without it.

## Rules

**Code**

- UI text lives in `lib/l10n/app_ar.arb` (Egyptian Arabic, the template) and `lib/l10n/app_en.arb` — add every new
  string to both and use it as `context.l10n.key`. If you can't write Arabic, write the English text and say so in
  the PR — a maintainer will translate. Code comments are in Egyptian Arabic; issues and PRs in English or Arabic are
  both fine.
- The layout flips between RTL and LTR: `EdgeInsetsDirectional` / `AlignmentDirectional`, never fixed left / right.
- Colours only through `context.palette`; messages via `showToast`; long operations via `busy()`.
- Line width 120. Don't reformat files your change doesn't touch.
- Avoid new dependencies — if you add one, explain why and give its license (it must be compatible with GPL-3.0).

**Security (non-negotiable)**

- No internet access: no analytics, crash reporting or network calls. The release build fails if INTERNET appears.
- Never log keys, passphrases, messages or file contents.
- All crypto and storage stays in the Kotlin core (`android/app/src/main/kotlin/com/adam/shen/core/`); Dart only
  calls `Api` methods. Errors cross the channel as codes, never with exception messages.
- Treat every input as hostile (keys, messages, QR codes, files, backups): bound sizes, map every library error to a
  code, add a test.
- Changing the vault layout or the backup format needs a version bump and a migration — see
  [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/BACKUP_FORMAT.md](docs/BACKUP_FORMAT.md).

**Tests**

- Crypto, vault, profiles and the API are tested on the JVM (`android/app/src/test`), including real GnuPG.
- For any bug fix: add a test that fails before the fix and passes after it.

## Pull requests

- Branch from `main`, one clear change per PR. Pull requests are squash-merged.
- Commit message: a short sentence saying what changed, and why below it if it isn't obvious.
- In the PR: what changed, how you tested it, and a screenshot for UI changes (both languages if text changed).
- By contributing you agree that your code is released under the project's license (GPL-3.0-or-later).

## Not sure where to start?

- Try Shen on different phones and report what doesn't work (phone model and Android version matter).
- Translations: a new `lib/l10n/app_<code>.arb`, added to `L10n.supported`, plus
  `android/app/src/main/res/values-<code>/strings.xml`.
- The items in [ROADMAP.md](ROADMAP.md) and the limitations in [SECURITY.md](SECURITY.md).
