allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix for flutter_appauth namespace issue with AGP 8.x
subprojects {
    project.configurations.all {
        resolutionStrategy {
            force("androidx.browser:browser:1.8.0")
            force("androidx.core:core:1.15.0")
            force("androidx.core:core-ktx:1.15.0")
        }
    }

    // Set compileSdk early for plugins that need it during configuration
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.api.AndroidBasePlugin) {
            project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                compileSdkVersion(35)
            }
        }
    }

    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.findByName("android")
            if (androidExtension != null) {
                val android = androidExtension as com.android.build.gradle.BaseExtension
                if (android.namespace == null) {
                    when (project.name) {
                        "flutter_appauth" -> android.namespace = "io.crossingthestreams.flutterappauth"
                        "url_launcher_android" -> android.namespace = "io.flutter.plugins.urllauncher"
                    }
                }
                android.compileSdkVersion(35)
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
