import java.util.Properties
import java.io.FileInputStream

plugins { 
    id("com.android.application") 
    id("dev.flutter.flutter-gradle-plugin") 
} 
 
 
// Release 서명 설정
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


android { 
 
    namespace = "com.snob.travel" 
 
    compileSdk = 36 
 
    ndkVersion = flutter.ndkVersion 
 
 
    compileOptions { 
 
        sourceCompatibility = JavaVersion.VERSION_17 
 
        targetCompatibility = JavaVersion.VERSION_17 
 
        isCoreLibraryDesugaringEnabled = true 
 
    } 
 
 
    defaultConfig { 
 
        applicationId = "com.snob.travel" 
 
        minSdk = flutter.minSdkVersion 
 
        targetSdk = 36 
 
        versionCode = flutter.versionCode 
 
        versionName = flutter.versionName 
 
    } 


    // Release용 업로드 키
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
 
 
    buildTypes { 
 
        release { 
 
            signingConfig = signingConfigs.getByName("release") 
 
        } 
 
    } 
 
} 
 
dependencies { 
 
    coreLibraryDesugaring( 
        "com.android.tools:desugar_jdk_libs:2.1.5" 
    ) 
 
} 
 
kotlin { 
 
    compilerOptions { 
 
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 
 
    } 
 
} 
 
 
 
flutter { 
 
    source = "../.." 
 
}