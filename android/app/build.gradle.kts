import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// مفتاح التوقيع في فولدر منفصل برا المشروع: Shen/Signing_Key
// (برا مستودع Git، فمستحيل يترفع بالغلط)
val signingDir = rootProject.file("../../Signing_Key")
val keystoreProperties = Properties().apply {
    val f = File(signingDir, "key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}

android {
    namespace = "com.adam.shen"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.adam.shen"
        // Android 8.0+: Keystore بـ AES-GCM مضمون + java.time
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = File(signingDir, keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // من غير مفتاح التوقيع (المساهمين / CI): بنوقّع بمفتاح الـ debug عشان المشروع يتبني عادي.
            // الإصدار الرسمي بيتبني بـ scripts/build_release.sh وده بيرفض يشتغل من غير المفتاح.
            signingConfig = if (keystoreProperties.containsKey("storeFile")) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("Shen: مفتاح التوقيع مش موجود في Shen/Signing_Key — التوقيع بمفتاح debug")
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    packaging {
        resources {
            // ملفات مكررة جوه jars بتاعة Bouncy Castle
            excludes += setOf(
                "META-INF/versions/9/OSGI-INF/MANIFEST.MF",
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE*",
                "META-INF/NOTICE*",
            )
        }
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
        unitTests.all { it.maxHeapSize = "2g" }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // OpenPGP: PGPainless (فوق Bouncy Castle) — اتعمل له فحص أمني من Cure53
    implementation("org.pgpainless:pgpainless-core:2.0.4")
    // البصمة مربوطة بمفتاح الـ Keystore (CryptoObject)
    implementation("androidx.biometric:biometric:1.1.0")
    implementation("androidx.fragment:fragment-ktx:1.8.9")
    // مسح QR (بصمة المفتاح) — ZXing، مفتوحة بالكامل من غير خدمات جوجل
    implementation("com.journeyapps:zxing-android-embedded:4.3.0")

    testImplementation("junit:junit:4.13.2")
    // org.json جوه أندرويد بس — للتيستات على الـ JVM
    testImplementation("org.json:json:20250517")
}
