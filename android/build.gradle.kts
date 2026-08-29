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
    // Securely hook into Android plugins without lifecycle errors
    plugins.withId("com.android.library") {
        applyProguardFix(this@subprojects)
    }
    plugins.withId("com.android.application") {
        applyProguardFix(this@subprojects)
    }
}

fun applyProguardFix(project: Project) {
    project.configure<com.android.build.gradle.BaseExtension> {
        buildTypes.all {
            val currentFiles = proguardFiles
            val newFiles = currentFiles.map { file ->
                if (file.name == "proguard-android.txt") {
                    project.android.getDefaultProguardFile("proguard-android-optimize.txt")
                } else {
                    file
                }
            }
            setProguardFiles(newFiles)
        }
    }
}

val Project.android: com.android.build.gradle.BaseExtension
    get() = extensions.getByType<com.android.build.gradle.BaseExtension>()

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
