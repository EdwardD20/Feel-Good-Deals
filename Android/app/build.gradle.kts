import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
} // plugins

android {

    namespace = "org.danleys.feelgooddeals"

    compileSdk = 37

    defaultConfig {

        applicationId = "org.danleys.feelgooddeals"

        minSdk = 24
        targetSdk = 37

        versionCode = 32
        versionName = "0.3"

        ndk {

            abiFilters += listOf(
                "armeabi-v7a",
                "arm64-v8a"
            )

        } // ndk

    } // defaultConfig

    buildTypes {

        release {

            isMinifyEnabled = false

            proguardFiles(
                getDefaultProguardFile(
                    "proguard-android-optimize.txt"
                ),
                "proguard-rules.pro"
            ) // proguardFiles

        } // release

    } // buildTypes

    compileOptions {

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

    } // compileOptions

    buildFeatures {

        compose = true

    } // buildFeatures

    packaging {

        jniLibs {

            useLegacyPackaging = false

        } // jniLibs

    } // packaging

} // android

kotlin {

    compilerOptions {

        jvmTarget.set(JvmTarget.JVM_17)

    } // compilerOptions

} // kotlin

dependencies {

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)

    implementation(
        platform(libs.androidx.compose.bom)
    )

    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.core)

    implementation(libs.androidx.camera.core)
    implementation(libs.androidx.camera.camera2)
    implementation(libs.androidx.camera.lifecycle)
    implementation(libs.androidx.camera.view)

    implementation(libs.google.mlkit.barcode)

    implementation(libs.google.accompanist.permissions)

    implementation(libs.kotlinx.coroutines.android)

    testImplementation(libs.junit)

    androidTestImplementation(libs.androidx.junit)

    androidTestImplementation(
        libs.androidx.espresso.core
    )

    androidTestImplementation(
        platform(libs.androidx.compose.bom)
    )

    androidTestImplementation(
        libs.androidx.compose.ui.test.junit4
    )

    debugImplementation(
        libs.androidx.compose.ui.tooling
    )

    debugImplementation(
        libs.androidx.compose.ui.test.manifest
    )

} // dependencies

tasks.register("bumpVersionCode") {

    doLast {

        val gradleFile = file("build.gradle.kts")

        val text = gradleFile.readText()

        val regex =
            Regex("""versionCode\s*=\s*(\d+)""")

        val match =
            regex.find(text)
                ?: error(
                    "versionCode not found in build.gradle.kts"
                )

        val current =
            match.groupValues[1].toInt()

        val next =
            current + 1

        val updated =
            text.replaceFirst(
                regex,
                "versionCode = $next"
            )

        gradleFile.writeText(updated)

        println(
            "versionCode bumped from $current to $next"
        )

    } // doLast

} // tasks.register

tasks.named("preBuild") {

    val isReleaseTask = gradle.startParameter.taskNames.any {
        it.contains("Release", ignoreCase = true) &&
                (it.contains("bundle") || it.contains("assemble"))
    }

    if (isReleaseTask) {
        dependsOn("bumpVersionCode")
    } // if

} // tasks.named