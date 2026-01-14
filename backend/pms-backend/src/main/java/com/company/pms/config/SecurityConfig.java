package com.company.pms.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/**
 * (Deprecated) 기존 local/dev 공용 permitAll 설정.
 *
 * 현재는 보안 기준선에 따라 아래 설정으로 분리한다.
 * - local: {@link SecurityLocalConfig}
 * - dev/test/prod: {@link SecurityOidcConfig}
 *
 * 이 클래스는 호환성을 위해 남겨두되, 어떤 프로파일에서도 활성화되지 않도록 한다.
 */
@Configuration
@Profile("never")
public class SecurityConfig {
    // intentionally empty
}
