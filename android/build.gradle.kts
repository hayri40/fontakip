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
        val project = this
        if (project.extensions.findByName("android") != null) {
            project.extensions.configure<com.android.build.gradle.BaseExtension> {
                buildTypes.forEach { buildType ->
                    // Replace the deprecated proguard-android.txt with proguard-android-optimize.txt
                    val files = buildType.proguardFiles
                    if (files.any { it.name == "proguard-android.txt" }) {
                        buildType.setProguardFiles(listOf(
                            project.android.getDefaultProguardFile("proguard-android-optimize.txt"),
                            "proguard-rules.pro"
                        ))
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
