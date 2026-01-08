# 작성일 2026 01 08
# 작업자 윤성민
# 설명 이 파일은 백엔드 스프링 부트 애플리케이션을 컨테이너 이미지로 패키징하기 위한 도커파일이다
# 설명 빌드 단계에서 자바 21 JDK 기반으로 그레이들 부트 JAR를 생성하고 런타임 단계는 JRE로 경량화한다
# 설명 기본 이미지 빌드에서는 테스트를 제외하여 빠른 패키징을 보장하고 테스트는 CI에서 별도 게이트로 수행한다
# 설명 런타임은 비루트 사용자로 실행하여 쿠버네티스 환경에서의 보안 표준에 맞춘다
# 설명 서버 포트는 환경 변수로 제어하며 배포 환경에서 설정을 외부화하는 방식을 전제로 한다

# syntax=docker/dockerfile:1

# Build stage
FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace

# Gradle wrapper + build files first (better caching)
COPY gradlew gradlew.bat settings.gradle.kts build.gradle.kts gradle.properties* ./
COPY gradle ./gradle

# Source
COPY src ./src

# 기본 이미지 빌드는 테스트 제외(통합테스트는 CI에서 별도 Job으로 확장)
RUN chmod +x ./gradlew && ./gradlew --no-daemon clean bootJar -x test

# Runtime stage
FROM eclipse-temurin:21-jre
WORKDIR /app

# Non-root user (기업 표준 권장)
RUN useradd -r -u 10001 appuser
USER appuser

COPY --from=build /workspace/build/libs/*.jar /app/app.jar

ENV SERVER_PORT=8080
EXPOSE 8080

ENTRYPOINT ["java","-jar","/app/app.jar"]
