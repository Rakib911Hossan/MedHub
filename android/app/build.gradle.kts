plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")

   
}

android {
    namespace = "com.example.new_project"
    compileSdk = 34  // Use the latest stable version

    defaultConfig {
        applicationId = "com.example.new_project"
        minSdk = 23  // Adjust based on your needs
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    val composeUiVersion = "1.2.0"
    implementation("androidx.compose.ui:ui:$composeUiVersion")
    implementation("androidx.compose.ui:ui-tooling-preview:$composeUiVersion")
    implementation(platform("com.google.firebase:firebase-bom:33.9.0"))
}

flutter {
    source = "../.."
}
