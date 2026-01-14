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

        // 주의: 운영에서는 '*' 금지. 여기서는 기본값을 비워두고 env로 받는다.
        // 콤마 구분: https://dev.pms.example.com,http://localhost:5173
        String origins = System.getenv().getOrDefault("CORS_ALLOWED_ORIGINS", "");
        if (!origins.isBlank()) {
            config.setAllowedOrigins(List.of(origins.split(",")));
        } else {
            // 로컬 개발 환경: 환경 변수가 없으면 localhost 허용
            config.setAllowedOrigins(List.of(
                    "http://localhost:5173",
                    "http://localhost:8080",
                    "http://127.0.0.1:5173",
                    "http://127.0.0.1:8080"
            ));
        }

        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
        config.setExposedHeaders(List.of("Location"));
        config.setAllowCredentials(false);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}

