package com.company.pms.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * 엔터프라이즈 권장: dev/test/prod는 OIDC(OAuth2 Resource Server) 기반 JWT 검증을 기본으로 한다.
 * OIDC_ISSUER_URI가 실제로 설정되어 있을 때만 활성화됨.
 */
@Configuration
@Profile({"dev", "test", "prod"})
@ConditionalOnProperty(
    name = "spring.security.oauth2.resourceserver.jwt.issuer-uri"
)
public class SecurityOidcConfig {

    @Bean
    public SecurityFilterChain oidcSecurityFilterChain(HttpSecurity http) throws Exception {
        return http
                // API 서버이므로 기본은 stateless
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // SPA + bearer 기반이면 CSRF 불필요(쿠키 세션 방식으로 전환 시 재검토)
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                        // Actuator 최소 허용
                        .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                        // Preflight 허용
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // 나머지 API는 인증 필요
                        .requestMatchers("/api/**").authenticated()
                        // 그 외(정적/기타)는 필요시 정책 조정
                        .anyRequest().denyAll()
                )
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(jwt -> {}))
                .httpBasic(basic -> basic.disable())
                .formLogin(form -> form.disable())
                .build();
    }
}
