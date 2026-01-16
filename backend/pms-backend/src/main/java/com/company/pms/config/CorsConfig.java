package com.company.pms.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * CORS 기본 설정
 * - dev에서는 프론트 도메인이 nginx(8181) 또는 vite(5173)일 수 있어 환경변수로 제어한다.
 * - 운영에서는 반드시 고정 도메인만 허용.
 *
 * ===== SSO IdP 등록 후 CORS 설정 강화 방법 =====
 *
 * 1. Dev 환경 Origin 제한 (보안 강화):
 *    docker-compose.dev.yml:
 *    ```yaml
 *    backend:
 *      environment:
 *        CORS_ALLOWED_ORIGINS: https://dev.pms.example.com,http://dev-server-ip:8181
 *    ```
 *    - allowedOriginPatterns("*") 대신 특정 Origin만 허용
 *    - SSO 인증과 함께 사용하여 보안 수준 향상
 *
 * 2. Test 환경 Origin 제한:
 *    ```yaml
 *    CORS_ALLOWED_ORIGINS: https://test.pms.example.com
 *    ```
 *
 * 3. Prod 환경 Origin 제한 (필수):
 *    ```yaml
 *    CORS_ALLOWED_ORIGINS: https://pms.example.com
 *    ```
 *    - 운영 환경에서는 반드시 환경변수 설정
 *    - 와일드카드(*) 절대 사용 금지
 *
 * 4. AllowedHeaders 확장 (필요 시):
 *    - SSO 사용 시 추가 헤더가 필요할 수 있음
 *    - 예: X-Tenant-ID, X-Request-ID 등
 *    ```java
 *    config.setAllowedHeaders(List.of(
 *        "Authorization", "Content-Type", "X-Requested-With",
 *        "X-Tenant-ID", "X-Request-ID"
 *    ));
 *    ```
 *
 * 5. ExposedHeaders 확장 (필요 시):
 *    - 응답 헤더를 클라이언트에 노출
 *    ```java
 *    config.setExposedHeaders(List.of(
 *        "Location", "X-Total-Count", "X-Page-Number"
 *    ));
 *    ```
 *
 * 6. AllowCredentials 주의사항:
 *    - true로 설정 시 쿠키, Authorization 헤더 전송 가능
 *    - allowedOriginPatterns("*")와 함께 사용 가능
 *    - allowedOrigins("*")와는 함께 사용 불가 (보안상)
 *    - SSO 토큰 기반 인증에는 true 권장
 */
@Configuration
public class CorsConfig {

    private static final Logger log = LoggerFactory.getLogger(CorsConfig.class);

    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        String origins = System.getenv().getOrDefault("CORS_ALLOWED_ORIGINS", "");
        String profile = System.getenv().getOrDefault("SPRING_PROFILES_ACTIVE", "local");

        if (!origins.isBlank()) {
            // 환경변수로 명시적으로 설정된 경우
            // 개선: 공백 제거 및 빈 문자열 필터링
            List<String> allowedOrigins = Arrays.stream(origins.split(","))
                    .map(String::trim)          // 공백 제거
                    .filter(s -> !s.isEmpty())  // 빈 문자열 제외
                    .toList();

            config.setAllowedOrigins(allowedOrigins);
            log.info("CORS Allowed Origins ({}): {}", profile, allowedOrigins);

        } else if ("dev".equals(profile) || "test".equals(profile)) {
            // dev/test 환경에서는 모든 Origin 허용 (SSO IdP 준비 전 임시)
            config.setAllowedOriginPatterns(List.of("*"));
            log.warn("CORS: Allowing all origins (*) - Dev/Test mode only! This is TEMPORARY until SSO IdP is ready.");
        } else {
            // 로컬 개발 환경: localhost만 허용
            config.setAllowedOrigins(List.of(
                    "http://localhost:5173",
                    "http://localhost:8080",
                    "http://localhost:8181",
                    "http://127.0.0.1:5173",
                    "http://127.0.0.1:8080",
                    "http://127.0.0.1:8181"
            ));
            log.info("CORS: Localhost-only mode (local development)");
        }

        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
        config.setExposedHeaders(List.of("Location"));
        config.setAllowCredentials(true);

        log.debug("CORS Configuration applied - Profile: {}, AllowCredentials: true", profile);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}

