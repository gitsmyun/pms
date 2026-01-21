package com.company.pms.config;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.web.SecurityFilterChain;

import java.util.Arrays;
import java.util.List;

/**
 * 엔터프라이즈 권장: dev/test/prod는 OIDC(OAuth2 Resource Server) 기반 JWT 검증을 기본으로 한다.
 * OIDC_ISSUER_URI가 실제로 설정되어 있을 때만 활성화됨.
 *
 * ===== SSO IdP 등록 시 활성화 방법 =====
 *
 * 1. Keycloak 또는 다른 IdP 설정:
 *    a) Keycloak 설치 및 Realm 생성 (예: pms-realm)
 *    b) Client 생성:
 *       - Client ID: pms-backend
 *       - Client Protocol: openid-connect
 *       - Access Type: bearer-only (Resource Server)
 *    c) Issuer URI 확인:
 *       https://keycloak.example.com/realms/pms-realm
 *
 * 2. 환경변수 설정:
 *    docker-compose.dev.yml 또는 infra/env/dev.env:
 *    ```
 *    OIDC_ISSUER_URI=http://keycloak:8080/realms/pms
 *    ```
 *    ⚠️ 주의: 컨테이너 내부 네트워크에서는 keycloak:8080 사용
 *             브라우저(외부)에서는 localhost:8280 사용
 *
 * 3. application-dev.yml 주석 해제 (선택사항):
 *    ```yaml
 *    spring:
 *      security:
 *        oauth2:
 *          resourceserver:
 *            jwt:
 *              issuer-uri: ${OIDC_ISSUER_URI}
 *    ```
 *    - 환경변수만으로도 동작하므로 필수는 아님
 *
 * 4. 자동 활성화:
 *    - OIDC_ISSUER_URI 환경변수가 설정되면 이 Config 활성화
 *    - SecurityDevConfig는 자동 비활성화됨
 *    - Spring Boot Auto-configuration이 JwtDecoder Bean 자동 생성
 *
 * 5. JWT 검증 프로세스:
 *    - 클라이언트가 Authorization: Bearer <token> 헤더로 요청
 *    - Spring Security가 JWT 토큰 파싱
 *    - Issuer URI의 /.well-known/openid-configuration에서 JWKS 조회
 *    - 공개키로 JWT 서명 검증
 *    - 검증 성공 시 요청 허용, 실패 시 401 응답
 *
 * 6. 추가 커스터마이징 (필요 시):
 *    - Role 기반 접근 제어:
 *      .requestMatchers("/api/admin/**").hasRole("ADMIN")
 *      .requestMatchers("/api/user/**").hasAnyRole("USER", "ADMIN")
 *    - Scope 기반 접근 제어:
 *      .requestMatchers("/api/projects").hasAuthority("SCOPE_projects.read")
 *    - Custom JWT Converter:
 *      @Bean JwtAuthenticationConverter jwtAuthenticationConverter() { ... }
 *
 * 7. CORS 설정과 함께 사용:
 *    - SecurityDevConfig와 동일하게 CORS 활성화 필요
 *    - TODO: .cors(cors -> {}) 추가 필요 (아래 코드 참고)
 */
@Configuration
@EnableWebSecurity
@Profile({"dev", "test", "prod"})
@ConditionalOnProperty(
    name = "spring.security.oauth2.resourceserver.jwt.issuer-uri"
)
public class SecurityOidcConfig {

    private static final Logger log = LoggerFactory.getLogger(SecurityOidcConfig.class);

