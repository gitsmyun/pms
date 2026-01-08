package com.company.pms;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

/**
 * 작성일 2026 01 08
 * 작업자 윤성민
 * 설명 기본 단위 테스트 단계에서는 외부 데이터베이스 없이도 통과해야 하므로 스프링 컨텍스트 로딩 테스트를 비활성화한다
 * 설명 데이터베이스가 필요한 스프링 부팅 검증은 src integrationTest 소스셋의 PmsBackendIntegrationTest에서 Testcontainers로 수행한다
 */
@Disabled("DB Testcontainers 준비 전 기본 단계에서는 Spring 컨텍스트 로딩 테스트를 제외")
@SpringBootTest
class PmsBackendApplicationTests {

    @Test
    void contextLoads() {
    }
}
