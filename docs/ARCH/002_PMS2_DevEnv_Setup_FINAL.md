# 002. PMS2 개발환경 세팅 상세 가이드 (경로/Keycloak 보정본)
*(Windows 11 / C:\intelliJ\git\pms 기준)*

이 문서는 **001_PMS2_TechSetup_and_ProjectCreation.md**를 기반으로,
현재 실제 사용 중인 **로컬 경로**, **Docker 기반 DB 운영 방식**,  
그리고 **Keycloak(OIDC) + Spring Security(Resource Server)** 논의를 반영하여
**누락·혼동될 수 있는 부분을 보정한 전체 버전 문서**입니다.

> ⚠️ 주의  
> 이전에 전달된 002 문서 중 “내용 동일” 요약본은 오류이며,  
> **이 문서가 002의 최종·정식 버전**입니다.

---

## 0. 현재 진행 상태 기준 정리

- OS: Windows 11
- 작업 루트 경로: `C:\intelliJ\git\pms`
- JDK: Java 21 LTS
- IDE: IntelliJ IDEA
- Backend: Spring Boot (Gradle, Kotlin DSL)
- Frontend: Vue 3 + Vite (예정)
- DB: PostgreSQL (Docker 컨테이너)
- Auth: Keycloak (OIDC, 선택 단계)
- Container: Docker Desktop (설치 및 정상 동작 확인 완료)

---

## 1. 실제 프로젝트 디렉터리 구조 (확정)

```
C:\intelliJ\git\pms
 ├─ backend
 │   └─ pms-backend        # Spring Boot 프로젝트
 ├─ frontend               # Vue 3 프로젝트
 └─ infra                  # docker-compose, 인프라 설정
```

> ✔ 기존 문서의 `D:\workspace\PMS2`는 **예시 경로**였으며  
> ✔ 현재 프로젝트는 위 경로를 **공식 기준**으로 사용합니다.

---

## 2. 기술 스택 확정 (현재 합의 기준)

| 구분 | 기술 |
|---|---|
| IDE | IntelliJ IDEA |
| Language | Java 21 (LTS) |
| Backend | Spring Boot |
| Build | Gradle (Kotlin DSL) |
| Security | Spring Security + OAuth2 Resource Server |
| Auth Server | Keycloak (OIDC) |
| Frontend | Vue 3 + Vite + TypeScript |
| Database | PostgreSQL |
| Container | Docker / Docker Compose |
| Infra Target | Docker → Kubernetes 확장 고려 |

---

## 3. DB(PostgreSQL)는 왜 “다운로드” 과정이 없는가

### 결론
PostgreSQL은 **로컬에 직접 설치하지 않습니다.**

- ❌ exe / msi 설치 파일 사용 안 함
- ❌ Windows 서비스로 DB 설치 안 함
- ✅ Docker 이미지(`postgres`) 사용
- ✅ `docker compose up` 시 자동으로 이미지 pull

즉,
> **DB 다운로드 = Docker 이미지 자동 pull**

이 방식은:
- 환경 오염 없음
- 팀원 간 환경 동일
- Kubernetes 전환 시 그대로 사용 가능  
이라는 장점 때문에 **최신 프로젝트 표준**입니다.

---

## 4. 로컬 인프라 1단계: PostgreSQL 컨테이너 실행

### 4.1 docker-compose 파일 생성

**경로**
```
C:\intelliJ\git\pms\infra\docker-compose.local.yml
```

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:18
    container_name: pms-postgres
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: pms
      POSTGRES_USER: pms
      POSTGRES_PASSWORD: pms
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

### 4.2 실행

```powershell
cd C:\intelliJ\git\pms\infra
docker compose -f docker-compose.local.yml up -d
docker ps
```

---

## 5. Spring Boot 백엔드 DB 연동

### 5.1 application-local.yml

**경로**
```
backend/pms-backend/src/main/resources/application-local.yml
```

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/pms
    username: pms
    password: pms

  jpa:
    hibernate:
      ddl-auto: validate

server:
  port: 8080
```

### 5.2 실행 확인

- IntelliJ에서 애플리케이션 실행
- 환경 변수:
  ```
  SPRING_PROFILES_ACTIVE=local
  ```
- 확인 URL:
  ```
  http://localhost:8080/actuator/health
  ```

---

## 6. Keycloak의 위치와 역할 (개념 정리)

### 6.1 Keycloak은 무엇인가
- OAuth2 / OIDC 기반 **인증 서버**
- 사용자 관리
- 로그인 UI 제공
- JWT(Access Token) 발급

### 6.2 Docker와의 관계
- Docker = 실행 환경
- Keycloak = 컨테이너로 실행되는 애플리케이션
- Docker를 설치해도 Keycloak은 **자동으로 올라가지 않음**

---

## 7. 로컬 인프라 2단계: PostgreSQL + Keycloak 실행

### 7.1 docker-compose 확장

```yaml
services:
  postgres:
    image: postgres:18
    container_name: pms-postgres
    environment:
      POSTGRES_DB: pms
      POSTGRES_USER: pms
      POSTGRES_PASSWORD: pms

  keycloak:
    image: quay.io/keycloak/keycloak:25.0.6
    container_name: pms-keycloak
    command: start-dev
    depends_on:
      - postgres
    ports:
      - "8081:8080"
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/pms
      KC_DB_USERNAME: pms
      KC_DB_PASSWORD: pms
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
```

### 7.2 실행

```powershell
docker compose -f docker-compose.local.yml up -d
```

### 7.3 접속

- Admin Console: http://localhost:8081
- 계정: admin / admin

---

## 8. Spring Security + Keycloak 역할 분담 (중요)

| 구성요소 | 역할 |
|---|---|
| Keycloak | 로그인, 사용자/권한 관리, JWT 발급 |
| Vue(SPA) | 로그인 요청, 토큰 저장 |
| Spring Boot API | Resource Server |
| Spring Security | JWT 검증, 인가 처리 |

> Spring Security를 사용하지 않으면  
> → JWT 검증, 권한 처리, 보안 컨텍스트를 **직접 구현**해야 하며  
> → 실무적으로 유지보수·보안 리스크가 큼

---

## 9. Resource Server 설정

### 9.1 의존성
- spring-boot-starter-security
- spring-boot-starter-oauth2-resource-server

### 9.2 issuer 설정

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8081/realms/pms
```

### 9.3 최소 SecurityConfig

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

  @Bean
  SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
      .csrf(csrf -> csrf.disable())
      .authorizeHttpRequests(auth -> auth
        .requestMatchers("/actuator/health").permitAll()
        .anyRequest().authenticated()
      )
      .oauth2ResourceServer(oauth -> oauth.jwt())
      .build();
  }
}
```

---

## 10. Kubernetes 확장성 관점 검증

- 모든 컴포넌트 무상태 설계
- 설정은 ENV 기반
- Docker 이미지 → K8s Deployment 그대로 사용 가능
- 코드 수정 필요 없음

---

## 11. 최종 결론

- DB는 Docker 이미지 기반 자동 pull 방식 → 정상
- 현재 경로 `C:\intelliJ\git\pms` 기준이 맞음
- Keycloak은 선택적이지만 인증 구조상 핵심
- Spring Security는 JWT 검증/인가를 위해 반드시 사용
- 현 구성은 Kubernetes 전환에 적합

---

## 다음 문서(003) 예고
- Keycloak Realm / Client / Role 설계
- Vue(OIDC PKCE) 로그인 흐름
- Role → Spring Authority 매핑
