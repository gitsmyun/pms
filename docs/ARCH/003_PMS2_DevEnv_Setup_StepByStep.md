# 002. PMS2 개발환경 세팅(설치→설정→실행) 상세 가이드
*(Windows 11, C:\ 드라이브 기준 / IntelliJ + Spring Boot + Vue + PostgreSQL + Docker / (옵션) Keycloak(OIDC) + Spring Security(Resource Server))*  

> **현재 진행 상태(사용자 기준)**
> - ✅ JDK 설치 완료 (Java 21 LTS 사용)
> - ✅ IntelliJ 설치 완료
> - ✅ Spring Boot 백엔드 프로젝트 뼈대 생성 완료
> - ✅ Git 설치 + user.name/user.email 설정 완료
> - ✅ Docker Desktop 설치 완료 및 `docker run --rm hello-world` 성공(정상 동작 확인)
> - ⏭️ 다음: 로컬 인프라(PostgreSQL → (옵션) Keycloak) 기동 + 백엔드 설정 + 프론트(Vue) 생성/연동

---

## 0. 목표(완료 기준)
로컬 PC에서 아래가 “한 번에” 동작하면 개발환경 세팅이 끝난 것입니다.

1. Docker로 **PostgreSQL 컨테이너** 기동
2. Spring Boot가 PostgreSQL에 연결되어 **정상 기동**
3. (옵션) Docker로 **Keycloak 컨테이너** 기동
4. (옵션) Vue(SPA)가 Keycloak 로그인 → **JWT 획득** → Spring Boot API 호출 성공

---

## 1. 권장 폴더 구조(이미 구성된 구조를 기준으로 진행)
이미 IntelliJ에서 아래 구조로 만들어 둔 상태이므로 **추가로 폴더를 만들 필요는 없습니다.**

```
C:\intelliJ\git\pms
 ├─ backend
 │   └─ pms-backend        # Spring Boot 프로젝트(이미 생성됨)
 ├─ frontend               # Vue 프로젝트(이제 생성할 예정)
 └─ infra                  # docker-compose 등 인프라 파일
```

> 기준 경로(권장)
> - 프로젝트 루트: `C:\intelliJ\git\pms`
> - 백엔드: `C:\intelliJ\git\pms\backend\pms-backend`
> - 인프라: `C:\intelliJ\git\pms\infra`
> - 프론트: `C:\intelliJ\git\pms\frontend`

---

## 2. 설치 단계(이미 완료/미완료 체크리스트)

### 2-1) Git (완료)
확인:
```powershell
git --version
git config --global --list
```

### 2-2) Docker Desktop (완료)
정상 확인(이미 hello-world 성공):
```powershell
docker version
docker compose version
docker ps
docker run --rm hello-world
```

### 2-3) Node.js (Vue/Vite용) — *미설치라면 설치 필요*
> Vue 프로젝트를 만들려면 Node.js가 필요합니다.

설치 후 확인:
```powershell
node -v
npm -v
```

---

## 3. IntelliJ + Gradle + JDK 정합성 세팅(필수)
**Gradle 9.x는 JVM 17+ 필요**하므로, 백엔드 프로젝트는 **JDK 21로 고정**해야 합니다.

### 3-1) IntelliJ에서 Gradle JVM을 JDK 21로 지정
- `Settings` → `Build, Execution, Deployment` → `Build Tools` → `Gradle`
  - **Gradle JVM**: `JDK 21` 선택

### 3-2) 프로젝트에 고정(권장)
`C:\intelliJ\git\pms\backend\pms-backend\gradle.properties` 파일에 추가:

```properties
org.gradle.java.home=C:\\Program Files\\Java\\jdk-21.0.9
```

확인:
```powershell
cd C:\intelliJ\git\pms\backend\pms-backend
.\gradlew -v
```
- `Launcher JVM: 21.x` 또는 유사한 출력이면 OK.

---

## 4. 백엔드(Spring Boot) 의존성 정리(현재 상태 기반)
### 4-1) 목표: Keycloak(OIDC) + Resource Server 준비
- **로그인/토큰 발급**: Keycloak
- **API 보호(JWT 검증)**: Spring Security(Resource Server)

따라서 백엔드에 최소로 필요한 의존성은:
- `spring-boot-starter-web`
- `spring-boot-starter-security`
- `spring-boot-starter-oauth2-resource-server`
- `spring-boot-starter-data-jpa`
- `postgresql`
- `flyway`
- (선택) actuator/validation/lombok/devtools

> ⚠️ 초기 단계에서는 Testcontainers로 인한 테스트 오류가 자주 발생하므로,
> “설치/기동 안정화”가 끝나기 전까지는 테스트 컨테이너 관련 파일/의존성은 비활성화 권장.

### 4-2) Gradle 리로드
- IntelliJ 오른쪽 `Gradle` 창 → 🔄 **Reload All Gradle Projects**

### 4-3) 빌드 확인(테스트 제외)
```powershell
cd C:\intelliJ\git\pms\backend\pms-backend
.\gradlew build -x test
```

---

## 5. 로컬 인프라 1단계: PostgreSQL만 먼저 올리기(권장)
> **DB(PostgreSQL)부터 먼저** 올려서 백엔드 연동을 확실히 잡는 방식을 권장합니다.

### 5-1) `infra`에 compose 파일 생성
파일: `C:\intelliJ\git\pms\infra\docker-compose.local.yml`

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:16
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

### 5-2) 실행
```powershell
cd C:\intelliJ\git\pms\infra
docker compose -f docker-compose.local.yml up -d
docker ps
```

정상이라면 `pms-postgres` 컨테이너가 목록에 나타납니다.

