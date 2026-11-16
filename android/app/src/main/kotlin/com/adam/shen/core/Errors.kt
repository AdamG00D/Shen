package com.adam.shen.core

/**
 * أكواد الأخطاء اللي بتوصل لـ Dart (نفس الأسماء في `lib/core/core_errors.dart`).
 * رسالة الخطأ نفسها مبتتعرضش للمستخدم — الواجهة بتترجم الكود.
 */
enum class Err {
    /** كلمة السر غلط (الرئيسية / البروفايل / المفتاح / الرسالة). */
    WRONG_PASSWORD,

    /** محاولات غلط كتير — استنى [CoreError.waitMs]. */
    LOCKED_OUT,

    /** الخزنة مقفولة. */
    LOCKED,

    /** البروفايل ده ليه كلمة سر لوحده ولسه مقفول. */
    PROFILE_LOCKED,

    /** مفتاح الـ Keystore اتمسح (مثلاً بعد ما التطبيق اترجع من نسخة احتياطية لجهاز تاني). */
    KEYSTORE,

    /** بيانات بايظة أو مش OpenPGP. */
    BAD_DATA,

    /** الرسالة أو الملف اتلعب فيه (فشل التحقق من السلامة). */
    INTEGRITY,

    /** مفيش مفتاح عندنا يفك الرسالة دي. */
    NO_KEY,

    /** المفتاح منتهي / ملغي / مينفعش يشفّر. */
    CANNOT_ENCRYPT,

    /** المفتاح مينفعش يوقّع. */
    CANNOT_SIGN,

    /** مش موجود. */
    NOT_FOUND,

    /** موجود قبل كده. */
    EXISTS,

    /** أكبر من المسموح. */
    TOO_LARGE,

    /** مدخلات غلط من الواجهة. */
    INVALID,

    /** الملف مش نسخة احتياطية من شِن. */
    NOT_BACKUP,

    /** العملية اتلغت. */
    CANCELLED,

    /** خطأ في القراءة / الكتابة. */
    IO,
}

class CoreError(val code: Err, val waitMs: Long = 0, detail: String? = null) : Exception(detail ?: code.name)
