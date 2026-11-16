**العربية** | [English](README.en.md)

<p align="center">
  <img src="docs/images/banner.ar.png" alt="شِن — مفاتيح PGP بتاعتك في الحفظ والصون" width="100%">
</p>

<p align="center">
  <a href="https://github.com/AdamG00D/Shen/actions/workflows/ci.yml"><img src="https://github.com/AdamG00D/Shen/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/AdamG00D/Shen/releases/latest"><img src="https://img.shields.io/github/v/release/AdamG00D/Shen?label=release" alt="آخر إصدار"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue" alt="GPL-3.0"></a>
  <img src="https://img.shields.io/badge/Android-8%2B-3DDC84?logo=android&logoColor=white" alt="Android 8+">
  <img src="https://img.shields.io/badge/OpenPGP-RFC%209580-6E56CF" alt="OpenPGP">
</p>

# شِن — Shen

برنامج لإدارة مفاتيح **PGP** على أندرويد، زي كيلوباترا (Kleopatra) على الكمبيوتر: تعمل مفاتيحك، تضيف مفاتيح الناس،
وتشفّر وتفك وتوقّع وتتأكد من التوقيعات — للنصوص والملفات. **من غير إنترنت خالص**: التطبيق معندوش صلاحية إنترنت
أصلاً، فمستحيل يبعت حاجة لأي مكان.

الاسم من **حلقة شِن** عند المصريين القدام: دايرة حبل معقودة، رمز الحماية — ومنها اتعمل الخرطوش اللي بيحمي اسم الملك.

## المميزات

- **بروفايلات منفصلة** (شخصي، شغل...) — كل بروفايل بمفاتيحه وجهات اتصاله، وممكن يبقى له **كلمة سر لوحده**.
- **جهات الاتصال**: المفتاح العام بتاع أي حد بيفضل في البروفايل اللي ضفته فيه (الافتراضي)، أو تخليه **يظهر في كل
  البروفايلات**.
- **التأكد من المفاتيح**: تمسح **QR** من موبايل الشخص، أو تقارن البصمة بنفسك، أو **توقّع على مفتاحه** بمفتاحك.
- **تشفير وفك** نصوص وملفات بأي حجم، لشخص أو أكتر، أو بكلمة سر. والملف المفكوك بيتحفظ بس في المكان اللي تختاره.
- **توقيع وتحقق**: توقيع نصي (cleartext) أو ملف `.sig` منفصل، والنتيجة بتتعرض ببساطة: أخضر / أصفر / أحمر.
- **إدارة المفاتيح**: Ed25519 (الافتراضي)، أو RSA-4096، أو v6 الجديد. تقدر تغيّر الصلاحية أو كلمة السر، تضيف هوية،
  تلغي المفتاح، وفيه **شهادة إلغاء** بتتعمل لوحدها مع كل مفتاح.
- **نسخ احتياطي متشفّر** (لكل حاجة أو لبروفايل واحد) بصيغة OpenPGP مفتوحة، فتقدر تفكها من غير شِن خالص.
- **Share → شِن** و**افتح بـ** لملفات `.asc` / `.pgp` / `.sig`.
- **عربي وإنجليزي**، فاتح وغامق، وألوان تختارها.

## الأمان باختصار

- كل البيانات متشفّرة بـ AES-256-GCM. المفتاح الرئيسي محمي بكلمة السر الرئيسية (Argon2id) **ومعاها** مفتاح جوه
  Android Keystore (StrongBox لو موبايلك فيه). يعني نسخ ملفات التطبيق من الموبايل ميفيدش بحاجة.
- المفاتيح السرية نفسها لسه متشفّرة بكلمات سرها جوه الخزنة.
- الفتح بالبصمة اختياري، و**مربوط بالتشفير**: البصمة بتفك مفتاح الخزنة نفسه، مش مجرد "آه أو لأ".
- قفل تلقائي، ومنع السكرين شوت، والحافظة بتتمسح لوحدها، والنسخ الاحتياطي بتاع أندرويد مقفول. وأي حاجة خطيرة (تصدير
  مفتاح سري، حذف) بتطلب كلمة السر الرئيسية تاني.
- محرك التشفير هو [PGPainless](https://pgpainless.org) فوق Bouncy Castle، واتعمله فحص أمني من Cure53. والتيستات
  بتتأكد إن شِن وGnuPG بيفهموا بعض في الاتجاهين.

التفاصيل والحدود المعروفة في [SECURITY.ar.md](SECURITY.ar.md)، وطريقة التخزين في [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## التحميل

من [صفحة الإصدارات](https://github.com/AdamG00D/Shen/releases/latest):

| الملف | لمين |
|---|---|
| `Shen-<ver>-arm64-v8a.apk` | **أغلب الموبايلات** — لو مش متأكد خد ده |
| `Shen-<ver>-armeabi-v7a.apk` | الموبايلات القديمة أو الضعيفة |
| `Shen-<ver>-x86_64.apk` | المحاكي وأجهزة Chromebook |
| `Shen-<ver>-universal.apk` | أي موبايل (حجمه أكبر) |

أندرويد 8.0 أو أحدث.

### اتأكد إن الملف مني

كل إصدار فيه `SHA256SUMS.txt` وتوقيعه `SHA256SUMS.txt.asc` بمفتاح الإصدارات
([docs/shen-release-key.asc](docs/shen-release-key.asc)). والبصمة بتاعته:

```
B2D4 53B8 5430 D721 C173   3C1F B0E8 ADA6 3BD7 84BC
```

```bash
gpg --import shen-release-key.asc
gpg --verify SHA256SUMS.txt.asc SHA256SUMS.txt
sha256sum -c SHA256SUMS.txt --ignore-missing
```

## استخدام مفتاحك في كيلوباترا / GnuPG

صدّر المفتاح السري من صفحة المفتاح (**تصدير المفتاح السري**)، واستورد ملف `.asc` في كيلوباترا أو بـ `gpg --import`.
المفتاح بيفضل بكلمة سره.

> **Ubuntu 26.04 بس:** مكتبة libgcrypt 1.12.0 اللي فيه مبتعرفش تستخدم المفاتيح السرية المحمية بكلمة سر اللي جاية من
> برامج تانية ("Bad passphrase"). شغّل `gpg --passwd <الإيميل بتاعك>` مرة واحدة بعد الاستيراد (تقدر تسيب نفس كلمة
> السر). Debian وFedora وArch وUbuntu 24.04 مش متأثرين.

## البناء من الكود

```bash
flutter pub get
flutter analyze && flutter test
(cd android && ./gradlew :app:testDebugUnitTest)   # محرك التشفير + التوافق مع gpg
flutter build apk --release                          # من غير مفتاح التوقيع بيتوقّع بمفتاح debug
```

محتاج Flutter (stable) وJDK 17 أو أحدث وAndroid SDK. والإصدارات الرسمية بتتبني بـ `scripts/build_release.sh`.

## المساهمة

أهلاً بيك! اقرا [CONTRIBUTING.ar.md](CONTRIBUTING.ar.md). الثغرات الأمنية **متتكتبش في issue** — شوف
[SECURITY.ar.md](SECURITY.ar.md). وخطة اللي جاي في [ROADMAP.md](ROADMAP.md): مزوّد OpenPGP لتطبيقات الإيميل،
ومفاتيح YubiKey.

## الرخصة

[GPL-3.0-or-later](LICENSE). الخط IBM Plex Sans Arabic برخصة [SIL OFL 1.1](assets/fonts/OFL.txt).
