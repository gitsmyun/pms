# PMS2.0 (Project Management System)

엔터프라이즈급 프로젝트 관리 시스템

## 🚀 빠른 시작

### ✅ 환경 검증 (권장)

```powershell
# 빠른 검증 (5초)
.\quick-verify.ps1

# 또는 전체 검증 (1분, 빌드 포함)
.\verify-local-env.ps1
```

**결과 예시:**
```
SUCCESS: All checks passed!
```

### 로컬 환경 검증

```powershell
# 환경 자동 검증 (위에서 이미 통과!)
.\verify-local-env.ps1
```

### 로컬 개발 환경 실행

```powershell
# 1. DB 기동
cd infra
docker compose -f docker-compose.local.yml up -d

# 2. 백엔드 실행 (IntelliJ 권장)
# - docs/020_INTELLIJ_RUN_CONFIG_GUIDE.md 참조

# 3. 프론트엔드 실행
cd frontend
pnpm install
pnpm dev

# 4. 접속
# - Swagger UI: http://localhost:8080/swagger-ui.html
# - Frontend: http://localhost:5173
```

📘 **자세한 가이드**: [`docs/LOCAL_DEVELOPMENT_GUIDE.md`](docs/ARCH/260114/021_LOCAL_DEVELOPMENT_GUIDE.md)

---

## 📋 기술 스택

### 백엔드
- **Java 21** (LTS)
- **Spring Boot 4.0.0**
- **Spring Security** + OAuth2 Resource Server (OIDC/JWT)
- **Spring Data JPA** + Flyway
- **PostgreSQL 18**

### 프론트엔드
- **Vue 3** + TypeScript
- **Vite 6**
- **Tailwind CSS v4**
- **pnpm** (패키지 매니저)

### 인프라
- **Docker** + Docker Compose
- **Gradle** (Kotlin DSL)
- 향후: **Kubernetes**

---

## 📂 프로젝트 구조

```
pms/
├── backend/
│   └── pms-backend/          # Spring Boot 4 백엔드
├── frontend/                 # Vue 3 + Vite 프론트엔드
├── infra/
│   ├── docker-compose.*.yml  # 환경별 Docker Compose 파일
│   └── env/                  # 환경변수 템플릿
├── docs/
│   ├── LOCAL_DEVELOPMENT_GUIDE.md       # 🌟 로컬 개발 가이드
│   ├── INTELLIJ_RUN_CONFIG_GUIDE.md     # IntelliJ 설정
│   ├── ARCH_COMPLIANCE_STATUS.md        # 아키텍처 준수 현황
│   └── ARCH/                            # 아키텍처 설계 문서
├── k8s/                      # Kubernetes 매니페스트 (향후)
└── verify-local-env.ps1      # 환경 검증 스크립트
```

---

## 🔐 보안 아키텍처

### 프로파일별 보안 설정

| 프로파일 | 인증 방식 | Swagger | 용도 |
|---------|----------|---------|------|
| `local` | permitAll | ON | 로컬 개발 |
| `dev` | OIDC JWT | 토글 | 개발 서버 |
| `test` | Mock JWT | OFF | CI/CD 테스트 |
| `prod` | OIDC JWT | OFF | 운영 |

### OIDC 적용 현황

✅ **Phase 0**: 기준선 합의/문서화 (완료)  
✅ **Phase 1**: OIDC Resource Server 코드 준비 (완료)  
🚧 **Phase 2**: 프론트엔드 OIDC 클라이언트 (준비 중)

📘 **SSO 로드맵**: [`docs/ARCH/260114/001_PMS2_Enterprise_SSO_Security_Roadmap_260114.md`](docs/ARCH/260114/001_PMS2_Enterprise_SSO_Security_Roadmap_260114.md)

---

## 🛠️ 개발 환경 설정

### 사전 요구사항

- **JDK 21**
- **Node.js 24** LTS
- **Docker Desktop**
- **pnpm** (`npm install -g pnpm`)
- **IntelliJ IDEA** Ultimate (권장)

### 백엔드 빌드

```powershell
cd backend\pms-backend
.\gradlew clean build

# 테스트 제외 빌드
.\gradlew build -x test
```

### 프론트엔드 빌드

```powershell
cd frontend
pnpm install
pnpm build
```

---

## 🧪 테스트

### 백엔드 테스트

```powershell
cd backend\pms-backend

# 전체 테스트
.\gradlew test

# 특정 테스트
.\gradlew test --tests SecurityOidcConfigTest

# 통합 테스트 (Testcontainers)
.\gradlew integrationTest
```

### 프론트엔드 테스트

```powershell
cd frontend
pnpm test
```

---

## 🚢 배포

### Dev 환경 배포

