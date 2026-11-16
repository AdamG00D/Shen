// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'شِن';

  @override
  String get tagline => 'مفاتيح PGP بتاعتك في الحفظ والصون — من غير إنترنت.';

  @override
  String get errUnknown => 'حصلت مشكلة. جرّب تاني.';

  @override
  String get errWrongPassword => 'كلمة السر غلط.';

  @override
  String get errLockedOut => 'محاولات غلط كتير.';

  @override
  String get errLocked => 'التطبيق اتقفل. افتحه تاني.';

  @override
  String get errProfileLocked => 'البروفايل ده مقفول بكلمة سر. افتحه الأول.';

  @override
  String errProfileLockedNamed(String name) {
    return 'افتح بروفايل «$name» الأول وبعدين جرّب تاني.';
  }

  @override
  String get errKeystore =>
      'مفتاح الجهاز مش موجود (يمكن البيانات اتنقلت من موبايل تاني). البيانات دي مش هتتفتح على الموبايل ده.';

  @override
  String get errBadData => 'البيانات دي مش OpenPGP أو بايظة.';

  @override
  String get errIntegrity =>
      'الرسالة دي اتلعب فيها أو بايظة — اترفضت ومحدش اتحفظ منها حاجة.';

  @override
  String get errNoKey => 'مفيش مفتاح عندك يفك الرسالة دي.';

  @override
  String get errCannotEncrypt =>
      'مفتاح واحد من المستلمين منتهي أو ملغي أو مينفعش يشفّر.';

  @override
  String get errCannotSign => 'المفتاح ده مينفعش يوقّع (منتهي أو ملغي).';

  @override
  String get errNotFound => 'مش موجود.';

  @override
  String get errExists => 'موجود قبل كده.';

  @override
  String get errTooLarge => 'كبير زيادة عن اللزوم.';

  @override
  String get errInvalid => 'في بيانات ناقصة أو غلط.';

  @override
  String get errEncryptedNotSigned => 'دي رسالة متشفّرة — استخدم «فك / تحقق».';

  @override
  String get errNotBackup => 'الملف ده مش نسخة احتياطية من شِن.';

  @override
  String get errCancelled => 'اتلغت.';

  @override
  String get errIo => 'مش قادر يقرا أو يكتب الملف.';

  @override
  String get errBioInvalidated =>
      'البصمات اللي على الموبايل اتغيّرت، فالفتح بالبصمة اتقفل. افتح بكلمة السر وفعّله تاني.';

  @override
  String get errBioUnavailable => 'الفتح بالبصمة مش متفعّل.';

  @override
  String tryAgainIn(String time) {
    return 'جرّب تاني بعد $time.';
  }

  @override
  String seconds(int count) {
    return '$count ثانية';
  }

  @override
  String minutes(int count) {
    return '$count دقيقة';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get ok => 'تمام';

  @override
  String get hide => 'إخفاء';

  @override
  String get show => 'إظهار';

  @override
  String get save => 'حفظ';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'اتنسخ';

  @override
  String get close => 'قفل';

  @override
  String get share => 'مشاركة';

  @override
  String get saveFile => 'حفظ كملف';

  @override
  String get saved => 'اتحفظ';

  @override
  String get search => 'بحث';

  @override
  String get done => 'تم';

  @override
  String get delete => 'حذف';

  @override
  String get deleted => 'اتحذف';

  @override
  String get add => 'إضافة';

  @override
  String get paste => 'لصق';

  @override
  String get clear => 'مسح';

  @override
  String get open => 'فتح';

  @override
  String get create => 'إنشاء';

  @override
  String get export => 'تصدير';

  @override
  String get import => 'استيراد';

  @override
  String get current => 'الحالي';

  @override
  String get iUnderstand => 'فاهم وعايز أكمّل';

  @override
  String copiedSecure(int count) {
    return 'اتنسخ — وهيتمسح من الحافظة بعد $count ثانية';
  }

  @override
  String get showQr => 'عرض QR';

  @override
  String get invalid => 'مش صالح';

  @override
  String get strengthVeryWeak => 'ضعيفة جداً';

  @override
  String get strengthWeak => 'ضعيفة';

  @override
  String get strengthOk => 'مقبولة';

  @override
  String get strengthGood => 'كويسة';

  @override
  String get strengthStrong => 'قوية';

  @override
  String get keyPassphraseTitle => 'كلمة سر المفتاح';

  @override
  String keyPassphraseFor(String name) {
    return 'اكتب كلمة سر المفتاح:\n$name';
  }

  @override
  String get keyPassphrase => 'كلمة سر المفتاح';

  @override
  String get masterPasswordTitle => 'كلمة السر الرئيسية';

  @override
  String get masterPassword => 'كلمة السر الرئيسية';

  @override
  String passwordTooShort(int count) {
    return 'كلمة السر لازم تكون $count حروف على الأقل.';
  }

  @override
  String get passwordsDontMatch => 'كلمتين السر مش زي بعض.';

  @override
  String get newPassword => 'كلمة السر الجديدة';

  @override
  String get confirmPassword => 'اكتبها تاني للتأكيد';

  @override
  String get revoked => 'ملغي';

  @override
  String get expired => 'منتهي';

  @override
  String get expiresSoon => 'هيخلص قريب';

  @override
  String get defaultKey => 'الافتراضي';

  @override
  String get noPassphrase => 'من غير كلمة سر';

  @override
  String get verified => 'متأكد منه';

  @override
  String get allProfiles => 'كل البروفايلات';

  @override
  String sigGoodVerified(String name) {
    return 'توقيع سليم من $name';
  }

  @override
  String get sigByMe => 'التوقيع ده بمفتاح من مفاتيحك.';

  @override
  String get sigGoodVerifiedBody =>
      'الرسالة متغيّرتش، وانت متأكد إن المفتاح ده بتاع الشخص ده.';

  @override
  String sigGoodUnverified(String name) {
    return 'التوقيع سليم من $name — بس لسه متأكدتش من المفتاح';
  }

  @override
  String get sigGoodUnverifiedBody =>
      'الرسالة متغيّرتش، بس لسه متأكدتش إن المفتاح ده فعلاً بتاع الشخص ده. قارن البصمة معاه (وش لوش أو بالـ QR).';

  @override
  String get sigUnknown => 'موقّعة بمفتاح مش عندك';

  @override
  String sigUnknownBody(String keyId) {
    return 'مش هنقدر نتأكد من التوقيع غير لما تضيف المفتاح العام بتاع اللي بعت ($keyId).';
  }

  @override
  String get sigBad => 'التوقيع غلط!';

  @override
  String get sigBadBody =>
      'الرسالة اتغيّرت بعد ما اتوقّعت، أو التوقيع مزوّر. متثقش في المحتوى ده.';

  @override
  String signedOn(String date) {
    return 'اتوقّعت يوم $date';
  }

  @override
  String get notSigned => 'الرسالة دي مش موقّعة — مش هنعرف مين اللي بعتها.';

  @override
  String get noRecipients =>
      'مفيش جهات اتصال تقدر تشفّر لها. ضيف مفاتيح الناس من «جهات الاتصال».';

  @override
  String get contacts => 'جهات الاتصال';

  @override
  String get myKeys => 'مفاتيحي';

  @override
  String hiddenUnusable(int count) {
    return '$count مفتاح متخبّي لأنه منتهي أو ملغي.';
  }

  @override
  String selectedCount(int count) {
    return 'تم ($count)';
  }

  @override
  String get chooseSigningKey => 'اختار المفتاح اللي هتوقّع بيه';

  @override
  String get defaultProfileName => 'شخصي';

  @override
  String get nameRequired => 'اكتب اسم.';

  @override
  String get introOffline =>
      'كل حاجة على موبايلك بس: مفيش إنترنت ولا حساب ولا سيرفر.';

  @override
  String get introProfiles =>
      'بروفايلات منفصلة (شخصي، شغل...) كل واحد بمفاتيحه وجهات اتصاله.';

  @override
  String get introStandard =>
      'OpenPGP قياسي: بيتفاهم مع كيلوباترا وgpg وThunderbird وأي برنامج تاني.';

  @override
  String get setupTitle => 'يلا نبدأ';

  @override
  String get firstProfileName => 'اسم أول بروفايل';

  @override
  String get masterPasswordWarning =>
      'كلمة السر الرئيسية بتقفل التطبيق كله. لو نسيتها مفيش أي طريقة ترجّع بيها البيانات — فاختار حاجة تفتكرها، وخد نسخة احتياطية من الإعدادات.';

  @override
  String get createVault => 'إنشاء';

  @override
  String get bioTitle => 'افتح شِن';

  @override
  String get bioSubtitle => 'بصمتك بتفك مفتاح الخزنة';

  @override
  String get usePassword => 'بكلمة السر';

  @override
  String get locked => 'شِن مقفول';

  @override
  String get lockedHint => 'اكتب كلمة السر الرئيسية عشان تفتح.';

  @override
  String get unlock => 'فتح';

  @override
  String get unlockWithBio => 'الفتح بالبصمة';

  @override
  String get lockNow => 'قفل دلوقتي';

  @override
  String get tools => 'الأدوات';

  @override
  String get settings => 'الإعدادات';

  @override
  String profileLockedTitle(String name) {
    return 'بروفايل «$name» مقفول';
  }

  @override
  String get profileLockedBody =>
      'البروفايل ده ليه كلمة سر لوحده. افتحه عشان تشوف مفاتيحه وجهات اتصاله.';

  @override
  String unlockProfile(String name) {
    return 'فتح «$name»';
  }

  @override
  String get profilePassword => 'كلمة سر البروفايل';

  @override
  String get profiles => 'البروفايلات';

  @override
  String profileCounts(int keys, int contacts) {
    return 'مفاتيح: $keys · جهات اتصال: $contacts';
  }

  @override
  String get profileLockedShort => 'مقفول';

  @override
  String get manageProfiles => 'إدارة البروفايلات';

  @override
  String get newKey => 'مفتاح جديد';

  @override
  String get noKeysTitle => 'لسه معندكش مفاتيح';

  @override
  String get noKeysBody =>
      'اعمل مفتاح جديد عشان الناس تقدر تبعتلك رسايل متشفّرة وتتأكد من توقيعك، أو استورد مفتاح عندك.';

  @override
  String get importKey => 'استيراد مفتاح';

  @override
  String myKeysCount(int count) {
    return 'مفاتيحي ($count)';
  }

  @override
  String get nameOrEmailRequired => 'اكتب اسم أو إيميل على الأقل.';

  @override
  String get invalidEmail => 'الإيميل ده مش مكتوب صح.';

  @override
  String get invalidCharacters => 'متستخدمش < > ( ) في الاسم أو التعليق.';

  @override
  String get keyCreatedTitle => 'المفتاح جاهز';

  @override
  String get keyCreatedBody =>
      'دلوقتي:\n• شارك المفتاح العام مع الناس عشان يقدروا يشفّرولك.\n• خد نسخة احتياطية (الإعدادات ← النسخ الاحتياطي) عشان لو الموبايل ضاع.\n• اتعملت شهادة إلغاء لوحدها — احفظها في مكان آمن.';

  @override
  String get newKeyIntro =>
      'المفتاح ليه جزئين: جزء عام بتديه للناس، وجزء سري بيفضل على موبايلك ومحمي بكلمة سر.';

  @override
  String get name => 'الاسم';

  @override
  String get emailOptional => 'الإيميل (اختياري)';

  @override
  String get commentOptional => 'تعليق (اختياري)';

  @override
  String get commentHelp => 'مثلاً: شغل — بيظهر جنب اسمك';

  @override
  String get keyPassphraseHelp =>
      'بتحمي الجزء السري حتى لو حد خد نسخة منه. هتطلبها وانت بتفك أو بتوقّع.';

  @override
  String get noPassphraseOption => 'من غير كلمة سر';

  @override
  String get noPassphraseWarning =>
      'مش منصوح بيه: أي حد معاه نسخة من المفتاح يقدر يستخدمه.';

  @override
  String get expiry => 'الصلاحية';

  @override
  String get never => 'مبيخلصش';

  @override
  String yearsCount(int count) {
    return '$count سنة';
  }

  @override
  String get expiryHelp =>
      'لو ضاع منك المفتاح، الصلاحية بتخلّيه يبطل لوحده. وتقدر تمدّها في أي وقت.';

  @override
  String get advanced => 'متقدم';

  @override
  String get algoCv25519 => 'Ed25519 / X25519 (منصوح بيه)';

  @override
  String get algoCv25519Help =>
      'حديث وسريع وشغال مع gpg وكيلوباترا وأي برنامج.';

  @override
  String get algoRsa => 'RSA 4096';

  @override
  String get algoRsaHelp => 'للأنظمة القديمة اللي مبتفهمش Ed25519. أبطأ وأكبر.';

  @override
  String get algoV6 => 'OpenPGP v6 (RFC 9580)';

  @override
  String get algoV6Help => 'أحدث صيغة. gpg وكيلوباترا لسه مبيدعموهاش.';

  @override
  String get createKey => 'إنشاء المفتاح';

  @override
  String get rsaSlow => 'مفاتيح RSA بتاخد وقت... استنى شوية.';

  @override
  String get sharePublicKey => 'مشاركة المفتاح العام';

  @override
  String get showAsQr => 'عرض كـ QR';

  @override
  String get showAsQrHelp => 'الشخص اللي قدامك يمسحه بشِن';

  @override
  String get qrKeyCaption =>
      'ده مفتاحك العام كامل. اللي يمسحه بشِن بيضيفك ويتعلّم إنه متأكد منك.';

  @override
  String get changeExpiry => 'تغيير الصلاحية';

  @override
  String yearsFromNow(int count) {
    return '$count سنة من النهارده';
  }

  @override
  String get updatedShareAgain =>
      'اتحدّث — شارك المفتاح العام تاني عشان الناس تاخد التعديل.';

  @override
  String get changeKeyPassphrase => 'تغيير كلمة سر المفتاح';

  @override
  String get changeKeyPassphraseBody =>
      'كلمة السر الجديدة بتحمي الجزء السري من المفتاح.';

  @override
  String get passphraseChanged => 'كلمة السر اتغيّرت';

  @override
  String get addIdentity => 'إضافة هوية (اسم / إيميل)';

  @override
  String get identityHint => 'الاسم <email@example.com>';

  @override
  String get exportSecretTitle => 'تصدير المفتاح السري';

  @override
  String get exportSecretBody =>
      'ده الجزء اللي محدش المفروض يشوفه غيرك. حتى لو متشفّر بكلمة سره، احفظه بس في مكان آمن (فلاشة معاك مثلاً) ومتبعتوش لحد.';

  @override
  String get masterPasswordForExport => 'اكتب كلمة السر الرئيسية عشان تصدّر.';

  @override
  String get revocationCert => 'شهادة الإلغاء';

  @override
  String get revocationCertBody =>
      'لو المفتاح اتسرق أو ضاع، الشهادة دي بتعرّف الناس إنه ملغي — حتى لو ملكش وصول للمفتاح نفسه. احفظها في مكان آمن برا الموبايل (أي حد معاه الشهادة يقدر يلغي مفتاحك).';

  @override
  String get revokeTitle => 'إلغاء المفتاح';

  @override
  String get revokeBody =>
      'بعد الإلغاء محدش هيقدر يشفّرلك بالمفتاح ده تاني، ومينفعش ترجع فيه. لازم تشارك المفتاح العام بعدها عشان الناس تعرف.';

  @override
  String get revoke => 'إلغاء المفتاح';

  @override
  String get revokeReason => 'ليه بتلغيه؟';

  @override
  String get reasonCompromised => 'اتسرق أو اتكشف';

  @override
  String get reasonSuperseded => 'عملت مفتاح جديد بداله';

  @override
  String get reasonRetired => 'مبقتش بستخدمه';

  @override
  String get reasonNone => 'من غير سبب';

  @override
  String get revokedShareNow =>
      'المفتاح اتلغى — شارك المفتاح العام دلوقتي عشان الناس تعرف.';

  @override
  String get deleteKeyTitle => 'حذف المفتاح';

  @override
  String get deleteKeyBody =>
      'المفتاح السري هيتمسح من الموبايل. لو معندكش نسخة احتياطية، أي رسالة متشفّرة ليه هتضيع للأبد.';

  @override
  String get masterPasswordForDelete => 'اكتب كلمة السر الرئيسية عشان تحذف.';

  @override
  String get note => 'ملاحظة';

  @override
  String get keyDetails => 'المفتاح';

  @override
  String get keyRevokedNotice =>
      'المفتاح ده اتلغى. محدش يقدر يشفّرله ومينفعش يوقّع، بس لسه تقدر تفك بيه الرسايل القديمة.';

  @override
  String get keyExpiredNotice =>
      'صلاحية المفتاح خلصت. مدّها من «تغيير الصلاحية» وشارك المفتاح العام تاني.';

  @override
  String get fingerprint => 'البصمة';

  @override
  String get qrFingerprintCaption =>
      'اللي قدامك يمسح الـ QR ده بشِن عشان يتأكد إن المفتاح اللي عنده هو مفتاحك.';

  @override
  String get manage => 'إدارة';

  @override
  String get makeDefault => 'خليه الافتراضي';

  @override
  String get makeDefaultHelp => 'بنوقّع بيه ونشفّر لنفسنا بيه تلقائياً';

  @override
  String get backupAndSafety => 'نسخ احتياطي وأمان';

  @override
  String get exportSecret => 'تصدير المفتاح السري';

  @override
  String get exportSecretHelp =>
      'ملف .asc لنقل المفتاح لكيلوباترا أو جهاز تاني';

  @override
  String get revocationCertHelp => 'احفظها برا الموبايل لو المفتاح اتسرق';

  @override
  String get revokeHelp => 'لو المفتاح اتسرق أو بطّلت تستخدمه';

  @override
  String get deleteKey => 'حذف المفتاح';

  @override
  String get flagCertify => 'اعتماد';

  @override
  String get flagSign => 'توقيع';

  @override
  String get flagEncrypt => 'تشفير';

  @override
  String get flagAuth => 'دخول';

  @override
  String get details => 'التفاصيل';

  @override
  String get algorithm => 'النوع';

  @override
  String get created => 'اتعمل';

  @override
  String get expires => 'بيخلص';

  @override
  String get keyIdLabel => 'رقم المفتاح';

  @override
  String get version => 'الإصدار';

  @override
  String get identities => 'الهويات';

  @override
  String get subkeys => 'المفاتيح الفرعية';

  @override
  String get fromClipboard => 'من الحافظة';

  @override
  String get pasteText => 'لصق نص';

  @override
  String get fromFile => 'من ملف';

  @override
  String get scanQr => 'مسح QR';

  @override
  String get scanQrHelp => 'مفتاح عام أو بصمة من موبايل الشخص قدامك';

  @override
  String get clipboardEmpty => 'الحافظة فاضية.';

  @override
  String get pasteKeyHere => 'الصق المفتاح هنا (-----BEGIN PGP...)';

  @override
  String get qrNotKey => 'الـ QR ده مش مفتاح ولا بصمة.';

  @override
  String get fingerprintUnknownTitle => 'المفتاح ده مش عندك';

  @override
  String fingerprintUnknownBody(String fp) {
    return 'البصمة:\n$fp\n\nضيف المفتاح العام بتاع الشخص الأول (ملف أو QR المفتاح كامل)، وبعدين امسح البصمة تاني عشان تتأكد.';
  }

  @override
  String get thisIsYourKey => 'ده مفتاح من مفاتيحك.';

  @override
  String get verifiedTitle => 'اتأكدنا';

  @override
  String get verifiedByQr =>
      'البصمة اللي مسحتها مطابقة للمفتاح اللي عندك، فالجهة دي اتعلّمت إنها متأكد منها.';

  @override
  String importDone(int added, int updated) {
    return 'اتضاف $added واتحدّث $updated';
  }

  @override
  String get importKeysTitle => 'استيراد مفاتيح';

  @override
  String importFound(int count) {
    return 'لقينا $count مفتاح. اختار اللي عايز تضيفه:';
  }

  @override
  String get alreadyHaveUpdate => 'موجود عندك — هيتحدّث بس (مفيش حاجة هتتمسح)';

  @override
  String get secretGoesToMyKeys =>
      'المفاتيح السرية بتتضاف لـ «مفاتيحي» في البروفايل ده.';

  @override
  String get whereToShow => 'يظهر فين';

  @override
  String thisProfileOnly(String name) {
    return 'بروفايل «$name» بس';
  }

  @override
  String get thisProfileOnlyHelp => 'مش هيظهر في البروفايلات التانية';

  @override
  String get allProfilesHelp => 'هيظهر في كل البروفايلات';

  @override
  String get importQrVerified =>
      'المفتاح جه بـ QR من موبايل الشخص نفسه، فهيتعلّم إنه متأكد منه.';

  @override
  String get verifyAfterImport =>
      'بعد الاستيراد قارن البصمة مع صاحب المفتاح (أو امسح الـ QR بتاعه) عشان تتأكد إنه بتاعه فعلاً.';

  @override
  String get addContact => 'إضافة جهة اتصال';

  @override
  String get noContactsTitle => 'مفيش جهات اتصال';

  @override
  String get noContactsBody =>
      'ضيف المفتاح العام بتاع أي حد عشان تشفّرله رسايل وتتأكد من توقيعاته.';

  @override
  String get searchContacts => 'دوّر بالاسم أو الإيميل أو البصمة';

  @override
  String contactsCount(int count) {
    return 'جهات الاتصال ($count)';
  }

  @override
  String get compareTitle => 'قارن البصمة';

  @override
  String compareBody(String fp) {
    return 'اطلب من الشخص يقرالك البصمة من موبايله (وش لوش أو في مكالمة)، وقارنها حرف حرف:\n\n$fp';
  }

  @override
  String get theyMatch => 'مطابقة';

  @override
  String get markedVerified => 'اتعلّم إنه متأكد منه';

  @override
  String get needOwnKey => 'محتاج مفتاح خاص بيك الأول (من «مفاتيحي»)';

  @override
  String get certifyTitle => 'التوقيع على المفتاح';

  @override
  String get certifyBody =>
      'هتوقّع بمفتاحك إنك متأكد إن المفتاح ده بتاع الشخص ده. لو شاركت المفتاح ده بعد كده، اللي يثق فيك هيعرف إنك اتأكدت منه. اعملها بس لو قارنت البصمة بنفسك.';

  @override
  String get certify => 'توقيع';

  @override
  String get certified => 'اتوقّع على المفتاح';

  @override
  String get deleteContactTitle => 'حذف جهة الاتصال';

  @override
  String get deleteContactBody => 'المفتاح العام بتاعه هيتشال من البروفايل ده.';

  @override
  String get deleteContactSharedBody =>
      'جهة الاتصال دي ظاهرة في كل البروفايلات — هتتشال منهم كلهم.';

  @override
  String get contact => 'جهة اتصال';

  @override
  String get contactVerified => 'متأكد إن المفتاح ده بتاعه';

  @override
  String get contactNotVerified => 'لسه متأكدتش من المفتاح ده';

  @override
  String get contactVerifiedBody =>
      'انت قارنت البصمة مع صاحبها. التوقيعات بالمفتاح ده هتظهر خضرا.';

  @override
  String get contactNotVerifiedBody =>
      'أي حد ممكن يعمل مفتاح باسم أي حد. قبل ما تثق فيه، اتأكد من البصمة مع صاحبها نفسه.';

  @override
  String get scanTheirQr => 'امسح الـ QR بتاعه';

  @override
  String get compareManually => 'قارنت البصمة بنفسي';

  @override
  String get certifyWithMyKey => 'وقّع عليه بمفتاحي';

  @override
  String get unmarkVerified => 'شيل علامة «متأكد منه»';

  @override
  String get showInAllProfiles => 'يظهر في كل البروفايلات';

  @override
  String get updateKey => 'تحديث المفتاح';

  @override
  String get updateKeyHelp => 'لو صاحبه بعتلك نسخة أحدث (صلاحية جديدة / إلغاء)';

  @override
  String get deleteContact => 'حذف جهة الاتصال';

  @override
  String get messagePasswordTitle => 'كلمة سر الرسالة';

  @override
  String get messagePasswordBody => 'الرسالة دي متشفّرة بكلمة سر (مش بمفتاح).';

  @override
  String get messagePassword => 'كلمة السر';

  @override
  String get otherProfileTitle => 'الرسالة لبروفايل تاني';

  @override
  String otherProfileBody(String name) {
    return 'الرسالة دي متشفّرة لمفتاح في بروفايل «$name». غيّر البروفايل من فوق وجرّب تاني.';
  }

  @override
  String get notForYouTitle => 'الرسالة دي مش ليك';

  @override
  String get notForYouHidden =>
      'المرسل خبّى أرقام المفاتيح، ومفيش مفتاح عندك عرف يفكها.';

  @override
  String notForYouBody(String ids) {
    return 'متشفّرة لمفاتيح مش عندك:\n$ids';
  }

  @override
  String get toPeople => 'لناس';

  @override
  String get withPassword => 'بكلمة سر';

  @override
  String get passwordModeHelp =>
      'أي حد معاه كلمة السر يقدر يفك — حتى لو معندوش شِن (gpg / كيلوباترا). ابعت كلمة السر بطريقة تانية غير الرسالة نفسها.';

  @override
  String get recipients => 'المستلمين';

  @override
  String get noRecipientsChosen => 'اختار مستلم واحد على الأقل.';

  @override
  String get unverifiedRecipientWarning =>
      'في مستلم لسه متأكدتش من مفتاحه — لو المفتاح مش بتاعه فعلاً حد تاني هيقدر يقرا الرسالة.';

  @override
  String get encryptToSelf => 'شفّر لنفسي كمان';

  @override
  String get encryptToSelfHelp => 'عشان تقدر تقرا اللي بعته بعدين';

  @override
  String get signMessage => 'وقّع';

  @override
  String get signMessageHelp => 'المستلم يتأكد إنها منك ومتغيّرتش';

  @override
  String get needSigningKey => 'محتاج مفتاح خاص بيك يقدر يوقّع (من «مفاتيحي»)';

  @override
  String signingAs(String name) {
    return 'بتوقّع كـ $name';
  }

  @override
  String get changeSigningKey => 'تغيير مفتاح التوقيع';

  @override
  String get newMessagePasswordBody =>
      'اختار كلمة سر قوية، وابعتها للمستلم بطريقة تانية.';

  @override
  String get writeSomething => 'اكتب حاجة الأول.';

  @override
  String get encryptedMessage => 'الرسالة المتشفّرة';

  @override
  String get encryptedMessageHelp =>
      'ابعتها بأي طريقة (واتساب، إيميل...). محدش يقدر يقراها غير المستلمين.';

  @override
  String get encryptText => 'تشفير نص';

  @override
  String get writeMessage => 'اكتب الرسالة هنا';

  @override
  String get encrypt => 'تشفير';

  @override
  String get pasteSomething => 'الصق رسالة أو توقيع الأول.';

  @override
  String get detachedNeedsText =>
      'ده توقيع منفصل: الصق النص الأصلي في الخانة اللي ظهرت وجرّب تاني.';

  @override
  String get notPgpText => 'النص ده مش رسالة OpenPGP.';

  @override
  String get decryptVerify => 'فك / تحقق';

  @override
  String get decryptVerifyHelp =>
      'الصق رسالة متشفّرة، أو رسالة موقّعة، أو مفتاح عام — وشِن هيعرف يعمل إيه.';

  @override
  String get pasteMessage => '-----BEGIN PGP MESSAGE-----';

  @override
  String get signedTextLabel => 'النص الأصلي';

  @override
  String get signedTextHint => 'الصق النص اللي اتوقّع';

  @override
  String get signature => 'التوقيع';

  @override
  String get decryptedText => 'الرسالة';

  @override
  String get signedContent => 'المحتوى';

  @override
  String get signedMessage => 'النص الموقّع';

  @override
  String get signText => 'توقيع نص';

  @override
  String get signingKey => 'مفتاح التوقيع';

  @override
  String get detachedSignature => 'توقيع منفصل';

  @override
  String get detachedSignatureHelp => 'التوقيع لوحده من غير النص (لملفات .sig)';

  @override
  String get sign => 'توقيع';

  @override
  String get chooseFileFirst => 'اختار ملف الأول.';

  @override
  String get fileIsSignedOnly =>
      'الملف ده موقّع بس (مش متشفّر) — استخدم «تحقق من ملف».';

  @override
  String get fileNotEncrypted => 'الملف ده مش متشفّر بـ OpenPGP.';

  @override
  String get chooseSignatureFile => 'اختار ملف التوقيع (.sig / .asc).';

  @override
  String get encryptFile => 'تشفير ملف';

  @override
  String get encryptFileHelp =>
      'أي نوع ملف وأي حجم. الملف المتشفّر بيتحفظ في المكان اللي تختاره.';

  @override
  String get decryptFile => 'فك ملف';

  @override
  String get decryptFileHelp =>
      'ملف .pgp / .gpg / .asc. لو الملف اتلعب فيه، اللي اتكتب منه بيتمسح لوحده.';

  @override
  String get decrypt => 'فك التشفير';

  @override
  String get signFile => 'توقيع ملف';

  @override
  String get signFileHelp => 'بيعمل ملف توقيع منفصل (.sig) تبعته جنب الملف.';

  @override
  String get verifyFile => 'تحقق من ملف';

  @override
  String get verifyFileHelp =>
      'اختار الملف وملف التوقيع بتاعه. لو الملف موقّع جوه نفسه، سيب التوقيع فاضي.';

  @override
  String get verify => 'تحقق';

  @override
  String get chooseFile => 'اختار ملف';

  @override
  String get chooseSignatureFileOptional => 'ملف التوقيع (.sig) — اختياري';

  @override
  String get asciiArmor => 'نص (ASCII armor)';

  @override
  String get asciiArmorHelp => 'ملف .asc نصي بدل .pgp — أكبر شوية بس يتبعت كنص';

  @override
  String savedAs(String name) {
    return 'اتحفظ: $name';
  }

  @override
  String get text => 'نصوص';

  @override
  String get encryptTextHelp => 'رسالة محدش يقراها غير اللي تختارهم';

  @override
  String get decryptVerifyShort => 'افتح رسالة، أو اتأكد من توقيع';

  @override
  String get signTextHelp => 'الناس تتأكد إن الكلام ده منك';

  @override
  String get files => 'ملفات';

  @override
  String get encryptFileShort => 'صور، مستندات، أي حاجة';

  @override
  String get decryptFileShort => '.pgp / .gpg / .asc';

  @override
  String get signFileShort => 'ملف توقيع .sig';

  @override
  String get verifyFileShort => 'اتأكد إن الملف متغيّرش ومن مين';

  @override
  String get newProfile => 'بروفايل جديد';

  @override
  String get profilesHelp =>
      'كل بروفايل ليه مفاتيحه وجهات اتصاله لوحده (شخصي، شغل...). جهات الاتصال بتفضل في البروفايل بتاعها، إلا لو اخترت إنها تظهر في الكل.';

  @override
  String get hasOwnPassword => 'بكلمة سر لوحده';

  @override
  String get profilePasswordHelp =>
      'طبقة زيادة: البروفايل يفضل مقفول لحد ما تكتب كلمة سره، حتى لو التطبيق مفتوح.';

  @override
  String get profileCreated => 'البروفايل اتعمل';

  @override
  String get switchTo => 'افتحه';

  @override
  String get renameProfile => 'الاسم واللون';

  @override
  String get changeProfilePassword => 'تغيير كلمة سر البروفايل';

  @override
  String get setProfilePassword => 'حط كلمة سر للبروفايل';

  @override
  String get removeProfilePassword => 'شيل كلمة سر البروفايل';

  @override
  String get lockProfileNow => 'اقفل البروفايل دلوقتي';

  @override
  String get deleteProfile => 'حذف البروفايل';

  @override
  String deleteProfileTitle(String name) {
    return 'حذف «$name»؟';
  }

  @override
  String get deleteProfileBody =>
      'كل المفاتيح السرية وجهات الاتصال اللي في البروفايل ده هتتمسح ومش هترجع. خد نسخة احتياطية الأول.';

  @override
  String get profileName => 'اسم البروفايل';

  @override
  String get profileNameHint => 'شخصي، شغل، الجامعة...';

  @override
  String get protectWithPassword => 'كلمة سر لوحده';

  @override
  String get backupPassword => 'كلمة سر النسخة الاحتياطية';

  @override
  String get backupPasswordHelp =>
      'النسخة بتتشفّر بيها. من غيرها مفيش أي طريقة تفتحها — اكتبها في مكان آمن.';

  @override
  String get backupDoneTitle => 'النسخة الاحتياطية جاهزة';

  @override
  String backupDoneBody(int profiles, int keys, int contacts) {
    return 'بروفايلات: $profiles\nمفاتيح: $keys\nجهات اتصال: $contacts\n\nحطها في مكان برا الموبايل (كمبيوتر، فلاشة).';
  }

  @override
  String backupSkipped(String names) {
    return 'البروفايلات المقفولة دي متاخدش منها نسخة (افتحها وجرّب تاني): $names';
  }

  @override
  String get restoreTitle => 'استرجاع النسخة؟';

  @override
  String backupFrom(String date) {
    return 'النسخة من يوم $date';
  }

  @override
  String get willMerge => 'هيندمج مع البروفايل اللي بنفس الاسم';

  @override
  String get willCreate => 'بروفايل جديد';

  @override
  String sharedContactsCount(int count) {
    return 'جهات اتصال لكل البروفايلات: $count';
  }

  @override
  String get restoreNothingDeleted =>
      'مفيش حاجة عندك هتتمسح: المفاتيح الجديدة بتتضاف والموجودة بتتحدّث بس.';

  @override
  String get restore => 'استرجاع';

  @override
  String get backup => 'النسخ الاحتياطي';

  @override
  String get backupIntro =>
      'النسخة الاحتياطية ملف .shen متشفّر بكلمة سر بتختارها (OpenPGP: Argon2 + AES-256). المفاتيح السرية جواها لسه محمية بكلمات سرها كمان. تقدر ترجّعها على أي موبايل.';

  @override
  String get exportSection => 'تصدير';

  @override
  String get backupEverything => 'نسخة من كل حاجة';

  @override
  String get backupEverythingHelp =>
      'كل البروفايلات المفتوحة + جهات الاتصال المشتركة';

  @override
  String backupThisProfile(String name) {
    return 'نسخة من «$name» بس';
  }

  @override
  String get backupThisProfileHelp => 'مفاتيح وجهات اتصال البروفايل ده بس';

  @override
  String get importSection => 'استرجاع';

  @override
  String get restoreBackup => 'استرجاع نسخة احتياطية';

  @override
  String get restoreBackupHelp => 'من ملف .shen';

  @override
  String get backupFormatNote =>
      'الصيغة مفتوحة وموثّقة: تقدر تفك النسخة من غير شِن خالص بالأمر sq decrypt (Sequoia PGP). مفاتيحك العامة تقدر تصدّرها لوحدها كملف .asc من صفحة كل مفتاح.';

  @override
  String get immediately => 'على طول';

  @override
  String get bioEnableTitle => 'تفعيل الفتح بالبصمة';

  @override
  String get bioEnabled => 'الفتح بالبصمة اتفعّل';

  @override
  String get currentMasterPassword => 'اكتب كلمة السر الرئيسية الحالية.';

  @override
  String get newMasterPassword => 'كلمة سر رئيسية جديدة';

  @override
  String get passwordChanged => 'كلمة السر اتغيّرت';

  @override
  String get wipeTitle => 'مسح كل البيانات';

  @override
  String get wipeBody =>
      'كل المفاتيح والبروفايلات وجهات الاتصال هتتمسح من الموبايل ده نهائياً. لو معندكش نسخة احتياطية مش هتقدر ترجّعها.';

  @override
  String get wipe => 'امسح كل حاجة';

  @override
  String get masterPasswordForWipe =>
      'اكتب كلمة السر الرئيسية عشان تمسح كل حاجة.';

  @override
  String get security => 'الأمان';

  @override
  String get bioHelp => 'البصمة بتفك مفتاح الخزنة نفسه (مش مجرد سماح)';

  @override
  String get autoLock => 'القفل التلقائي';

  @override
  String autoLockValue(String time) {
    return 'بعد ما تخرج من التطبيق بـ $time';
  }

  @override
  String get rememberPassphrase => 'تذكّر كلمات سر المفاتيح';

  @override
  String get rememberPassphraseOff => 'لأ — هتتطلب كل مرة (الأأمن)';

  @override
  String rememberPassphraseOn(int count) {
    return 'في الذاكرة بس لمدة $count دقيقة، وبتتمسح لما التطبيق يتقفل';
  }

  @override
  String get dontRemember => 'متفتكرش';

  @override
  String get clipboardClear => 'مسح الحافظة';

  @override
  String clipboardClearValue(int count) {
    return 'النص السري بيتمسح بعد $count ثانية';
  }

  @override
  String get changeMasterPassword => 'تغيير كلمة السر الرئيسية';

  @override
  String get data => 'البيانات';

  @override
  String get profilesShortHelp => 'شخصي، شغل... كل واحد بمفاتيحه';

  @override
  String get backupShortHelp => 'تصدير واسترجاع نسخة متشفّرة';

  @override
  String get appearance => 'الشكل';

  @override
  String get language => 'اللغة';

  @override
  String get followPhone => 'زي الموبايل';

  @override
  String get theme => 'الوضع';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'غامق';

  @override
  String get about => 'عن التطبيق';

  @override
  String get aboutBody =>
      'مفتوح المصدر (GPL-3.0). من غير إنترنت ولا تتبّع ولا إعلانات.';

  @override
  String get sourceCode => 'الكود المصدري';

  @override
  String get releaseKey => 'بصمة مفتاح توقيع الإصدارات';

  @override
  String get license => 'الرخصة';

  @override
  String get dangerZone => 'منطقة خطر';

  @override
  String get wipeHelp => 'بيمسح المفاتيح والبروفايلات من الموبايل ده';
}
