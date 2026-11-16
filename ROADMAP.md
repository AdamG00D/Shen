**English** · العربي تحت

# Roadmap

## 1.0 (done)

Profiles (each with its own keys, contacts and optional password), key generation and management, contacts that live
in one profile or in all of them, verification by QR / fingerprint comparison, certification, text and file
encryption / decryption / signing / verification, encrypted backups, Arabic + English, no internet permission.

## After 1.0 — planned

1. **OpenPGP provider for email apps** — let K-9 / Thunderbird for Android and FairEmail use Shen's keys (the role
   OpenKeychain plays today).
2. **Hardware keys** — YubiKey and other OpenPGP smart cards over NFC (and USB): the secret key never leaves the card.
3. **Online key lookup and refresh** — find keys by email (WKD, keys.openpgp.org) and fetch updates (new expiry,
   revocations). Off by default. Still to decide: an opt-in feature in the same app, or a separate "online" build so
   the default build keeps having no INTERNET permission at all.
4. *Maybe:* a Linux desktop build (on hold — desktop users already have Kleopatra).

Ideas and votes are welcome in the issues.

---

<div dir="rtl">

# خطة التطوير

## الإصدار 1.0 (خلص)

بروفايلات (كل واحد بمفاتيحه وجهات اتصاله وكلمة سر اختيارية)، إنشاء وإدارة المفاتيح، جهات اتصال في بروفايل واحد أو
في الكل، التأكد بالـ QR أو بمقارنة البصمة، التوقيع على المفاتيح، تشفير وفك وتوقيع وتحقق للنصوص والملفات، نسخ
احتياطي متشفّر، عربي وإنجليزي، ومن غير صلاحية إنترنت.

## بعد 1.0 — المخطط

1. **مزوّد OpenPGP لتطبيقات الإيميل** — K-9 / Thunderbird for Android وFairEmail يستخدموا مفاتيح شِن (زي
   OpenKeychain).
2. **المفاتيح الهاردوير** — YubiKey وكروت OpenPGP بالـ NFC (والـ USB): المفتاح السري مبيطلعش من الكارت أبداً.
3. **البحث عن المفاتيح وتحديثها أونلاين** — تدوّر على مفتاح بالإيميل (WKD وkeys.openpgp.org) وتجيب التحديثات
   (صلاحية جديدة، إلغاء). مقفول افتراضياً. لسه هنقرر: اختيار جوه نفس التطبيق، ولا نسخة "أونلاين" منفصلة عشان
   النسخة العادية تفضل من غير صلاحية إنترنت خالص.
4. *يمكن:* نسخة لينكس ديسكتوب (متأجلة — مستخدمين الكمبيوتر عندهم كيلوباترا أصلاً).

</div>
