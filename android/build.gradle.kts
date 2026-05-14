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
    project.evaluationDependsOn(":app")
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Fix for missing namespace and legacy package attribute in plugins (AGP 8.0+ requirement)
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.LibraryPlugin) {
            project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java).apply {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifestContent = manifestFile.readText()
                    val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestContent)
                    if (packageMatch != null) {
                        val packageName = packageMatch.groupValues[1]
                        if (namespace == null) {
                            namespace = packageName
                        }
                    }
                }
                if (namespace == null) {
                    namespace = "com.smart_odsc_queue.${project.name.replace("-", "_")}"
                }
            }
        }
    }

    // Automatically remove legacy package attribute from AndroidManifest.xml before processing
    project.tasks.withType<com.android.build.gradle.tasks.ProcessLibraryManifest>().configureEach {
        doFirst {
            val manifestFile = project.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                try {
                    val content = manifestFile.readText()
                    val newContent = content.replace(Regex("\\s*package=\"[^\"]*\""), "")
                    if (content != newContent) {
                        manifestFile.writeText(newContent)
                    }
                } catch (e: Exception) {
                    // Ignore if file is read-only
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
