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
    val project = this
    fun applyProguardFix() {
        if (project.extensions.findByName("android") != null) {
            project.configure<com.android.build.gradle.BaseExtension> {
                buildTypes.forEach { buildType ->
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

    if (project.state.executed) {
        applyProguardFix()
    } else {
        project.afterEvaluate {
            applyProguardFix()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
