package com.company.pms;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

/**
 * 작성일 2026 01 08
 * 작업자 윤성민
 * 설명 이 테스트는 Testcontainers 기반으로 Postgres를 기동한 뒤 스프링 컨텍스트가 정상 부팅되는지 확인한다
 * 설명 로컬 개발과 기본 CI 단계에서는 실행하지 않고 도커 사용이 가능한 환경에서 integrationTest 태스크로 실행한다
 */
@SpringBootTest
@ActiveProfiles("local")
@Import(TestcontainersConfiguration.class)
class PmsBackendIntegrationTest {

    @Test
    void contextLoads() {
    }
}
