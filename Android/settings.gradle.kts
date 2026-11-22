pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "PibblesAndroid"
include(":app")

// Same setup as SquashAnalyzer: Skip transpiles Packages/PibblesUI (and
// Core) to a Gradle build, which this project includes. Kotlin UI is never
// hand-maintained. `swift build` only runs when a Swift source changed.
val uiPackage = file("../Packages/PibblesUI")
val skipOutput = uiPackage.resolve(".build/plugins/outputs/pibblesui/PibblesUI/destination/skipstone")
val skipStamp = uiPackage.resolve(".build/gradle-skip-stamp")
val swiftSources = listOf(file("../Packages/PibblesUI"), file("../Packages/PibblesCore"))
    .flatMap { pkg -> listOf(pkg.resolve("Package.swift"), pkg.resolve("Sources")) }
val newestSource = swiftSources.flatMap { root -> root.walkTopDown().filter { it.isFile }.toList() }
    .maxOfOrNull { it.lastModified() } ?: 0L
if (!skipOutput.exists() || !skipStamp.exists() || skipStamp.lastModified() < newestSource) {
    val swiftBuild = providers.exec {
        commandLine("swift", "build", "--package-path", uiPackage.absolutePath)
        environment("PATH", "${System.getenv("PATH")}:/opt/homebrew/bin")
    }
    print(swiftBuild.standardOutput.asText.get())
    print(swiftBuild.standardError.asText.get())
    skipStamp.parentFile.mkdirs()
    skipStamp.writeText(System.currentTimeMillis().toString())
}
// Included builds do not inherit this project's local SDK location.
val localSdk = file("local.properties")
if (localSdk.exists()) {
    localSdk.copyTo(skipOutput.resolve("local.properties"), overwrite = true)
}
includeBuild(skipOutput)