### 5-3) (선택) DB 접속 확인
- 로컬에서 DBeaver/pgAdmin 등을 사용해 접속:
  - Host: `localhost`
  - Port: `5432`
  - DB: `pms`
  - User: `pms`
  - Password: `pms`

---

## 6. 백엔드 DB 연결 세팅(application-local.yml)
파일:  
`C:\intelliJ\git\pms\backend\pms-backend\src\main\resources\application-local.yml`

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/pms
    username: pms
    password: pms
  jpa:
    hibernate:
      ddl-auto: validate   # 초기에는 validate 권장(원하면 update로 변경)
  flyway:
    enabled: true

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health,info
```

### 6-1) local 프로파일로 실행되도록 설정
IntelliJ Run/Debug Configuration에서 아래 중 하나:
- Environment variables: `SPRING_PROFILES_ACTIVE=local`
- 또는 VM options: `-Dspring.profiles.active=local`

### 6-2) 실행 확인
- IntelliJ에서 `PmsBackendApplication` 실행
- 브라우저:
  - `http://localhost:8080/actuator/health`

---

## 7. 로컬 인프라 2단계(옵션): Keycloak 추가하기
> Keycloak은 “도커(엔진)”가 아니라 **인증 서버 애플리케이션**입니다.  
> “Keycloak 기반 로그인/JWT”를 붙이려면 Keycloak도 컨테이너로 실행되어야 합니다.

### 7-1) compose에 Keycloak 서비스 추가(POSTGRES + KEYCLOAK)
`C:\intelliJ\git\pms\infra\docker-compose.local.yml`을 아래처럼 확장합니다.

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:16
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

  keycloak:
    image: quay.io/keycloak/keycloak:25.0.6
    container_name: pms-keycloak
    command: start-dev
    restart: unless-stopped
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
    volumes:
      - keycloak-data:/opt/keycloak/data

volumes:
  postgres-data:
  keycloak-data:
```

### 7-2) 실행(이미 postgres가 떠 있으면 재적용)
```powershell
cd C:\intelliJ\git\pms\infra
docker compose -f docker-compose.local.yml up -d
docker ps
```

### 7-3) Keycloak 접속
- 브라우저: `http://localhost:8081`
- Admin ID/PW: `admin` / `admin`

### 7-4) Keycloak 기본 설정(최소)
1. Realm 생성: `pms`
2. Client 생성(프론트 SPA용)
   - Client ID: `pms-spa`
   - Client type: Public
   - Standard Flow(Authorization Code): ON
   - PKCE: ON
   - Redirect URI: `http://localhost:5173/*`
   - Web Origins: `http://localhost:5173`
3. 테스트 유저 생성: `testuser` + 비밀번호 설정

---

## 8. 백엔드: Resource Server(JWT 검증) 설정
### 8-1) 의존성 확인(필수)
- `spring-boot-starter-security`
- `spring-boot-starter-oauth2-resource-server`

### 8-2) issuer-uri 설정 추가
`application-local.yml`에 아래 추가(Realm 이름이 pms일 때):

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8081/realms/pms
```

### 8-3) 최소 SecurityConfig 예시
> 폼 로그인/세션 대신 JWT 검증만 수행하도록 구성합니다.

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

  @Bean
  SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
      .csrf(csrf -> csrf.disable())
      .authorizeHttpRequests(auth -> auth
        .requestMatchers("/actuator/health", "/api/health").permitAll()
        .anyRequest().authenticated()
      )
      .oauth2ResourceServer(oauth2 -> oauth2.jwt())
      .build();
  }
}
```

---

## 9. 프론트(Vue 3 + Vite) 생성 및 실행
> Node.js 설치가 완료되어야 합니다.

### 9-1) Vue 프로젝트 생성
```powershell
cd C:\intelliJ\git\pms
npm create vite@latest frontend -- --template vue-ts
cd frontend
npm install
npm run dev
```

- 브라우저: `http://localhost:5173`

### 9-2) (다음 단계) Keycloak 로그인 연동
- Vue에서 OIDC(PKCE)로 로그인
- Access Token을 받아 API 요청 시 `Authorization: Bearer <token>`로 호출

---

## 10. 실행 순서(매번 이 순서로 하면 빨라짐)
1) 인프라 기동
```powershell
cd C:\intelliJ\git\pms\infra
docker compose -f docker-compose.local.yml up -d
```

2) 백엔드 실행(IntelliJ)
- `SPRING_PROFILES_ACTIVE=local` 확인
- `http://localhost:8080/actuator/health` 확인

3) 프론트 실행
```powershell
cd C:\intelliJ\git\pms\frontend
npm run dev
```

4) (옵션) Keycloak 로그인 → JWT로 API 호출 테스트

---

## 11. 문제 발생 시 빠른 점검
### 11-1) 컨테이너가 안 떠요
```powershell
docker ps
docker logs pms-postgres
docker logs pms-keycloak
```

### 11-2) 포트 충돌(8081/5432)
- 다른 서비스가 같은 포트를 사용 중이면 compose의 `ports` 값을 변경해야 합니다.

### 11-3) Gradle/JDK 오류
- IntelliJ Gradle JVM이 JDK 21인지 확인
- `.\gradlew -v`로 JVM 버전 확인

---

## 12. 다음 문서(003) 추천 범위
- Vue OIDC(PKCE) 로그인 구현(라이브러리 선택 포함)
- Axios 인터셉터로 토큰 자동 첨부
- Role/Authority 매핑(Keycloak Role → Spring GrantedAuthority)
- CORS 정책 정리(개발/운영)
- Docker 이미지 빌드 + (향후) Kubernetes 전환 기본 매니페스트
