plugins {
    kotlin("jvm") version "1.9.20"
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("com.amazonaws:aws-lambda-java-core:1.2.1")
}

tasks.jar {
    manifest {
        attributes["Main-Class"] = "example.Handler"
    }
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) })
    duplicatesStrategy = DuplicatesStrategy.INCLUDE
}

kotlin {
    // 🔥 DŮLEŽITÉ — vynutí kompilaci na Java 17, kompatibilní s Lambda runtime
    jvmToolchain(17)
}