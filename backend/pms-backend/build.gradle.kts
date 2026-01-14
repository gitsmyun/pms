plugins {
    java
    id("org.springframework.boot") version "4.0.0"
    id("io.spring.dependency-management") version "1.1.7"
}

group = "com.example"
version = "0.0.1-SNAPSHOT"
description = "pms-backend"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

configurations {
    compileOnly {
        extendsFrom(configurations.annotationProcessor.get())
    }
}

repositories {
    mavenCentral()
}

dependencies {
    // --- Web / API ---
    implementation("org.springframework.boot:spring-boot-starter-web") // 표준: webmvc 대신 web

    // --- Security (Keycloak JWT 검증) ---
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-oauth2-resource-server") // ★ 필수
    // (선택) JWT 인코더/디코더 유틸이 필요하면 아래도, 보통은 위 한 줄로 충분
    // implementation("org.springframework.security:spring-security-oauth2-jose")

    // --- Validation / Ops ---
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")

    // --- WebMVC + Swagger UI ---
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.5.0")

    // --- Data ---
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    runtimeOnly("org.postgresql:postgresql")

    // --- Flyway (둘 중 하나만 선택) ---
    // Boot starter를 쓰는 경우, 아래 2줄만으로 충분
    implementation("org.springframework.boot:spring-boot-starter-flyway")
    runtimeOnly("org.flywaydb:flyway-database-postgresql")

    // --- Lombok ---
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")

    // --- Dev only ---
    developmentOnly("org.springframework.boot:spring-boot-devtools")

    // --- Tests (지금 단계 최소 세트) ---
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    // MockMvc / test slices
    testImplementation("org.springframework.boot:spring-boot-test-autoconfigure")
    testImplementation("org.springframework.security:spring-security-test")

    // --- Integration Tests (Testcontainers) ---
    testImplementation(platform("org.testcontainers:testcontainers-bom:1.20.4"))
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
    testImplementation("org.springframework.boot:spring-boot-testcontainers")

    // 테스트에서 in-memory DB(H2) 사용
    testRuntimeOnly("com.h2database:h2")

    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}


// UTF-8 표준(한글 안전)
tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
}

tasks.withType<Javadoc>().configureEach {
    options.encoding = "UTF-8"
}

tasks.withType<Test>().configureEach {
    useJUnitPlatform()
    systemProperty("file.encoding", "UTF-8")

    // 환경에 따라 테스트 탐지가 흔들릴 수 있어 초기 기준선에서는 비발견 실패를 방지
    failOnNoDiscoveredTests = false

    // Windows에서 Gradle이 이전 test-results 바이너리(output.bin)를 지우는 단계에서
    // 간헐적으로 파일 잠금이 발생해 빌드가 실패하는 케이스가 있음.
    // (특히 IDE/AV/인덱서가 build 디렉터리를 스캔할 때)
    // → 테스트를 항상 별도 JVM으로 포크해 핸들이 빨리 반납되도록 완화.
    forkEvery = 1
    maxParallelForks = 1
}

// 통합 테스트 소스셋 분리
val integrationTest by sourceSets.creating {
    java.srcDir("src/integrationTest/java")
    resources.srcDir("src/integrationTest/resources")
    compileClasspath += sourceSets.main.get().output + configurations.testRuntimeClasspath.get()
    runtimeClasspath += output + compileClasspath
}

configurations[integrationTest.implementationConfigurationName].extendsFrom(configurations.testImplementation.get())
configurations[integrationTest.runtimeOnlyConfigurationName].extendsFrom(configurations.testRuntimeOnly.get())

val integrationTestTask = tasks.register<Test>("integrationTest") {
    description = "Runs integration tests."
    group = "verification"
    testClassesDirs = integrationTest.output.classesDirs
    classpath = integrationTest.runtimeClasspath
    useJUnitPlatform()
    systemProperty("file.encoding", "UTF-8")
}

// 기본 check에는 통합 테스트를 포함하지 않습니다.
// 통합 테스트는 도커가 가능한 환경에서만 별도 실행하는 것을 기본 전략으로 합니다.
