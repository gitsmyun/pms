package com.company.pms.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

/**
 * local 보안 설정
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
@Configuration
@Profile({"local", "dev"})
public class SecurityConfig {

    @Bean
    SecurityFilterChain localSecurityFilterChain(HttpSecurity http) throws Exception {
        return http
                // CSRF 끔(local)
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                        // Swagger 허용
                        .requestMatchers(
                                "/swagger-ui.html",
                                "/swagger-ui/**",
                                "/v3/api-docs/**"
                        ).permitAll()
                        // Actuator 허용
                        .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                        // API 허용
                        .requestMatchers("/api/**").permitAll()
                        // 나머지 허용
                        .anyRequest().permitAll()
                )
                // 기본로그인 끔
                .httpBasic(basic -> basic.disable())
                .formLogin(form -> form.disable())
                .build();
    }
}
