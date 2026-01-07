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
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.14")

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
    testImplementation("org.springframework.security:spring-security-test")

    // Testcontainers는 "도커 준비된 이후"에 다시 켜는 걸 권장
    // testImplementation("org.springframework.boot:spring-boot-testcontainers")
    // testImplementation("org.testcontainers:junit-jupiter")
    // testImplementation("org.testcontainers:postgresql")

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
}
