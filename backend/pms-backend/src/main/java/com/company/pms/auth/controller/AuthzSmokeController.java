package com.company.pms.auth.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 인증/인가 동작 스모크 테스트용 엔드포인트.
 * 엔터프라이즈 권장:
 * - 보안 설정(SecurityFilterChain) 단위 검증은 DB/JPA/Flyway 같은 인프라 의존성과 분리되어야 CI/로컬에서 안정적으로 검증 가능하다.
 * - 이 엔드포인트는 인증이 걸린 상태(401/200)만 확인하는 용도로 사용한다.
 */
@RestController
public class AuthzSmokeController {

    @GetMapping("/api/_authz_smoke")
    public String authzSmoke() {
        return "ok";
    }
}
