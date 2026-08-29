allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            configure<com.android.build.gradle.BaseExtension> {
                buildTypes.forEach { buildType ->
                    // Force the use of the optimized proguard file instead of the legacy one
                    // which is no longer supported in AGP 8.0+
                    val currentFiles = buildType.proguardFiles
                    val newFiles = currentFiles.map { file ->
                        if (file.name == "proguard-android.txt") {
                            getDefaultProguardFile("proguard-android-optimize.txt")
                        } else {
                            file
                        }
                    }
                    buildType.setProguardFiles(newFiles)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