    @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri:}")
    private String issuerUri;

    @Value("${spring.security.oauth2.resourceserver.jwt.jwk-set-uri:http://localhost:8280/realms/pms/protocol/openid-connect/certs}")
    private String jwkSetUri;

    @PostConstruct
    public void init() {
        log.info("╔═══════════════════════════════════════════════════════════════════════╗");
        log.info("║  🔐 SecurityOidcConfig ACTIVATED                                      ║");
        log.info("║  Mode: OAuth2 Resource Server (JWT Validation)                       ║");
        log.info("║  OIDC Issuer URI: {}", String.format("%-45s", issuerUri) + "║");
        log.info("║  JWK Set URI: {}", String.format("%-49s", jwkSetUri) + "║");
        log.info("║  Multi-Issuer Support: localhost, IP, HTTPS                          ║");
        log.info("║  All /api/** endpoints require valid JWT token                       ║");
        log.info("╚═══════════════════════════════════════════════════════════════════════╝");
    }

    /**
     * Custom JwtDecoder - 여러 Issuer 지원
     *
     * 개발 환경에서는 localhost, IP, HTTPS 등 다양한 경로로 접속 가능하므로
     * Keycloak이 동적으로 발급하는 여러 Issuer를 모두 허용합니다.
     *
     * 허용되는 Issuer:
     * - http://localhost:8280/realms/pms (localhost 접속)
     * - http://10.127.6.102:8280/realms/pms (IP HTTP 접속)
     * - https://10.127.6.102:8543/realms/pms (IP HTTPS 접속 - 사용 안 함, 예비)
     */
    @Bean
    public JwtDecoder jwtDecoder() {
        log.info("🔧 Configuring Custom JwtDecoder with JWK Set URI: {}", jwkSetUri);

        NimbusJwtDecoder decoder = NimbusJwtDecoder
                .withJwkSetUri(jwkSetUri)
                .build();

        // 다중 Issuer Validator 설정
        List<String> validIssuers = Arrays.asList(
                "http://localhost:8280/realms/pms",
                "http://10.127.6.102:8280/realms/pms",
                "https://10.127.6.102:8543/realms/pms"
        );

        log.info("🔒 Allowed Issuers: {}", validIssuers);

        OAuth2TokenValidator<Jwt> validator = new DelegatingOAuth2TokenValidator<>(
                new JwtTimestampValidator(),
                new MultiIssuerValidator(validIssuers)
        );

        decoder.setJwtValidator(validator);

        return decoder;
    }

    @Bean
    public SecurityFilterChain oidcSecurityFilterChain(HttpSecurity http) {
        log.debug("Configuring SecurityFilterChain for OIDC/JWT validation");

        return http
                // API 서버이므로 기본은 stateless
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // CORS 활성화 (CorsConfigurationSource 자동 사용) - SSO 사용 시에도 필요
                .cors(cors -> {})
                // SPA + bearer 기반이면 CSRF 불필요(쿠키 세션 방식으로 전환 시 재검토)
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                        // Actuator 최소 허용
                        .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                        // Preflight 허용
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // 나머지 API는 인증 필요
                        .requestMatchers("/api/**").authenticated()

                        // ===== SSO IdP 등록 후 Role/Scope 기반 접근 제어 추가 예시 =====
                        // .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        // .requestMatchers("/api/projects/**").hasAnyAuthority("SCOPE_projects.read", "SCOPE_projects.write")
                        // .requestMatchers(HttpMethod.POST, "/api/**").hasAuthority("SCOPE_write")
                        // .requestMatchers(HttpMethod.GET, "/api/**").hasAuthority("SCOPE_read")

                        // 그 외(정적/기타)는 필요시 정책 조정
                        .anyRequest().denyAll()
                )
                // OAuth2 Resource Server - JWT 검증
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(jwt -> {}))

                // ===== SSO IdP 등록 후 Custom JWT Converter 추가 예시 =====
                // .oauth2ResourceServer(oauth2 -> oauth2
                //     .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                // )

                .httpBasic(basic -> basic.disable())
                .formLogin(form -> form.disable())
                .build();
    }

    // ===== SSO IdP 등록 후 Custom JWT Converter 구현 예시 =====
    // Keycloak의 realm_access.roles를 Spring Security의 GrantedAuthority로 변환
    // @Bean
    // public JwtAuthenticationConverter jwtAuthenticationConverter() {
    //     JwtGrantedAuthoritiesConverter grantedAuthoritiesConverter = new JwtGrantedAuthoritiesConverter();
    //     // Keycloak roles를 ROLE_ prefix와 함께 변환
    //     grantedAuthoritiesConverter.setAuthorityPrefix("ROLE_");
    //     grantedAuthoritiesConverter.setAuthoritiesClaimName("realm_access.roles");
    //
    //     JwtAuthenticationConverter jwtAuthenticationConverter = new JwtAuthenticationConverter();
    //     jwtAuthenticationConverter.setJwtGrantedAuthoritiesConverter(grantedAuthoritiesConverter);
    //     return jwtAuthenticationConverter;
    // }

    /**
     * Multi-Issuer Validator
     *
     * 여러 Issuer를 검증하는 Custom Validator입니다.
     * 개발 환경에서 localhost, IP 등 다양한 접속 경로를 지원합니다.
     */
    private static class MultiIssuerValidator implements OAuth2TokenValidator<Jwt> {
        private final List<String> validIssuers;

        public MultiIssuerValidator(List<String> validIssuers) {
            this.validIssuers = validIssuers;
        }

        @Override
        public OAuth2TokenValidatorResult validate(Jwt jwt) {
            String issuer = jwt.getIssuer().toString();

            if (validIssuers.contains(issuer)) {
                return OAuth2TokenValidatorResult.success();
            }

            return OAuth2TokenValidatorResult.failure(
                    new OAuth2Error(
                            "invalid_token",
                            String.format("Invalid issuer: %s. Allowed issuers: %s", issuer, validIssuers),
                            null
                    )
            );
        }
    }
}
