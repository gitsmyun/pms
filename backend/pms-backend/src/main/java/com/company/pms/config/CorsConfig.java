package com.company.pms.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * CORS 기본 설정
 * - dev에서는 프론트 도메인이 nginx(8181) 또는 vite(5173)일 수 있어 환경변수로 제어한다.
 * - 운영에서는 반드시 고정 도메인만 허용.
 */
@Configuration
public class CorsConfig {

    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        String origins = System.getenv().getOrDefault("CORS_ALLOWED_ORIGINS", "");
        String profile = System.getenv().getOrDefault("SPRING_PROFILES_ACTIVE", "local");

        if (!origins.isBlank()) {
            // 환경변수로 명시적으로 설정된 경우
            config.setAllowedOrigins(List.of(origins.split(",")));
        } else if ("dev".equals(profile) || "test".equals(profile)) {
            // dev/test 환경에서는 모든 Origin 허용 (SSO IdP 준비 전 임시)
            config.setAllowedOriginPatterns(List.of("*"));
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
        }

        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
        config.setExposedHeaders(List.of("Location"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}

