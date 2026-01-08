package com.company.pms;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * 작성일 2026 01 08
 * 작업자 윤성민
 * 설명 이 설정은 통합 테스트 실행 시 Postgres Testcontainer를 자동으로 생성하고 스프링 데이터소스에 연결한다
 * 설명 통합 테스트는 별도 소스셋에서 실행되므로 동일 소스셋에 설정 클래스를 둬서 의존 관계를 단순화한다
 */
@TestConfiguration(proxyBeanMethods = false)
class TestcontainersConfiguration {

    @Bean
    @ServiceConnection
    PostgreSQLContainer<?> postgresContainer() {
        return new PostgreSQLContainer<>(DockerImageName.parse("postgres:18"));
    }
}

