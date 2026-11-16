allprojects {
    repositories {
        // ملفات الـ engine (io.flutter) موجودة بس في مستودع Flutter اللي الـ plugin بيضيفه بعد دول.
        // من غير الاستثناء Gradle بيسأل عنها Maven Central الأول، ولو رد 429 (Too Many Requests) البيلد بيقع.
        google { content { excludeGroupByRegex("io\\.flutter(\\..*)?") } }
        mavenCentral { content { excludeGroupByRegex("io\\.flutter(\\..*)?") } }
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
