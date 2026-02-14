import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryExtension

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
    project.plugins.withId("com.android.application") {
        project.extensions.configure<ApplicationExtension> {
            compileSdk = 35
        }
    }
    project.plugins.withId("com.android.library") {
        project.extensions.configure<LibraryExtension> {
            compileSdk = 35
        }
    }

    afterEvaluate {
        val appExt = project.extensions.findByType(ApplicationExtension::class.java)
        val libExt = project.extensions.findByType(LibraryExtension::class.java)
        val android = appExt ?: libExt
        if (android != null && android.namespace == null) {
            when (project.name) {
                "flutter_appauth" -> android.namespace = "io.crossingthestreams.flutterappauth"
                "url_launcher_android" -> android.namespace = "io.flutter.plugins.urllauncher"
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
