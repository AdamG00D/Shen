#!/usr/bin/env bash
# بناء نسخة Release موقّعة ومشوّشة وتنظيمها في مجلد Releases (جوه المشروع، برا Git):
#   Releases/<X.Y>v/
#     Shen-<X.Y>-arm64-v8a.apk     أغلب الموبايلات
#     Shen-<X.Y>-armeabi-v7a.apk   الموبايلات القديمة
#     Shen-<X.Y>-x86_64.apk        المحاكي / Chromebook
#     Shen-<X.Y>-universal.apk     أي موبايل (أكبر)
#     SHA256SUMS.txt + SHA256SUMS.txt.asc (موقّع بمفتاح الإصدارات) + Release_Notes.txt + github_release.md
#   Releases/Shen.apk  ← آخر إصدار (النسخة الشاملة)
#
# كل النسخ بنفس رقم الإصدار الداخلي (versionCode): اللي سطّب نسخة يقدر يحدّث بأي نسخة تانية.
set -euo pipefail

cd "$(dirname "$0")/.."

# جافا النظام ممكن متكونش فيها javac — بنستخدم JDK 21 لو موجود
TOOLCHAINS="${TOOLCHAINS:-$HOME/Downloads/Files/toolchains}"
if [ -z "${JAVA_HOME:-}" ] && compgen -G "$TOOLCHAINS/jdk-21*" >/dev/null; then
  JAVA_HOME="$(ls -d "$TOOLCHAINS"/jdk-21* | head -n1)"
  export JAVA_HOME PATH="$JAVA_HOME/bin:$PATH"
fi
[ -d "$TOOLCHAINS/flutter/bin" ] && export PATH="$TOOLCHAINS/flutter/bin:$PATH"
[ -z "${ANDROID_HOME:-}" ] && [ -d "$TOOLCHAINS/android-sdk" ] && export ANDROID_HOME="$TOOLCHAINS/android-sdk"

KEYS=../Signing_Key
if [ ! -f "$KEYS/key.properties" ]; then
  echo "⚠️  مفتاح التوقيع مش موجود في $KEYS — شوف README هناك"
  exit 1
fi
PGP_HOME="$KEYS/release-pgp/gnupg"
PGP_PASS="$KEYS/release-pgp/passphrase.txt"
PGP_FPR="$(cat "$KEYS/release-pgp/fingerprint.txt" 2>/dev/null || true)"
if [ -z "$PGP_FPR" ] || [ ! -d "$PGP_HOME" ] || [ ! -f "$PGP_PASS" ]; then
  echo "⚠️  مفتاح OpenPGP بتاع الإصدارات مش موجود في $KEYS/release-pgp"
  exit 1
fi

# 1.0.0+1 ← 1.0
VERSION=$(grep '^version:' pubspec.yaml | sed -E 's/version: ([0-9]+)\.([0-9]+).*/\1.\2/')
FULL=$(grep '^version:' pubspec.yaml | sed -E 's/version: ([0-9.]+)\+.*/\1/')
if ! grep -q "appVersion = '$FULL'" lib/core/config.dart; then
  echo "⚠️  appVersion في lib/core/config.dart لازم تبقى $FULL (زي pubspec.yaml)"
  exit 1
fi
NOTES="release_notes/${VERSION}v.txt"
NOTES_EN="release_notes/${VERSION}v.en.md"
for f in "$NOTES" "$NOTES_EN"; do
  if [ ! -f "$f" ]; then
    echo "⚠️  اكتب ملاحظات الإصدار الأول في: $f (عربي .txt + إنجليزي .en.md)"
    exit 1
  fi
done

# نقفل Gradle في الآخر مهما حصل عشان ميفضلش ماسك ~2 جيجا رام
trap '(cd android && ./gradlew --stop >/dev/null 2>&1) || true' EXIT

flutter pub get
flutter analyze
flutter test
(cd android && ./gradlew :app:testDebugUnitTest --console=plain -q)

SYMBOLS="build/symbols/${VERSION}"
COMMON=(--release --obfuscate --split-debug-info="$SYMBOLS" -P force-version-code-ignoring-abi=true)
APKS=build/app/outputs/flutter-apk
OUT="Releases/${VERSION}v"
mkdir -p "$OUT"
rm -f "$OUT"/Shen-*.apk "$OUT"/SHA256SUMS.txt "$OUT"/SHA256SUMS.txt.asc

# 1) النسخة الشاملة
flutter build apk "${COMMON[@]}"
cp "$APKS/app-release.apk" "$OUT/Shen-${VERSION}-universal.apk"

# 2) نسخة لكل نوع معالج
flutter build apk "${COMMON[@]}" --split-per-abi
for ABI in arm64-v8a armeabi-v7a x86_64; do
  cp "$APKS/app-${ABI}-release.apk" "$OUT/Shen-${VERSION}-${ABI}.apk"
done

# 3) مفيش صلاحية إنترنت في أي نسخة، والتوقيع بمفتاحنا
AAPT=$(ls "$ANDROID_HOME"/build-tools/*/aapt2 | sort -V | tail -1)
APKSIGNER=$(ls "$ANDROID_HOME"/build-tools/*/apksigner | sort -V | tail -1)
for APK in "$OUT"/Shen-*.apk; do
  if "$AAPT" dump permissions "$APK" | grep -q 'android.permission.INTERNET'; then
    echo "❌ $APK فيه صلاحية INTERNET — في مكتبة ضافتها. الإصدار اتلغى."
    exit 1
  fi
  "$APKSIGNER" verify "$APK"
done
echo "✓ مفيش صلاحية إنترنت، والتوقيع سليم"

cp "$NOTES" "$OUT/Release_Notes.txt"
(cd "$OUT" && sha256sum Shen-*.apk > SHA256SUMS.txt)
# توقيع الـ checksums بمفتاح الإصدارات (docs/shen-release-key.asc)
GNUPGHOME="$PGP_HOME" gpg --batch --yes --pinentry-mode loopback --passphrase-file "$PGP_PASS" \
  --local-user "$PGP_FPR" --armor --detach-sign --output "$OUT/SHA256SUMS.txt.asc" "$OUT/SHA256SUMS.txt"
GNUPGHOME="$PGP_HOME" gpg --batch --verify "$OUT/SHA256SUMS.txt.asc" "$OUT/SHA256SUMS.txt"
GNUPGHOME="$PGP_HOME" gpgconf --kill gpg-agent || true

# ملاحظات GitHub: الإنجليزي فوق والعربي تحته
{
  cat "$NOTES_EN"
  printf '\n---\n\n<div dir="rtl">\n\n'
  sed -e 's/^=\+$//' -e 's/^-\+$//' "$NOTES"
  printf '\n</div>\n'
} > "$OUT/github_release.md"
cp "$OUT/Shen-${VERSION}-universal.apk" Releases/Shen.apk

echo
echo "✅ الإصدار ${VERSION}v جاهز في $(realpath "$OUT"):"
(cd "$OUT" && ls -lh Shen-*.apk | awk '{print "   " $5 "\t" $9}')
echo
echo "النشر على GitHub (بعد ما تعمل تاج v${VERSION} وتعمل له push):"
echo "   gh release create v${VERSION} $OUT/Shen-*.apk $OUT/SHA256SUMS.txt $OUT/SHA256SUMS.txt.asc --title \"Shen ${VERSION}\" --notes-file $OUT/github_release.md"
