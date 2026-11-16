# Bouncy Castle / PGPainless: بيستخدموا reflection في اختيار الخوارزميات
-keep class org.bouncycastle.** { *; }
-keep class org.pgpainless.** { *; }
-dontwarn org.bouncycastle.**
-dontwarn org.pgpainless.**
-dontwarn org.slf4j.**
-dontwarn javax.naming.**
-dontwarn javax.annotation.**
# مكتبة tooling بتاعة zxing
-dontwarn com.google.zxing.**
