import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'شِن'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In ar, this message translates to:
  /// **'مفاتيح PGP بتاعتك في الحفظ والصون — من غير إنترنت.'**
  String get tagline;

  /// No description provided for @errUnknown.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة. جرّب تاني.'**
  String get errUnknown;

  /// No description provided for @errWrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر غلط.'**
  String get errWrongPassword;

  /// No description provided for @errLockedOut.
  ///
  /// In ar, this message translates to:
  /// **'محاولات غلط كتير.'**
  String get errLockedOut;

  /// No description provided for @errLocked.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق اتقفل. افتحه تاني.'**
  String get errLocked;

  /// No description provided for @errProfileLocked.
  ///
  /// In ar, this message translates to:
  /// **'البروفايل ده مقفول بكلمة سر. افتحه الأول.'**
  String get errProfileLocked;

  /// No description provided for @errProfileLockedNamed.
  ///
  /// In ar, this message translates to:
  /// **'افتح بروفايل «{name}» الأول وبعدين جرّب تاني.'**
  String errProfileLockedNamed(String name);

  /// No description provided for @errKeystore.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح الجهاز مش موجود (يمكن البيانات اتنقلت من موبايل تاني). البيانات دي مش هتتفتح على الموبايل ده.'**
  String get errKeystore;

  /// No description provided for @errBadData.
  ///
  /// In ar, this message translates to:
  /// **'البيانات دي مش OpenPGP أو بايظة.'**
  String get errBadData;

  /// No description provided for @errIntegrity.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة دي اتلعب فيها أو بايظة — اترفضت ومحدش اتحفظ منها حاجة.'**
  String get errIntegrity;

  /// No description provided for @errNoKey.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مفتاح عندك يفك الرسالة دي.'**
  String get errNoKey;

  /// No description provided for @errCannotEncrypt.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح واحد من المستلمين منتهي أو ملغي أو مينفعش يشفّر.'**
  String get errCannotEncrypt;

  /// No description provided for @errCannotSign.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح ده مينفعش يوقّع (منتهي أو ملغي).'**
  String get errCannotSign;

  /// No description provided for @errNotFound.
  ///
  /// In ar, this message translates to:
  /// **'مش موجود.'**
  String get errNotFound;

  /// No description provided for @errExists.
  ///
  /// In ar, this message translates to:
  /// **'موجود قبل كده.'**
  String get errExists;

  /// No description provided for @errTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'كبير زيادة عن اللزوم.'**
  String get errTooLarge;

  /// No description provided for @errInvalid.
  ///
  /// In ar, this message translates to:
  /// **'في بيانات ناقصة أو غلط.'**
  String get errInvalid;

  /// No description provided for @errEncryptedNotSigned.
  ///
  /// In ar, this message translates to:
  /// **'دي رسالة متشفّرة — استخدم «فك / تحقق».'**
  String get errEncryptedNotSigned;

  /// No description provided for @errNotBackup.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده مش نسخة احتياطية من شِن.'**
  String get errNotBackup;

  /// No description provided for @errCancelled.
  ///
  /// In ar, this message translates to:
  /// **'اتلغت.'**
  String get errCancelled;

  /// No description provided for @errIo.
  ///
  /// In ar, this message translates to:
  /// **'مش قادر يقرا أو يكتب الملف.'**
  String get errIo;

  /// No description provided for @errBioInvalidated.
  ///
  /// In ar, this message translates to:
  /// **'البصمات اللي على الموبايل اتغيّرت، فالفتح بالبصمة اتقفل. افتح بكلمة السر وفعّله تاني.'**
  String get errBioInvalidated;

  /// No description provided for @errBioUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الفتح بالبصمة مش متفعّل.'**
  String get errBioUnavailable;

  /// No description provided for @tryAgainIn.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تاني بعد {time}.'**
  String tryAgainIn(String time);

  /// No description provided for @seconds.
  ///
  /// In ar, this message translates to:
  /// **'{count} ثانية'**
  String seconds(int count);

  /// No description provided for @minutes.
  ///
  /// In ar, this message translates to:
  /// **'{count} دقيقة'**
  String minutes(int count);

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get ok;

  /// No description provided for @hide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In ar, this message translates to:
  /// **'إظهار'**
  String get show;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'اتنسخ'**
  String get copied;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'قفل'**
  String get close;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @saveFile.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كملف'**
  String get saveFile;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ'**
  String get saved;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @deleted.
  ///
  /// In ar, this message translates to:
  /// **'اتحذف'**
  String get deleted;

  /// No description provided for @add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add;

  /// No description provided for @paste.
  ///
  /// In ar, this message translates to:
  /// **'لصق'**
  String get paste;

  /// No description provided for @clear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clear;

  /// No description provided for @open.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get open;

  /// No description provided for @create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get create;

  /// No description provided for @export.
  ///
  /// In ar, this message translates to:
  /// **'تصدير'**
  String get export;

  /// No description provided for @import.
  ///
  /// In ar, this message translates to:
  /// **'استيراد'**
  String get import;

  /// No description provided for @current.
  ///
  /// In ar, this message translates to:
  /// **'الحالي'**
  String get current;

  /// No description provided for @iUnderstand.
  ///
  /// In ar, this message translates to:
  /// **'فاهم وعايز أكمّل'**
  String get iUnderstand;

  /// No description provided for @copiedSecure.
  ///
  /// In ar, this message translates to:
  /// **'اتنسخ — وهيتمسح من الحافظة بعد {count} ثانية'**
  String copiedSecure(int count);

  /// No description provided for @showQr.
  ///
  /// In ar, this message translates to:
  /// **'عرض QR'**
  String get showQr;

  /// No description provided for @invalid.
  ///
  /// In ar, this message translates to:
  /// **'مش صالح'**
  String get invalid;

  /// No description provided for @strengthVeryWeak.
  ///
  /// In ar, this message translates to:
  /// **'ضعيفة جداً'**
  String get strengthVeryWeak;

  /// No description provided for @strengthWeak.
  ///
  /// In ar, this message translates to:
  /// **'ضعيفة'**
  String get strengthWeak;

  /// No description provided for @strengthOk.
  ///
  /// In ar, this message translates to:
  /// **'مقبولة'**
  String get strengthOk;

  /// No description provided for @strengthGood.
  ///
  /// In ar, this message translates to:
  /// **'كويسة'**
  String get strengthGood;

  /// No description provided for @strengthStrong.
  ///
  /// In ar, this message translates to:
  /// **'قوية'**
  String get strengthStrong;

  /// No description provided for @keyPassphraseTitle.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سر المفتاح'**
  String get keyPassphraseTitle;

  /// No description provided for @keyPassphraseFor.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة سر المفتاح:\n{name}'**
  String keyPassphraseFor(String name);

  /// No description provided for @keyPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سر المفتاح'**
  String get keyPassphrase;

  /// No description provided for @masterPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر الرئيسية'**
  String get masterPasswordTitle;

  /// No description provided for @masterPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر الرئيسية'**
  String get masterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر لازم تكون {count} حروف على الأقل.'**
  String passwordTooShort(int count);

  /// No description provided for @passwordsDontMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتين السر مش زي بعض.'**
  String get passwordsDontMatch;

  /// No description provided for @newPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر الجديدة'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'اكتبها تاني للتأكيد'**
  String get confirmPassword;

  /// No description provided for @revoked.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get revoked;

  /// No description provided for @expired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get expired;

  /// No description provided for @expiresSoon.
  ///
  /// In ar, this message translates to:
  /// **'هيخلص قريب'**
  String get expiresSoon;

  /// No description provided for @defaultKey.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي'**
  String get defaultKey;

  /// No description provided for @noPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'من غير كلمة سر'**
  String get noPassphrase;

  /// No description provided for @verified.
  ///
  /// In ar, this message translates to:
  /// **'متأكد منه'**
  String get verified;

  /// No description provided for @allProfiles.
  ///
  /// In ar, this message translates to:
  /// **'كل البروفايلات'**
  String get allProfiles;

  /// No description provided for @sigGoodVerified.
  ///
  /// In ar, this message translates to:
  /// **'توقيع سليم من {name}'**
  String sigGoodVerified(String name);

  /// No description provided for @sigByMe.
  ///
  /// In ar, this message translates to:
  /// **'التوقيع ده بمفتاح من مفاتيحك.'**
  String get sigByMe;

  /// No description provided for @sigGoodVerifiedBody.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة متغيّرتش، وانت متأكد إن المفتاح ده بتاع الشخص ده.'**
  String get sigGoodVerifiedBody;

  /// No description provided for @sigGoodUnverified.
  ///
  /// In ar, this message translates to:
  /// **'التوقيع سليم من {name} — بس لسه متأكدتش من المفتاح'**
  String sigGoodUnverified(String name);

  /// No description provided for @sigGoodUnverifiedBody.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة متغيّرتش، بس لسه متأكدتش إن المفتاح ده فعلاً بتاع الشخص ده. قارن البصمة معاه (وش لوش أو بالـ QR).'**
  String get sigGoodUnverifiedBody;

  /// No description provided for @sigUnknown.
  ///
  /// In ar, this message translates to:
  /// **'موقّعة بمفتاح مش عندك'**
  String get sigUnknown;

  /// No description provided for @sigUnknownBody.
  ///
  /// In ar, this message translates to:
  /// **'مش هنقدر نتأكد من التوقيع غير لما تضيف المفتاح العام بتاع اللي بعت ({keyId}).'**
  String sigUnknownBody(String keyId);

  /// No description provided for @sigBad.
  ///
  /// In ar, this message translates to:
  /// **'التوقيع غلط!'**
  String get sigBad;

  /// No description provided for @sigBadBody.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة اتغيّرت بعد ما اتوقّعت، أو التوقيع مزوّر. متثقش في المحتوى ده.'**
  String get sigBadBody;

  /// No description provided for @signedOn.
  ///
  /// In ar, this message translates to:
  /// **'اتوقّعت يوم {date}'**
  String signedOn(String date);

  /// No description provided for @notSigned.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة دي مش موقّعة — مش هنعرف مين اللي بعتها.'**
  String get notSigned;

  /// No description provided for @noRecipients.
  ///
  /// In ar, this message translates to:
  /// **'مفيش جهات اتصال تقدر تشفّر لها. ضيف مفاتيح الناس من «جهات الاتصال».'**
  String get noRecipients;

  /// No description provided for @contacts.
  ///
  /// In ar, this message translates to:
  /// **'جهات الاتصال'**
  String get contacts;

  /// No description provided for @myKeys.
  ///
  /// In ar, this message translates to:
  /// **'مفاتيحي'**
  String get myKeys;

  /// No description provided for @hiddenUnusable.
  ///
  /// In ar, this message translates to:
  /// **'{count} مفتاح متخبّي لأنه منتهي أو ملغي.'**
  String hiddenUnusable(int count);

  /// No description provided for @selectedCount.
  ///
  /// In ar, this message translates to:
  /// **'تم ({count})'**
  String selectedCount(int count);

  /// No description provided for @chooseSigningKey.
  ///
  /// In ar, this message translates to:
  /// **'اختار المفتاح اللي هتوقّع بيه'**
  String get chooseSigningKey;

  /// No description provided for @defaultProfileName.
  ///
  /// In ar, this message translates to:
  /// **'شخصي'**
  String get defaultProfileName;

  /// No description provided for @nameRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم.'**
  String get nameRequired;

  /// No description provided for @introOffline.
  ///
  /// In ar, this message translates to:
  /// **'كل حاجة على موبايلك بس: مفيش إنترنت ولا حساب ولا سيرفر.'**
  String get introOffline;

  /// No description provided for @introProfiles.
  ///
  /// In ar, this message translates to:
  /// **'بروفايلات منفصلة (شخصي، شغل...) كل واحد بمفاتيحه وجهات اتصاله.'**
  String get introProfiles;

  /// No description provided for @introStandard.
  ///
  /// In ar, this message translates to:
  /// **'OpenPGP قياسي: بيتفاهم مع كيلوباترا وgpg وThunderbird وأي برنامج تاني.'**
  String get introStandard;

  /// No description provided for @setupTitle.
  ///
  /// In ar, this message translates to:
  /// **'يلا نبدأ'**
  String get setupTitle;

  /// No description provided for @firstProfileName.
  ///
  /// In ar, this message translates to:
  /// **'اسم أول بروفايل'**
  String get firstProfileName;

  /// No description provided for @masterPasswordWarning.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر الرئيسية بتقفل التطبيق كله. لو نسيتها مفيش أي طريقة ترجّع بيها البيانات — فاختار حاجة تفتكرها، وخد نسخة احتياطية من الإعدادات.'**
  String get masterPasswordWarning;

  /// No description provided for @createVault.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get createVault;

  /// No description provided for @bioTitle.
  ///
  /// In ar, this message translates to:
  /// **'افتح شِن'**
  String get bioTitle;

  /// No description provided for @bioSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'بصمتك بتفك مفتاح الخزنة'**
  String get bioSubtitle;

  /// No description provided for @usePassword.
  ///
  /// In ar, this message translates to:
  /// **'بكلمة السر'**
  String get usePassword;

  /// No description provided for @locked.
  ///
  /// In ar, this message translates to:
  /// **'شِن مقفول'**
  String get locked;

  /// No description provided for @lockedHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة السر الرئيسية عشان تفتح.'**
  String get lockedHint;

  /// No description provided for @unlock.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get unlock;

  /// No description provided for @unlockWithBio.
  ///
  /// In ar, this message translates to:
  /// **'الفتح بالبصمة'**
  String get unlockWithBio;

  /// No description provided for @lockNow.
  ///
  /// In ar, this message translates to:
  /// **'قفل دلوقتي'**
  String get lockNow;

  /// No description provided for @tools.
  ///
  /// In ar, this message translates to:
  /// **'الأدوات'**
  String get tools;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @profileLockedTitle.
  ///
  /// In ar, this message translates to:
  /// **'بروفايل «{name}» مقفول'**
  String profileLockedTitle(String name);

  /// No description provided for @profileLockedBody.
  ///
  /// In ar, this message translates to:
  /// **'البروفايل ده ليه كلمة سر لوحده. افتحه عشان تشوف مفاتيحه وجهات اتصاله.'**
  String get profileLockedBody;

  /// No description provided for @unlockProfile.
  ///
  /// In ar, this message translates to:
  /// **'فتح «{name}»'**
  String unlockProfile(String name);

  /// No description provided for @profilePassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سر البروفايل'**
  String get profilePassword;

  /// No description provided for @profiles.
  ///
  /// In ar, this message translates to:
  /// **'البروفايلات'**
  String get profiles;

  /// No description provided for @profileCounts.
  ///
  /// In ar, this message translates to:
  /// **'مفاتيح: {keys} · جهات اتصال: {contacts}'**
  String profileCounts(int keys, int contacts);

  /// No description provided for @profileLockedShort.
  ///
  /// In ar, this message translates to:
  /// **'مقفول'**
  String get profileLockedShort;

  /// No description provided for @manageProfiles.
  ///
  /// In ar, this message translates to:
  /// **'إدارة البروفايلات'**
  String get manageProfiles;

  /// No description provided for @newKey.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح جديد'**
  String get newKey;

  /// No description provided for @noKeysTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه معندكش مفاتيح'**
  String get noKeysTitle;

  /// No description provided for @noKeysBody.
  ///
  /// In ar, this message translates to:
  /// **'اعمل مفتاح جديد عشان الناس تقدر تبعتلك رسايل متشفّرة وتتأكد من توقيعك، أو استورد مفتاح عندك.'**
  String get noKeysBody;

  /// No description provided for @importKey.
  ///
  /// In ar, this message translates to:
  /// **'استيراد مفتاح'**
  String get importKey;

  /// No description provided for @myKeysCount.
  ///
  /// In ar, this message translates to:
  /// **'مفاتيحي ({count})'**
  String myKeysCount(int count);

  /// No description provided for @nameOrEmailRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم أو إيميل على الأقل.'**
  String get nameOrEmailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل ده مش مكتوب صح.'**
  String get invalidEmail;

  /// No description provided for @invalidCharacters.
  ///
  /// In ar, this message translates to:
  /// **'متستخدمش < > ( ) في الاسم أو التعليق.'**
  String get invalidCharacters;

  /// No description provided for @keyCreatedTitle.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح جاهز'**
  String get keyCreatedTitle;

  /// No description provided for @keyCreatedBody.
  ///
  /// In ar, this message translates to:
  /// **'دلوقتي:\n• شارك المفتاح العام مع الناس عشان يقدروا يشفّرولك.\n• خد نسخة احتياطية (الإعدادات ← النسخ الاحتياطي) عشان لو الموبايل ضاع.\n• اتعملت شهادة إلغاء لوحدها — احفظها في مكان آمن.'**
  String get keyCreatedBody;

  /// No description provided for @newKeyIntro.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح ليه جزئين: جزء عام بتديه للناس، وجزء سري بيفضل على موبايلك ومحمي بكلمة سر.'**
  String get newKeyIntro;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @emailOptional.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل (اختياري)'**
  String get emailOptional;

  /// No description provided for @commentOptional.
  ///
  /// In ar, this message translates to:
  /// **'تعليق (اختياري)'**
  String get commentOptional;

  /// No description provided for @commentHelp.
  ///
  /// In ar, this message translates to:
  /// **'مثلاً: شغل — بيظهر جنب اسمك'**
  String get commentHelp;

  /// No description provided for @keyPassphraseHelp.
  ///
  /// In ar, this message translates to:
  /// **'بتحمي الجزء السري حتى لو حد خد نسخة منه. هتطلبها وانت بتفك أو بتوقّع.'**
  String get keyPassphraseHelp;

  /// No description provided for @noPassphraseOption.
  ///
  /// In ar, this message translates to:
  /// **'من غير كلمة سر'**
  String get noPassphraseOption;

  /// No description provided for @noPassphraseWarning.
  ///
  /// In ar, this message translates to:
  /// **'مش منصوح بيه: أي حد معاه نسخة من المفتاح يقدر يستخدمه.'**
  String get noPassphraseWarning;

  /// No description provided for @expiry.
  ///
  /// In ar, this message translates to:
  /// **'الصلاحية'**
  String get expiry;

  /// No description provided for @never.
  ///
  /// In ar, this message translates to:
  /// **'مبيخلصش'**
  String get never;

  /// No description provided for @yearsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} سنة'**
  String yearsCount(int count);

  /// No description provided for @expiryHelp.
  ///
  /// In ar, this message translates to:
  /// **'لو ضاع منك المفتاح، الصلاحية بتخلّيه يبطل لوحده. وتقدر تمدّها في أي وقت.'**
  String get expiryHelp;

  /// No description provided for @advanced.
  ///
  /// In ar, this message translates to:
  /// **'متقدم'**
  String get advanced;

  /// No description provided for @algoCv25519.
  ///
  /// In ar, this message translates to:
  /// **'Ed25519 / X25519 (منصوح بيه)'**
  String get algoCv25519;

  /// No description provided for @algoCv25519Help.
  ///
  /// In ar, this message translates to:
  /// **'حديث وسريع وشغال مع gpg وكيلوباترا وأي برنامج.'**
  String get algoCv25519Help;

  /// No description provided for @algoRsa.
  ///
  /// In ar, this message translates to:
  /// **'RSA 4096'**
  String get algoRsa;

  /// No description provided for @algoRsaHelp.
  ///
  /// In ar, this message translates to:
  /// **'للأنظمة القديمة اللي مبتفهمش Ed25519. أبطأ وأكبر.'**
  String get algoRsaHelp;

  /// No description provided for @algoV6.
  ///
  /// In ar, this message translates to:
  /// **'OpenPGP v6 (RFC 9580)'**
  String get algoV6;

  /// No description provided for @algoV6Help.
  ///
  /// In ar, this message translates to:
  /// **'أحدث صيغة. gpg وكيلوباترا لسه مبيدعموهاش.'**
  String get algoV6Help;

  /// No description provided for @createKey.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء المفتاح'**
  String get createKey;

  /// No description provided for @rsaSlow.
  ///
  /// In ar, this message translates to:
  /// **'مفاتيح RSA بتاخد وقت... استنى شوية.'**
  String get rsaSlow;

  /// No description provided for @sharePublicKey.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة المفتاح العام'**
  String get sharePublicKey;

  /// No description provided for @showAsQr.
  ///
  /// In ar, this message translates to:
  /// **'عرض كـ QR'**
  String get showAsQr;

  /// No description provided for @showAsQrHelp.
  ///
  /// In ar, this message translates to:
  /// **'الشخص اللي قدامك يمسحه بشِن'**
  String get showAsQrHelp;

  /// No description provided for @qrKeyCaption.
  ///
  /// In ar, this message translates to:
  /// **'ده مفتاحك العام كامل. اللي يمسحه بشِن بيضيفك ويتعلّم إنه متأكد منك.'**
  String get qrKeyCaption;

  /// No description provided for @changeExpiry.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصلاحية'**
  String get changeExpiry;

  /// No description provided for @yearsFromNow.
  ///
  /// In ar, this message translates to:
  /// **'{count} سنة من النهارده'**
  String yearsFromNow(int count);

  /// No description provided for @updatedShareAgain.
  ///
  /// In ar, this message translates to:
  /// **'اتحدّث — شارك المفتاح العام تاني عشان الناس تاخد التعديل.'**
  String get updatedShareAgain;

  /// No description provided for @changeKeyPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة سر المفتاح'**
  String get changeKeyPassphrase;

  /// No description provided for @changeKeyPassphraseBody.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر الجديدة بتحمي الجزء السري من المفتاح.'**
  String get changeKeyPassphraseBody;

  /// No description provided for @passphraseChanged.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر اتغيّرت'**
  String get passphraseChanged;

  /// No description provided for @addIdentity.
  ///
  /// In ar, this message translates to:
  /// **'إضافة هوية (اسم / إيميل)'**
  String get addIdentity;

  /// No description provided for @identityHint.
  ///
  /// In ar, this message translates to:
  /// **'الاسم <email@example.com>'**
  String get identityHint;

  /// No description provided for @exportSecretTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصدير المفتاح السري'**
  String get exportSecretTitle;

  /// No description provided for @exportSecretBody.
  ///
  /// In ar, this message translates to:
  /// **'ده الجزء اللي محدش المفروض يشوفه غيرك. حتى لو متشفّر بكلمة سره، احفظه بس في مكان آمن (فلاشة معاك مثلاً) ومتبعتوش لحد.'**
  String get exportSecretBody;

  /// No description provided for @masterPasswordForExport.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة السر الرئيسية عشان تصدّر.'**
  String get masterPasswordForExport;

  /// No description provided for @revocationCert.
  ///
  /// In ar, this message translates to:
  /// **'شهادة الإلغاء'**
  String get revocationCert;

  /// No description provided for @revocationCertBody.
  ///
  /// In ar, this message translates to:
  /// **'لو المفتاح اتسرق أو ضاع، الشهادة دي بتعرّف الناس إنه ملغي — حتى لو ملكش وصول للمفتاح نفسه. احفظها في مكان آمن برا الموبايل (أي حد معاه الشهادة يقدر يلغي مفتاحك).'**
  String get revocationCertBody;

  /// No description provided for @revokeTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المفتاح'**
  String get revokeTitle;

  /// No description provided for @revokeBody.
  ///
  /// In ar, this message translates to:
  /// **'بعد الإلغاء محدش هيقدر يشفّرلك بالمفتاح ده تاني، ومينفعش ترجع فيه. لازم تشارك المفتاح العام بعدها عشان الناس تعرف.'**
  String get revokeBody;

  /// No description provided for @revoke.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المفتاح'**
  String get revoke;

  /// No description provided for @revokeReason.
  ///
  /// In ar, this message translates to:
  /// **'ليه بتلغيه؟'**
  String get revokeReason;

  /// No description provided for @reasonCompromised.
  ///
  /// In ar, this message translates to:
  /// **'اتسرق أو اتكشف'**
  String get reasonCompromised;

  /// No description provided for @reasonSuperseded.
  ///
  /// In ar, this message translates to:
  /// **'عملت مفتاح جديد بداله'**
  String get reasonSuperseded;

  /// No description provided for @reasonRetired.
  ///
  /// In ar, this message translates to:
  /// **'مبقتش بستخدمه'**
  String get reasonRetired;

  /// No description provided for @reasonNone.
  ///
  /// In ar, this message translates to:
  /// **'من غير سبب'**
  String get reasonNone;

  /// No description provided for @revokedShareNow.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح اتلغى — شارك المفتاح العام دلوقتي عشان الناس تعرف.'**
  String get revokedShareNow;

  /// No description provided for @deleteKeyTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف المفتاح'**
  String get deleteKeyTitle;

  /// No description provided for @deleteKeyBody.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح السري هيتمسح من الموبايل. لو معندكش نسخة احتياطية، أي رسالة متشفّرة ليه هتضيع للأبد.'**
  String get deleteKeyBody;

  /// No description provided for @masterPasswordForDelete.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة السر الرئيسية عشان تحذف.'**
  String get masterPasswordForDelete;

  /// No description provided for @note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get note;

  /// No description provided for @keyDetails.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح'**
  String get keyDetails;

  /// No description provided for @keyRevokedNotice.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح ده اتلغى. محدش يقدر يشفّرله ومينفعش يوقّع، بس لسه تقدر تفك بيه الرسايل القديمة.'**
  String get keyRevokedNotice;

  /// No description provided for @keyExpiredNotice.
  ///
  /// In ar, this message translates to:
  /// **'صلاحية المفتاح خلصت. مدّها من «تغيير الصلاحية» وشارك المفتاح العام تاني.'**
  String get keyExpiredNotice;

  /// No description provided for @fingerprint.
  ///
  /// In ar, this message translates to:
  /// **'البصمة'**
  String get fingerprint;

  /// No description provided for @qrFingerprintCaption.
  ///
  /// In ar, this message translates to:
  /// **'اللي قدامك يمسح الـ QR ده بشِن عشان يتأكد إن المفتاح اللي عنده هو مفتاحك.'**
  String get qrFingerprintCaption;

  /// No description provided for @manage.
  ///
  /// In ar, this message translates to:
  /// **'إدارة'**
  String get manage;

  /// No description provided for @makeDefault.
  ///
  /// In ar, this message translates to:
  /// **'خليه الافتراضي'**
  String get makeDefault;

  /// No description provided for @makeDefaultHelp.
  ///
  /// In ar, this message translates to:
  /// **'بنوقّع بيه ونشفّر لنفسنا بيه تلقائياً'**
  String get makeDefaultHelp;

  /// No description provided for @backupAndSafety.
  ///
  /// In ar, this message translates to:
  /// **'نسخ احتياطي وأمان'**
  String get backupAndSafety;

  /// No description provided for @exportSecret.
  ///
  /// In ar, this message translates to:
  /// **'تصدير المفتاح السري'**
  String get exportSecret;

  /// No description provided for @exportSecretHelp.
  ///
  /// In ar, this message translates to:
  /// **'ملف .asc لنقل المفتاح لكيلوباترا أو جهاز تاني'**
  String get exportSecretHelp;

  /// No description provided for @revocationCertHelp.
  ///
  /// In ar, this message translates to:
  /// **'احفظها برا الموبايل لو المفتاح اتسرق'**
  String get revocationCertHelp;

  /// No description provided for @revokeHelp.
  ///
  /// In ar, this message translates to:
  /// **'لو المفتاح اتسرق أو بطّلت تستخدمه'**
  String get revokeHelp;

  /// No description provided for @deleteKey.
  ///
  /// In ar, this message translates to:
  /// **'حذف المفتاح'**
  String get deleteKey;

  /// No description provided for @flagCertify.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد'**
  String get flagCertify;

  /// No description provided for @flagSign.
  ///
  /// In ar, this message translates to:
  /// **'توقيع'**
  String get flagSign;

  /// No description provided for @flagEncrypt.
  ///
  /// In ar, this message translates to:
  /// **'تشفير'**
  String get flagEncrypt;

  /// No description provided for @flagAuth.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get flagAuth;

  /// No description provided for @details.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get details;

  /// No description provided for @algorithm.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get algorithm;

  /// No description provided for @created.
  ///
  /// In ar, this message translates to:
  /// **'اتعمل'**
  String get created;

  /// No description provided for @expires.
  ///
  /// In ar, this message translates to:
  /// **'بيخلص'**
  String get expires;

  /// No description provided for @keyIdLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم المفتاح'**
  String get keyIdLabel;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get version;

  /// No description provided for @identities.
  ///
  /// In ar, this message translates to:
  /// **'الهويات'**
  String get identities;

  /// No description provided for @subkeys.
  ///
  /// In ar, this message translates to:
  /// **'المفاتيح الفرعية'**
  String get subkeys;

  /// No description provided for @fromClipboard.
  ///
  /// In ar, this message translates to:
  /// **'من الحافظة'**
  String get fromClipboard;

  /// No description provided for @pasteText.
  ///
  /// In ar, this message translates to:
  /// **'لصق نص'**
  String get pasteText;

  /// No description provided for @fromFile.
  ///
  /// In ar, this message translates to:
  /// **'من ملف'**
  String get fromFile;

  /// No description provided for @scanQr.
  ///
  /// In ar, this message translates to:
  /// **'مسح QR'**
  String get scanQr;

  /// No description provided for @scanQrHelp.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح عام أو بصمة من موبايل الشخص قدامك'**
  String get scanQrHelp;

  /// No description provided for @clipboardEmpty.
  ///
  /// In ar, this message translates to:
  /// **'الحافظة فاضية.'**
  String get clipboardEmpty;

  /// No description provided for @pasteKeyHere.
  ///
  /// In ar, this message translates to:
  /// **'الصق المفتاح هنا (-----BEGIN PGP...)'**
  String get pasteKeyHere;

  /// No description provided for @qrNotKey.
  ///
  /// In ar, this message translates to:
  /// **'الـ QR ده مش مفتاح ولا بصمة.'**
  String get qrNotKey;

  /// No description provided for @fingerprintUnknownTitle.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح ده مش عندك'**
  String get fingerprintUnknownTitle;

  /// No description provided for @fingerprintUnknownBody.
  ///
  /// In ar, this message translates to:
  /// **'البصمة:\n{fp}\n\nضيف المفتاح العام بتاع الشخص الأول (ملف أو QR المفتاح كامل)، وبعدين امسح البصمة تاني عشان تتأكد.'**
  String fingerprintUnknownBody(String fp);

  /// No description provided for @thisIsYourKey.
  ///
  /// In ar, this message translates to:
  /// **'ده مفتاح من مفاتيحك.'**
  String get thisIsYourKey;

  /// No description provided for @verifiedTitle.
  ///
  /// In ar, this message translates to:
  /// **'اتأكدنا'**
  String get verifiedTitle;

  /// No description provided for @verifiedByQr.
  ///
  /// In ar, this message translates to:
  /// **'البصمة اللي مسحتها مطابقة للمفتاح اللي عندك، فالجهة دي اتعلّمت إنها متأكد منها.'**
  String get verifiedByQr;

  /// No description provided for @importDone.
  ///
  /// In ar, this message translates to:
  /// **'اتضاف {added} واتحدّث {updated}'**
  String importDone(int added, int updated);

  /// No description provided for @importKeysTitle.
  ///
  /// In ar, this message translates to:
  /// **'استيراد مفاتيح'**
  String get importKeysTitle;

  /// No description provided for @importFound.
  ///
  /// In ar, this message translates to:
  /// **'لقينا {count} مفتاح. اختار اللي عايز تضيفه:'**
  String importFound(int count);

  /// No description provided for @alreadyHaveUpdate.
  ///
  /// In ar, this message translates to:
  /// **'موجود عندك — هيتحدّث بس (مفيش حاجة هتتمسح)'**
  String get alreadyHaveUpdate;

  /// No description provided for @secretGoesToMyKeys.
  ///
  /// In ar, this message translates to:
  /// **'المفاتيح السرية بتتضاف لـ «مفاتيحي» في البروفايل ده.'**
  String get secretGoesToMyKeys;

  /// No description provided for @whereToShow.
  ///
  /// In ar, this message translates to:
  /// **'يظهر فين'**
  String get whereToShow;

  /// No description provided for @thisProfileOnly.
  ///
  /// In ar, this message translates to:
  /// **'بروفايل «{name}» بس'**
  String thisProfileOnly(String name);

  /// No description provided for @thisProfileOnlyHelp.
  ///
  /// In ar, this message translates to:
  /// **'مش هيظهر في البروفايلات التانية'**
  String get thisProfileOnlyHelp;

  /// No description provided for @allProfilesHelp.
  ///
  /// In ar, this message translates to:
  /// **'هيظهر في كل البروفايلات'**
  String get allProfilesHelp;

  /// No description provided for @importQrVerified.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح جه بـ QR من موبايل الشخص نفسه، فهيتعلّم إنه متأكد منه.'**
  String get importQrVerified;

  /// No description provided for @verifyAfterImport.
  ///
  /// In ar, this message translates to:
  /// **'بعد الاستيراد قارن البصمة مع صاحب المفتاح (أو امسح الـ QR بتاعه) عشان تتأكد إنه بتاعه فعلاً.'**
  String get verifyAfterImport;

  /// No description provided for @addContact.
  ///
  /// In ar, this message translates to:
  /// **'إضافة جهة اتصال'**
  String get addContact;

  /// No description provided for @noContactsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش جهات اتصال'**
  String get noContactsTitle;

  /// No description provided for @noContactsBody.
  ///
  /// In ar, this message translates to:
  /// **'ضيف المفتاح العام بتاع أي حد عشان تشفّرله رسايل وتتأكد من توقيعاته.'**
  String get noContactsBody;

  /// No description provided for @searchContacts.
  ///
  /// In ar, this message translates to:
  /// **'دوّر بالاسم أو الإيميل أو البصمة'**
  String get searchContacts;

  /// No description provided for @contactsCount.
  ///
  /// In ar, this message translates to:
  /// **'جهات الاتصال ({count})'**
  String contactsCount(int count);

  /// No description provided for @compareTitle.
  ///
  /// In ar, this message translates to:
  /// **'قارن البصمة'**
  String get compareTitle;

  /// No description provided for @compareBody.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من الشخص يقرالك البصمة من موبايله (وش لوش أو في مكالمة)، وقارنها حرف حرف:\n\n{fp}'**
  String compareBody(String fp);

  /// No description provided for @theyMatch.
  ///
  /// In ar, this message translates to:
  /// **'مطابقة'**
  String get theyMatch;

  /// No description provided for @markedVerified.
  ///
  /// In ar, this message translates to:
  /// **'اتعلّم إنه متأكد منه'**
  String get markedVerified;

  /// No description provided for @needOwnKey.
  ///
  /// In ar, this message translates to:
  /// **'محتاج مفتاح من مفاتيحك (مش منتهي) الأول.'**
  String get needOwnKey;

  /// No description provided for @certifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'التوقيع على المفتاح'**
  String get certifyTitle;

  /// No description provided for @certifyBody.
  ///
  /// In ar, this message translates to:
  /// **'هتوقّع بمفتاحك إنك متأكد إن المفتاح ده بتاع الشخص ده. لو شاركت المفتاح ده بعد كده، اللي يثق فيك هيعرف إنك اتأكدت منه. اعملها بس لو قارنت البصمة بنفسك.'**
  String get certifyBody;

  /// No description provided for @certify.
  ///
  /// In ar, this message translates to:
  /// **'توقيع'**
  String get certify;

  /// No description provided for @certified.
  ///
  /// In ar, this message translates to:
  /// **'اتوقّع على المفتاح'**
  String get certified;

  /// No description provided for @deleteContactTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف جهة الاتصال'**
  String get deleteContactTitle;

  /// No description provided for @deleteContactBody.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح العام بتاعه هيتشال من البروفايل ده.'**
  String get deleteContactBody;

  /// No description provided for @deleteContactSharedBody.
  ///
  /// In ar, this message translates to:
  /// **'جهة الاتصال دي ظاهرة في كل البروفايلات — هتتشال منهم كلهم.'**
  String get deleteContactSharedBody;

  /// No description provided for @contact.
  ///
  /// In ar, this message translates to:
  /// **'جهة اتصال'**
  String get contact;

  /// No description provided for @contactVerified.
  ///
  /// In ar, this message translates to:
  /// **'متأكد إن المفتاح ده بتاعه'**
  String get contactVerified;

  /// No description provided for @contactNotVerified.
  ///
  /// In ar, this message translates to:
  /// **'لسه متأكدتش من المفتاح ده'**
  String get contactNotVerified;

  /// No description provided for @contactVerifiedBody.
  ///
  /// In ar, this message translates to:
  /// **'انت قارنت البصمة مع صاحبها. التوقيعات بالمفتاح ده هتظهر خضرا.'**
  String get contactVerifiedBody;

  /// No description provided for @contactNotVerifiedBody.
  ///
  /// In ar, this message translates to:
  /// **'أي حد ممكن يعمل مفتاح باسم أي حد. قبل ما تثق فيه، اتأكد من البصمة مع صاحبها نفسه.'**
  String get contactNotVerifiedBody;

  /// No description provided for @scanTheirQr.
  ///
  /// In ar, this message translates to:
  /// **'امسح الـ QR بتاعه'**
  String get scanTheirQr;

  /// No description provided for @compareManually.
  ///
  /// In ar, this message translates to:
  /// **'قارنت البصمة بنفسي'**
  String get compareManually;

  /// No description provided for @certifyWithMyKey.
  ///
  /// In ar, this message translates to:
  /// **'وقّع عليه بمفتاحي'**
  String get certifyWithMyKey;

  /// No description provided for @unmarkVerified.
  ///
  /// In ar, this message translates to:
  /// **'شيل علامة «متأكد منه»'**
  String get unmarkVerified;

  /// No description provided for @showInAllProfiles.
  ///
  /// In ar, this message translates to:
  /// **'يظهر في كل البروفايلات'**
  String get showInAllProfiles;

  /// No description provided for @updateKey.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المفتاح'**
  String get updateKey;

  /// No description provided for @updateKeyHelp.
  ///
  /// In ar, this message translates to:
  /// **'لو صاحبه بعتلك نسخة أحدث (صلاحية جديدة / إلغاء)'**
  String get updateKeyHelp;

  /// No description provided for @deleteContact.
  ///
  /// In ar, this message translates to:
  /// **'حذف جهة الاتصال'**
  String get deleteContact;

  /// No description provided for @messagePasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سر الرسالة'**
  String get messagePasswordTitle;

  /// No description provided for @messagePasswordBody.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة دي متشفّرة بكلمة سر (مش بمفتاح).'**
  String get messagePasswordBody;

  /// No description provided for @messagePassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر'**
  String get messagePassword;

  /// No description provided for @otherProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة لبروفايل تاني'**
  String get otherProfileTitle;

  /// No description provided for @otherProfileBody.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة دي متشفّرة لمفتاح في بروفايل «{name}». غيّر البروفايل من فوق وجرّب تاني.'**
  String otherProfileBody(String name);

  /// No description provided for @notForYouTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة دي مش ليك'**
  String get notForYouTitle;

  /// No description provided for @notForYouHidden.
  ///
  /// In ar, this message translates to:
  /// **'المرسل خبّى أرقام المفاتيح، ومفيش مفتاح عندك عرف يفكها.'**
  String get notForYouHidden;

  /// No description provided for @notForYouBody.
  ///
  /// In ar, this message translates to:
  /// **'متشفّرة لمفاتيح مش عندك:\n{ids}'**
  String notForYouBody(String ids);

  /// No description provided for @toPeople.
  ///
  /// In ar, this message translates to:
  /// **'لناس'**
  String get toPeople;

  /// No description provided for @withPassword.
  ///
  /// In ar, this message translates to:
  /// **'بكلمة سر'**
  String get withPassword;

  /// No description provided for @passwordModeHelp.
  ///
  /// In ar, this message translates to:
  /// **'أي حد معاه كلمة السر يقدر يفك — حتى لو معندوش شِن (gpg / كيلوباترا). ابعت كلمة السر بطريقة تانية غير الرسالة نفسها.'**
  String get passwordModeHelp;

  /// No description provided for @recipients.
  ///
  /// In ar, this message translates to:
  /// **'المستلمين'**
  String get recipients;

  /// No description provided for @noRecipientsChosen.
  ///
  /// In ar, this message translates to:
  /// **'اختار مستلم واحد على الأقل.'**
  String get noRecipientsChosen;

  /// No description provided for @unverifiedRecipientWarning.
  ///
  /// In ar, this message translates to:
  /// **'في مستلم لسه متأكدتش من مفتاحه — لو المفتاح مش بتاعه فعلاً حد تاني هيقدر يقرا الرسالة.'**
  String get unverifiedRecipientWarning;

  /// No description provided for @encryptToSelf.
  ///
  /// In ar, this message translates to:
  /// **'شفّر لنفسي كمان'**
  String get encryptToSelf;

  /// No description provided for @encryptToSelfHelp.
  ///
  /// In ar, this message translates to:
  /// **'عشان تقدر تقرا اللي بعته بعدين'**
  String get encryptToSelfHelp;

  /// No description provided for @signMessage.
  ///
  /// In ar, this message translates to:
  /// **'وقّع'**
  String get signMessage;

  /// No description provided for @signMessageHelp.
  ///
  /// In ar, this message translates to:
  /// **'المستلم يتأكد إنها منك ومتغيّرتش'**
  String get signMessageHelp;

  /// No description provided for @signingAs.
  ///
  /// In ar, this message translates to:
  /// **'بتوقّع كـ {name}'**
  String signingAs(String name);

  /// No description provided for @changeSigningKey.
  ///
  /// In ar, this message translates to:
  /// **'تغيير مفتاح التوقيع'**
  String get changeSigningKey;

  /// No description provided for @newMessagePasswordBody.
  ///
  /// In ar, this message translates to:
  /// **'اختار كلمة سر قوية، وابعتها للمستلم بطريقة تانية.'**
  String get newMessagePasswordBody;

  /// No description provided for @writeSomething.
  ///
  /// In ar, this message translates to:
  /// **'اكتب حاجة الأول.'**
  String get writeSomething;

  /// No description provided for @encryptedMessage.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة المتشفّرة'**
  String get encryptedMessage;

  /// No description provided for @encryptedMessageHelp.
  ///
  /// In ar, this message translates to:
  /// **'ابعتها بأي طريقة (واتساب، إيميل...). محدش يقدر يقراها غير المستلمين.'**
  String get encryptedMessageHelp;

  /// No description provided for @encryptText.
  ///
  /// In ar, this message translates to:
  /// **'تشفير نص'**
  String get encryptText;

  /// No description provided for @writeMessage.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الرسالة هنا'**
  String get writeMessage;

  /// No description provided for @encrypt.
  ///
  /// In ar, this message translates to:
  /// **'تشفير'**
  String get encrypt;

  /// No description provided for @pasteSomething.
  ///
  /// In ar, this message translates to:
  /// **'الصق رسالة أو توقيع الأول.'**
  String get pasteSomething;

  /// No description provided for @detachedNeedsText.
  ///
  /// In ar, this message translates to:
  /// **'ده توقيع منفصل: الصق النص الأصلي في الخانة اللي ظهرت وجرّب تاني.'**
  String get detachedNeedsText;

  /// No description provided for @notPgpText.
  ///
  /// In ar, this message translates to:
  /// **'النص ده مش رسالة OpenPGP.'**
  String get notPgpText;

  /// No description provided for @decryptVerify.
  ///
  /// In ar, this message translates to:
  /// **'فك / تحقق'**
  String get decryptVerify;

  /// No description provided for @decryptVerifyHelp.
  ///
  /// In ar, this message translates to:
  /// **'الصق رسالة متشفّرة، أو رسالة موقّعة، أو مفتاح عام — وشِن هيعرف يعمل إيه.'**
  String get decryptVerifyHelp;

  /// No description provided for @pasteMessage.
  ///
  /// In ar, this message translates to:
  /// **'-----BEGIN PGP MESSAGE-----'**
  String get pasteMessage;

  /// No description provided for @signedTextLabel.
  ///
  /// In ar, this message translates to:
  /// **'النص الأصلي'**
  String get signedTextLabel;

  /// No description provided for @signedTextHint.
  ///
  /// In ar, this message translates to:
  /// **'الصق النص اللي اتوقّع'**
  String get signedTextHint;

  /// No description provided for @signature.
  ///
  /// In ar, this message translates to:
  /// **'التوقيع'**
  String get signature;

  /// No description provided for @decryptedText.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة'**
  String get decryptedText;

  /// No description provided for @signedContent.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى'**
  String get signedContent;

  /// No description provided for @signedMessage.
  ///
  /// In ar, this message translates to:
  /// **'النص الموقّع'**
  String get signedMessage;

  /// No description provided for @signText.
  ///
  /// In ar, this message translates to:
  /// **'توقيع نص'**
  String get signText;

  /// No description provided for @signingKey.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح التوقيع'**
  String get signingKey;

  /// No description provided for @detachedSignature.
  ///
  /// In ar, this message translates to:
  /// **'توقيع منفصل'**
  String get detachedSignature;

  /// No description provided for @detachedSignatureHelp.
  ///
  /// In ar, this message translates to:
  /// **'التوقيع لوحده من غير النص (لملفات .sig)'**
  String get detachedSignatureHelp;

  /// No description provided for @sign.
  ///
  /// In ar, this message translates to:
  /// **'توقيع'**
  String get sign;

  /// No description provided for @chooseFileFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختار ملف الأول.'**
  String get chooseFileFirst;

  /// No description provided for @fileIsSignedOnly.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده موقّع بس (مش متشفّر) — استخدم «تحقق من ملف».'**
  String get fileIsSignedOnly;

  /// No description provided for @fileNotEncrypted.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده مش متشفّر بـ OpenPGP.'**
  String get fileNotEncrypted;

  /// No description provided for @chooseSignatureFile.
  ///
  /// In ar, this message translates to:
  /// **'اختار ملف التوقيع (.sig / .asc).'**
  String get chooseSignatureFile;

  /// No description provided for @encryptFile.
  ///
  /// In ar, this message translates to:
  /// **'تشفير ملف'**
  String get encryptFile;

  /// No description provided for @encryptFileHelp.
  ///
  /// In ar, this message translates to:
  /// **'أي نوع ملف وأي حجم. الملف المتشفّر بيتحفظ في المكان اللي تختاره.'**
  String get encryptFileHelp;

  /// No description provided for @decryptFile.
  ///
  /// In ar, this message translates to:
  /// **'فك ملف'**
  String get decryptFile;

  /// No description provided for @decryptFileHelp.
  ///
  /// In ar, this message translates to:
  /// **'ملف .pgp / .gpg / .asc. لو الملف اتلعب فيه، اللي اتكتب منه بيتمسح لوحده.'**
  String get decryptFileHelp;

  /// No description provided for @decrypt.
  ///
  /// In ar, this message translates to:
  /// **'فك التشفير'**
  String get decrypt;

  /// No description provided for @signFile.
  ///
  /// In ar, this message translates to:
  /// **'توقيع ملف'**
  String get signFile;

  /// No description provided for @signFileHelp.
  ///
  /// In ar, this message translates to:
  /// **'بيعمل ملف توقيع منفصل (.sig) تبعته جنب الملف.'**
  String get signFileHelp;

  /// No description provided for @verifyFile.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من ملف'**
  String get verifyFile;

  /// No description provided for @verifyFileHelp.
  ///
  /// In ar, this message translates to:
  /// **'اختار الملف وملف التوقيع بتاعه. لو الملف موقّع جوه نفسه، سيب التوقيع فاضي.'**
  String get verifyFileHelp;

  /// No description provided for @verify.
  ///
  /// In ar, this message translates to:
  /// **'تحقق'**
  String get verify;

  /// No description provided for @chooseFile.
  ///
  /// In ar, this message translates to:
  /// **'اختار ملف'**
  String get chooseFile;

  /// No description provided for @chooseSignatureFileOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملف التوقيع (.sig) — اختياري'**
  String get chooseSignatureFileOptional;

  /// No description provided for @asciiArmor.
  ///
  /// In ar, this message translates to:
  /// **'نص (ASCII armor)'**
  String get asciiArmor;

  /// No description provided for @asciiArmorHelp.
  ///
  /// In ar, this message translates to:
  /// **'ملف .asc نصي بدل .pgp — أكبر شوية بس يتبعت كنص'**
  String get asciiArmorHelp;

  /// No description provided for @savedAs.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ: {name}'**
  String savedAs(String name);

  /// No description provided for @text.
  ///
  /// In ar, this message translates to:
  /// **'نصوص'**
  String get text;

  /// No description provided for @encryptTextHelp.
  ///
  /// In ar, this message translates to:
  /// **'رسالة محدش يقراها غير اللي تختارهم'**
  String get encryptTextHelp;

  /// No description provided for @decryptVerifyShort.
  ///
  /// In ar, this message translates to:
  /// **'افتح رسالة، أو اتأكد من توقيع'**
  String get decryptVerifyShort;

  /// No description provided for @signTextHelp.
  ///
  /// In ar, this message translates to:
  /// **'الناس تتأكد إن الكلام ده منك'**
  String get signTextHelp;

  /// No description provided for @files.
  ///
  /// In ar, this message translates to:
  /// **'ملفات'**
  String get files;

  /// No description provided for @encryptFileShort.
  ///
  /// In ar, this message translates to:
  /// **'صور، مستندات، أي حاجة'**
  String get encryptFileShort;

  /// No description provided for @decryptFileShort.
  ///
  /// In ar, this message translates to:
  /// **'.pgp / .gpg / .asc'**
  String get decryptFileShort;

  /// No description provided for @signFileShort.
  ///
  /// In ar, this message translates to:
  /// **'ملف توقيع .sig'**
  String get signFileShort;

  /// No description provided for @verifyFileShort.
  ///
  /// In ar, this message translates to:
  /// **'اتأكد إن الملف متغيّرش ومن مين'**
  String get verifyFileShort;

  /// No description provided for @newProfile.
  ///
  /// In ar, this message translates to:
  /// **'بروفايل جديد'**
  String get newProfile;

  /// No description provided for @profilesHelp.
  ///
  /// In ar, this message translates to:
  /// **'كل بروفايل ليه مفاتيحه وجهات اتصاله لوحده (شخصي، شغل...). جهات الاتصال بتفضل في البروفايل بتاعها، إلا لو اخترت إنها تظهر في الكل.'**
  String get profilesHelp;

  /// No description provided for @hasOwnPassword.
  ///
  /// In ar, this message translates to:
  /// **'بكلمة سر لوحده'**
  String get hasOwnPassword;

  /// No description provided for @profilePasswordHelp.
  ///
  /// In ar, this message translates to:
  /// **'طبقة زيادة: البروفايل يفضل مقفول لحد ما تكتب كلمة سره، حتى لو التطبيق مفتوح.'**
  String get profilePasswordHelp;

  /// No description provided for @profileCreated.
  ///
  /// In ar, this message translates to:
  /// **'البروفايل اتعمل'**
  String get profileCreated;

  /// No description provided for @switchTo.
  ///
  /// In ar, this message translates to:
  /// **'افتحه'**
  String get switchTo;

  /// No description provided for @renameProfile.
  ///
  /// In ar, this message translates to:
  /// **'الاسم واللون'**
  String get renameProfile;

  /// No description provided for @changeProfilePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة سر البروفايل'**
  String get changeProfilePassword;

  /// No description provided for @setProfilePassword.
  ///
  /// In ar, this message translates to:
  /// **'حط كلمة سر للبروفايل'**
  String get setProfilePassword;

  /// No description provided for @removeProfilePassword.
  ///
  /// In ar, this message translates to:
  /// **'شيل كلمة سر البروفايل'**
  String get removeProfilePassword;

  /// No description provided for @lockProfileNow.
  ///
  /// In ar, this message translates to:
  /// **'اقفل البروفايل دلوقتي'**
  String get lockProfileNow;

  /// No description provided for @deleteProfile.
  ///
  /// In ar, this message translates to:
  /// **'حذف البروفايل'**
  String get deleteProfile;

  /// No description provided for @deleteProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف «{name}»؟'**
  String deleteProfileTitle(String name);

  /// No description provided for @deleteProfileBody.
  ///
  /// In ar, this message translates to:
  /// **'كل المفاتيح السرية وجهات الاتصال اللي في البروفايل ده هتتمسح ومش هترجع. خد نسخة احتياطية الأول.'**
  String get deleteProfileBody;

  /// No description provided for @profileName.
  ///
  /// In ar, this message translates to:
  /// **'اسم البروفايل'**
  String get profileName;

  /// No description provided for @profileNameHint.
  ///
  /// In ar, this message translates to:
  /// **'شخصي، شغل، الجامعة...'**
  String get profileNameHint;

  /// No description provided for @protectWithPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سر لوحده'**
  String get protectWithPassword;

  /// No description provided for @backupPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سر النسخة الاحتياطية'**
  String get backupPassword;

  /// No description provided for @backupPasswordHelp.
  ///
  /// In ar, this message translates to:
  /// **'النسخة بتتشفّر بيها. من غيرها مفيش أي طريقة تفتحها — اكتبها في مكان آمن.'**
  String get backupPasswordHelp;

  /// No description provided for @backupDoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'النسخة الاحتياطية جاهزة'**
  String get backupDoneTitle;

  /// No description provided for @backupDoneBody.
  ///
  /// In ar, this message translates to:
  /// **'بروفايلات: {profiles}\nمفاتيح: {keys}\nجهات اتصال: {contacts}\n\nحطها في مكان برا الموبايل (كمبيوتر، فلاشة).'**
  String backupDoneBody(int profiles, int keys, int contacts);

  /// No description provided for @backupSkipped.
  ///
  /// In ar, this message translates to:
  /// **'البروفايلات المقفولة دي متاخدش منها نسخة (افتحها وجرّب تاني): {names}'**
  String backupSkipped(String names);

  /// No description provided for @restoreTitle.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع النسخة؟'**
  String get restoreTitle;

  /// No description provided for @backupFrom.
  ///
  /// In ar, this message translates to:
  /// **'النسخة من يوم {date}'**
  String backupFrom(String date);

  /// No description provided for @willMerge.
  ///
  /// In ar, this message translates to:
  /// **'هيندمج مع البروفايل اللي بنفس الاسم'**
  String get willMerge;

  /// No description provided for @willCreate.
  ///
  /// In ar, this message translates to:
  /// **'بروفايل جديد'**
  String get willCreate;

  /// No description provided for @sharedContactsCount.
  ///
  /// In ar, this message translates to:
  /// **'جهات اتصال لكل البروفايلات: {count}'**
  String sharedContactsCount(int count);

  /// No description provided for @restoreNothingDeleted.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة عندك هتتمسح: المفاتيح الجديدة بتتضاف والموجودة بتتحدّث بس.'**
  String get restoreNothingDeleted;

  /// No description provided for @restore.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع'**
  String get restore;

  /// No description provided for @backup.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get backup;

  /// No description provided for @backupIntro.
  ///
  /// In ar, this message translates to:
  /// **'النسخة الاحتياطية ملف .shen متشفّر بكلمة سر بتختارها (OpenPGP: Argon2 + AES-256). المفاتيح السرية جواها لسه محمية بكلمات سرها كمان. تقدر ترجّعها على أي موبايل.'**
  String get backupIntro;

  /// No description provided for @exportSection.
  ///
  /// In ar, this message translates to:
  /// **'تصدير'**
  String get exportSection;

  /// No description provided for @backupEverything.
  ///
  /// In ar, this message translates to:
  /// **'نسخة من كل حاجة'**
  String get backupEverything;

  /// No description provided for @backupEverythingHelp.
  ///
  /// In ar, this message translates to:
  /// **'كل البروفايلات المفتوحة + جهات الاتصال المشتركة'**
  String get backupEverythingHelp;

  /// No description provided for @backupThisProfile.
  ///
  /// In ar, this message translates to:
  /// **'نسخة من «{name}» بس'**
  String backupThisProfile(String name);

  /// No description provided for @backupThisProfileHelp.
  ///
  /// In ar, this message translates to:
  /// **'مفاتيح وجهات اتصال البروفايل ده بس'**
  String get backupThisProfileHelp;

  /// No description provided for @importSection.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع'**
  String get importSection;

  /// No description provided for @restoreBackup.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع نسخة احتياطية'**
  String get restoreBackup;

  /// No description provided for @restoreBackupHelp.
  ///
  /// In ar, this message translates to:
  /// **'من ملف .shen'**
  String get restoreBackupHelp;

  /// No description provided for @backupFormatNote.
  ///
  /// In ar, this message translates to:
  /// **'الصيغة مفتوحة وموثّقة: تقدر تفك النسخة من غير شِن خالص بالأمر sq decrypt (Sequoia PGP). مفاتيحك العامة تقدر تصدّرها لوحدها كملف .asc من صفحة كل مفتاح.'**
  String get backupFormatNote;

  /// No description provided for @immediately.
  ///
  /// In ar, this message translates to:
  /// **'على طول'**
  String get immediately;

  /// No description provided for @bioEnableTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الفتح بالبصمة'**
  String get bioEnableTitle;

  /// No description provided for @bioEnabled.
  ///
  /// In ar, this message translates to:
  /// **'الفتح بالبصمة اتفعّل'**
  String get bioEnabled;

  /// No description provided for @currentMasterPassword.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة السر الرئيسية الحالية.'**
  String get currentMasterPassword;

  /// No description provided for @newMasterPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سر رئيسية جديدة'**
  String get newMasterPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر اتغيّرت'**
  String get passwordChanged;

  /// No description provided for @wipeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسح كل البيانات'**
  String get wipeTitle;

  /// No description provided for @wipeBody.
  ///
  /// In ar, this message translates to:
  /// **'كل المفاتيح والبروفايلات وجهات الاتصال هتتمسح من الموبايل ده نهائياً. لو معندكش نسخة احتياطية مش هتقدر ترجّعها.'**
  String get wipeBody;

  /// No description provided for @wipe.
  ///
  /// In ar, this message translates to:
  /// **'امسح كل حاجة'**
  String get wipe;

  /// No description provided for @masterPasswordForWipe.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة السر الرئيسية عشان تمسح كل حاجة.'**
  String get masterPasswordForWipe;

  /// No description provided for @security.
  ///
  /// In ar, this message translates to:
  /// **'الأمان'**
  String get security;

  /// No description provided for @bioHelp.
  ///
  /// In ar, this message translates to:
  /// **'البصمة بتفك مفتاح الخزنة نفسه (مش مجرد سماح)'**
  String get bioHelp;

  /// No description provided for @autoLock.
  ///
  /// In ar, this message translates to:
  /// **'القفل التلقائي'**
  String get autoLock;

  /// No description provided for @autoLockValue.
  ///
  /// In ar, this message translates to:
  /// **'بعد ما تخرج من التطبيق بـ {time}'**
  String autoLockValue(String time);

  /// No description provided for @rememberPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'تذكّر كلمات سر المفاتيح'**
  String get rememberPassphrase;

  /// No description provided for @rememberPassphraseOff.
  ///
  /// In ar, this message translates to:
  /// **'لأ — هتتطلب كل مرة (الأأمن)'**
  String get rememberPassphraseOff;

  /// No description provided for @rememberPassphraseOn.
  ///
  /// In ar, this message translates to:
  /// **'في الذاكرة بس لمدة {count} دقيقة، وبتتمسح لما التطبيق يتقفل'**
  String rememberPassphraseOn(int count);

  /// No description provided for @dontRemember.
  ///
  /// In ar, this message translates to:
  /// **'متفتكرش'**
  String get dontRemember;

  /// No description provided for @clipboardClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح الحافظة'**
  String get clipboardClear;

  /// No description provided for @clipboardClearValue.
  ///
  /// In ar, this message translates to:
  /// **'النص السري بيتمسح بعد {count} ثانية'**
  String clipboardClearValue(int count);

  /// No description provided for @changeMasterPassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة السر الرئيسية'**
  String get changeMasterPassword;

  /// No description provided for @data.
  ///
  /// In ar, this message translates to:
  /// **'البيانات'**
  String get data;

  /// No description provided for @profilesShortHelp.
  ///
  /// In ar, this message translates to:
  /// **'شخصي، شغل... كل واحد بمفاتيحه'**
  String get profilesShortHelp;

  /// No description provided for @backupShortHelp.
  ///
  /// In ar, this message translates to:
  /// **'تصدير واسترجاع نسخة متشفّرة'**
  String get backupShortHelp;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'الشكل'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @followPhone.
  ///
  /// In ar, this message translates to:
  /// **'زي الموبايل'**
  String get followPhone;

  /// No description provided for @theme.
  ///
  /// In ar, this message translates to:
  /// **'الوضع'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'غامق'**
  String get themeDark;

  /// No description provided for @about.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح المصدر (GPL-3.0). من غير إنترنت ولا تتبّع ولا إعلانات.'**
  String get aboutBody;

  /// No description provided for @sourceCode.
  ///
  /// In ar, this message translates to:
  /// **'الكود المصدري'**
  String get sourceCode;

  /// No description provided for @releaseKey.
  ///
  /// In ar, this message translates to:
  /// **'بصمة مفتاح توقيع الإصدارات'**
  String get releaseKey;

  /// No description provided for @license.
  ///
  /// In ar, this message translates to:
  /// **'الرخصة'**
  String get license;

  /// No description provided for @dangerZone.
  ///
  /// In ar, this message translates to:
  /// **'منطقة خطر'**
  String get dangerZone;

  /// No description provided for @wipeHelp.
  ///
  /// In ar, this message translates to:
  /// **'بيمسح المفاتيح والبروفايلات من الموبايل ده'**
  String get wipeHelp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
