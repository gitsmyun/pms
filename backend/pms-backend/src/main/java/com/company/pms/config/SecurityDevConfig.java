package com.company.pms.config;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Dev/Test 환경에서 OIDC_ISSUER_URI가 설정되지 않은 경우 임시로 모든 요청을 허용.
 * SSO IdP 준비 전까지 사용. SSO 준비 후에는 SecurityOidcConfig가 활성화됨.
 *
 * ===== SSO IdP 등록 시 변경 사항 =====
 *
 * 1. 환경변수 설정으로 자동 비활성화됨:
 *    - docker-compose.dev.yml 또는 환경변수에 설정:
 *      OIDC_ISSUER_URI=https://dev-sso.example.com/realms/pms
 *    - 위 환경변수가 설정되면 @ConditionalOnProperty의 matchIfMissing=true 조건이
 *      false가 되어 이 Config는 비활성화되고 SecurityOidcConfig가 활성화됨
 *
 * 2. 추가 작업 없음:
 *    - 이 파일은 수정하지 않아도 됨
 *    - 환경변수 설정만으로 자동 전환됨
 *
 * 3. 검증 방법:
 *    - 백엔드 로그에서 "SecurityOidcConfig" Bean 로드 확인
 *    - /api/** 엔드포인트에 Authorization 헤더 없이 요청 시 401 응답 확인
 *    - Bearer 토큰과 함께 요청 시 JWT 검증 후 정상 응답 확인
 *
 * 4. 롤백 방법:
 *    - OIDC_ISSUER_URI 환경변수 제거 또는 빈 문자열로 설정
 *    - 컨테이너 재시작 시 다시 이 Config가 활성화됨
 */
@Configuration
@EnableWebSecurity
@Profile({"dev", "test"})
@ConditionalOnExpression(
    "T(org.springframework.util.StringUtils).isEmpty('${spring.security.oauth2.resourceserver.jwt.issuer-uri:}')"
)
public class SecurityDevConfig {

    private static final Logger log = LoggerFactory.getLogger(SecurityDevConfig.class);

    @PostConstruct
    public void init() {
        log.warn("╔═══════════════════════════════════════════════════════════════════════╗");
        log.warn("║  ⚠️  SecurityDevConfig ACTIVATED (Fallback Mode)                     ║");
        log.warn("║  WARNING: All requests are PERMITTED without authentication         ║");
        log.warn("║  This is TEMPORARY until SSO IdP is ready                            ║");
        log.warn("║  To activate SSO: Set OIDC_ISSUER_URI environment variable           ║");
        log.warn("╚═══════════════════════════════════════════════════════════════════════╝");
    }

    @Bean
    public SecurityFilterChain devSecurityFilterChain(HttpSecurity http) {
        log.debug("Configuring SecurityFilterChain for Dev/Test environment (permitAll mode)");

        return http
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .cors(cors -> {}) // CORS 활성화 (CorsConfigurationSource 사용)
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                        // Dev 환경에서는 모든 요청 허용 (SSO IdP 준비 전)
                        .anyRequest().permitAll()
                )
                .httpBasic(basic -> basic.disable())
                .formLogin(form -> form.disable())
                .build();
    }
}

