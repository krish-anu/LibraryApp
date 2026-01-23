allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix for flutter_appauth namespace issue with AGP 8.x
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.findByName("android")
            if (androidExtension != null) {
                val android = androidExtension as com.android.build.gradle.BaseExtension
                if (android.namespace == null) {
                    when (project.name) {
                        "flutter_appauth" -> android.namespace = "io.crossingthestreams.flutterappauth"
                    }
                }
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
