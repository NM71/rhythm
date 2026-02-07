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
    project.afterEvaluate {
        try {
            if (project.name == "on_audio_query_android") {
                val android = project.extensions.findByName("android")
                if (android != null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, "com.lucasjosino.on_audio_query")
                }
                
                // Fix Inconsistent JVM Target (Java=1.8 vs Kotlin=17)
                project.tasks.configureEach {
                    if (this::class.java.name.contains("KotlinCompile")) {
                        try {
                            val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                            kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java).invoke(kotlinOptions, "1.8")
                        } catch (e: Exception) {
                            println("Failed to set jvmTarget for task ${this.name}: $e")
                        }
                    }
                }
            }
        } catch (e: Exception) {
            println("Failed to set namespace workspace workaround for ${project.name}: $e")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
