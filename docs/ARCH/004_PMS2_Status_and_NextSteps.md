# PMS2 개발환경 진행 현황 정리 & 다음 단계 로드맵 (004)
*(Windows 11 / IntelliJ 한글 UI / 경로: `C:\intelliJ\git\pms` 기준)*

## 1. 현재까지 완료된 진행상황 (체크리스트)

### 1) 로컬 개발 기본 도구
- [x] **JDK 21(LTS)** 설치 및 사용 확인
- [x] **IntelliJ IDEA** 설치 및 프로젝트 오픈
- [x] **Git 설치 + 사용자 설정**
  - `user.name = gitsmyun`
  - `user.email = gitsmyun@gmail.com`
- [x] **Docker Desktop 설치 및 동작 확인**
  - `hello-world` 실행 성공
  - Docker Engine 연결 문제 해결 후 compose 실행 성공

### 2) 프로젝트 구조(모노레포)
현재 디렉터리 구조:
```
C:\intelliJ\git\pms
 ├─ backend\pms-backend        # Spring Boot
 ├─ frontend                   # Vue 3 (예정/준비)
 ├─ infra                      # Docker/Compose (DB/Keycloak 등)
 └─ docs                       # 문서
```

### 3) Git 저장소 초기화(로컬)
- [x] 루트에서 `git init` 완료 (현재 브랜치: `master`)
- [x] 루트 `.gitignore` 생성 및 스테이징 완료
- [x] `backend/ docs/ infra/` 를 `git add`까지 수행 완료  
  *(줄바꿈 LF↔CRLF 경고는 Windows 환경에서 흔한 경고이며 기능상 문제 없음)*

> 권장: 첫 커밋 + 브랜치 `main` 변경 + 원격(remote) 연결은 아래 “다음 단계”에서 진행

### 4) PostgreSQL(DB) 컨테이너 실행
- [x] `infra/docker-compose.local.yml` 작성 완료 (PostgreSQL 16)
- [x] 실행 명령 성공:
```powershell
cd C:\intelliJ\git\pms\infra
docker compose -f docker-compose.local.yml up -d
docker ps
```

### 5) Spring Boot 실행 구성(local 프로파일) 적용
- [x] IntelliJ 실행/디버그 구성에서 **활성화된 프로파일 = `local`** 지정 완료
- [x] `application-local.yml` 구성 완료 및 애플리케이션 실행 성공

### 6) Health Check 결과(가장 중요한 확인)
사용자가 제공한 Actuator Health 응답 요약:
- `status: UP`
- `db: UP (PostgreSQL)`
- `livenessState: UP`
- `readinessState: UP`

✅ 결론: **Spring Boot ↔ PostgreSQL 연결이 정상이며, 런타임 상태도 UP**

---

## 2. 앞으로 진행해야 할 사항 (권장 순서)

아래는 **실행 순서대로** 정리했습니다. (MVP → 확장)

---

### Step A) Git “첫 커밋” 완료 + 브랜치 표준화
1) 첫 커밋
```powershell
cd C:\intelliJ\git\pms
git status
git commit -m "chore: initialize PMS2 monorepo skeleton"
```

2) 브랜치명 `main` 전환(권장)
```powershell
git branch -m master main
git status
```

3) 원격 저장소 연결(원격 URL 확보 후)
```powershell
git remote add origin <REMOTE_URL>
git push -u origin main
```

---

### Step B) DB 버전관리 시작: Flyway 마이그레이션 파일 생성
> 목표: **DB 스키마를 “SQL 파일 버전”으로 관리** (배포/협업/검증이 쉬워짐)

1) 폴더 생성
```
backend\pms-backend\src\main\resources\db\migration\
```

2) 최초 파일 생성 (예: `V1__init.sql`)
- 파일명 규칙: `V{숫자}__{설명}.sql`  
  예) `V1__init.sql`, `V2__create_user.sql`

3) 최소 예제(샘플)
```sql
-- V1__init.sql
CREATE TABLE IF NOT EXISTS app_example (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
```

4) 애플리케이션 재실행 → Flyway 로그 확인
- 성공 시 로그에 `Migrating schema ... to version 1` 류 메시지 출력

---

### Step C) API 개발 기반 마련: OpenAPI(Swagger) 추가 (강력 추천)
> 프론트(Vue)와 병렬 개발을 위해 API 문서 자동 생성이 매우 유용합니다.

1) 의존성 추가 (Spring Boot 버전에 맞춰 적용)
2) `/swagger-ui` 접근 확인
3) Controller 작성 시 자동 문서화 확인

---

### Step D) Vue 3 프론트 프로젝트 생성 + 백엔드 프록시 연결
> 목표: CORS 최소화 + 빠른 API 연동

1) Node/npm 버전 확인
```powershell
node -v
npm -v
```

2) Vue(Vite) 생성 (예시)
```powershell
cd C:\intelliJ\git\pms\frontend
npm create vite@latest pms-frontend -- --template vue-ts
cd pms-frontend
npm install
npm run dev
```

3) Vite Proxy 설정 (예: `/api` → `localhost:8080`)
- `vite.config.ts`에 proxy 추가

---

### Step E) 인증/인가: Keycloak(OIDC) + Spring Security(Resource Server)
> 목표: SPA 로그인 → JWT 발급 → API는 JWT 검증 + 권한 적용

권장 순서:
1) docker-compose에 Keycloak 서비스 추가 (Postgres와 함께 기동)
2) Keycloak에서 Realm / Client / Role 구성
3) Vue: OIDC PKCE 로그인(토큰 획득)
4) Spring Boot: Resource Server로 JWT 검증 설정(issuer-uri)
5) Role → Authority 매핑(필요 시 Converter 추가)

---

## 3. Docker → Kubernetes 확장 로드맵 (요약)

1) Docker 기반 개발/테스트 정착
- compose로 `postgres`, (선택) `keycloak`, (선택) `redis/kafka` 구동
- 백엔드는 이미지화(bootBuildImage 또는 Dockerfile)

2) CI/CD 기초 구축(선택)
- 빌드 → 테스트 → 이미지 빌드 → 레지스트리 push

3) Kubernetes 전환 시 변경량
- 현재 구조(무상태/설정 외부화)로 가면 **코드 수정 최소**
- 주로 필요한 것: Deployment/Service/Ingress, Secret/ConfigMap, DB 운영 방식 결정

---

## 4. 다음 작업 추천 “1순위”
현재 상태에서 가장 먼저 추천:
1) **Step A: Git 첫 커밋 완료**
2) **Step B: Flyway 마이그레이션 시작(V1)**
3) **Step C: Swagger(OpenAPI)**
→ 그 다음 Vue / Keycloak 순으로 확장
