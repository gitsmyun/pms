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
 * Dev 환경에서 OIDC_ISSUER_URI가 설정되지 않았을 때 사용하는 fallback 보안 설정.
 * SSO IdP 준비 전까지 임시로 사용됨.
 */
@Configuration
@EnableWebSecurity
@Profile({"dev"})
@ConditionalOnProperty(
    name = "spring.security.oauth2.resourceserver.jwt.issuer-uri",
    havingValue = "",
    matchIfMissing = true
)
public class SecurityDevFallbackConfig {

    @Bean
    public SecurityFilterChain devFallbackSecurityFilterChain(HttpSecurity http) throws Exception {
        return http
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                        // Actuator 허용
                        .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                        // Preflight 허용
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // Dev 환경 임시: API 허용 (SSO 준비 전까지)
                        .requestMatchers("/api/**").permitAll()
                        .anyRequest().permitAll()
                )
                .httpBasic(basic -> basic.disable())
                .formLogin(form -> form.disable())
                .build();
    }
}

