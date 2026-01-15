package com.company.pms.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
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
 */
@Configuration
@EnableWebSecurity
@Profile({"dev", "test"})
@ConditionalOnProperty(
    name = "spring.security.oauth2.resourceserver.jwt.issuer-uri",
    matchIfMissing = true
)
public class SecurityDevConfig {

    @Bean
    public SecurityFilterChain devSecurityFilterChain(HttpSecurity http) {
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