```powershell
cd infra
cp env\dev.env.example env\dev.env
# dev.env 편집 (OIDC_ISSUER_URI 등 설정)

docker compose --env-file env\dev.env -f docker-compose.dev.yml up -d
```

### 이미지 빌드

```powershell
# 백엔드
cd backend\pms-backend
.\gradlew bootBuildImage

# 프론트엔드
cd frontend
docker build -t pms-frontend .
```

📘 **배포 가이드**: `docs/DEPLOYMENT_GUIDE.md` (향후)

---

## 📚 문서

### 실행 가이드
- 🌟 [로컬 개발 환경](docs/ARCH/260114/021_LOCAL_DEVELOPMENT_GUIDE.md) - **시작하기**
- [IntelliJ Run Configuration](docs/ARCH/260114/020_INTELLIJ_RUN_CONFIG_GUIDE.md)

### 아키텍처
- [아키텍처 준수 현황](docs/ARCH/260114/015_ARCH_COMPLIANCE_STATUS.md)
- [기술 스택 정의](docs/ARCH/260105/001_PMS2_TechSetup_and_ProjectCreation.md)
- [SSO 보안 로드맵](docs/ARCH/260114/001_PMS2_Enterprise_SSO_Security_Roadmap_260114.md)

### 프로젝트 관리
- [브랜칭 전략](docs/ARCH/260114/017_BRANCHING_AND_RELEASE_KR.md)

---

## 🐛 트러블슈팅

### 환경 변수 미설정 오류

**증상:**
```
JDBC URL invalid port number: ${DB_PORT}
Driver claims to not accept jdbcUrl, jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
```

**원인:** IntelliJ Run Configuration에 환경 변수가 설정되지 않음

**해결:**
1. `Run → Edit Configurations...`
2. `Environment variables` 필드 옆 📁 아이콘 클릭
3. 다음 변수 추가 (세미콜론 구분):
   ```
   DB_HOST=localhost;DB_PORT=5432;DB_NAME=pms;DB_USER=pms;DB_PASSWORD=pms;SPRING_PROFILES_ACTIVE=local
   ```
4. `Apply` → `OK`
5. 다시 실행

**⚠️ 주의**: EnvFile 플러그인은 Java 1.8용이므로 Java 21 환경에서는 수동 설정을 권장합니다.

📋 **상세 가이드**: `BACKEND_START_FIX.md` 또는 `ENV_SETUP_COMPLETE.md`

### API 요청 403 Forbidden 오류

**증상:**
```
POST http://localhost:5173/api/projects 403 (Forbidden)
```

**원인:** CORS 설정에서 localhost가 허용되지 않음

**해결:** 이미 수정됨! 백엔드 재시작하세요.
```powershell
# IntelliJ에서 Stop → Run
# 또는 Gradle 재시작
```

`CorsConfig.java`가 이미 localhost를 기본으로 허용하도록 수정되었습니다.

📋 **상세**: `CORS_403_FIXED.md`

### 컨테이너 이름 충돌 오류

**증상:**
```
Error: The container name "/pms-postgres" is already in use
```

**해결:**
```powershell
# 기존 컨테이너 강제 제거
docker rm -f pms-postgres

# 다시 시작
cd infra
docker compose -f docker-compose.local.yml up -d
```

### DB 연결 오류

```powershell
# 컨테이너 확인
docker ps

# 컨테이너 재시작
cd infra
docker compose -f docker-compose.local.yml down
docker compose -f docker-compose.local.yml up -d
```

### 빌드 오류

```powershell
# Gradle 캐시 정리
cd backend\pms-backend
.\gradlew clean --no-daemon

# IntelliJ 캐시 정리
# File → Invalidate Caches → Invalidate and Restart
```

📘 **상세 트러블슈팅**: [`docs/LOCAL_DEVELOPMENT_GUIDE.md#트러블슈팅`](docs/ARCH/260114/021_LOCAL_DEVELOPMENT_GUIDE.md#트러블슈팅)

---

## 🤝 기여하기

1. Feature 브랜치 생성: `git checkout -b feature/amazing-feature`
2. 변경사항 커밋: `git commit -m 'Add amazing feature'`
3. 브랜치 푸시: `git push origin feature/amazing-feature`
4. Pull Request 생성

---

## 📝 라이선스

This project is proprietary and confidential.

---

## 📧 문의

프로젝트 관련 문의는 팀 리더에게 연락하세요.

---

## 🎯 다음 단계

1. **로컬 환경 실행**: `docs/LOCAL_DEVELOPMENT_GUIDE.md` 따라하기
2. **Dev 환경 OIDC 연동**: Keycloak/IdP 설정
3. **프론트엔드 OIDC 클라이언트 구현**: Phase 2 진행

---

**Made with ❤️ by PMS Team**

