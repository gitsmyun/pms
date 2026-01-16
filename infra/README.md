# Infra - Docker Compose 환경별 배포

PMS2.0 프로젝트의 Docker Compose 기반 인프라 구성 파일입니다.

## 📁 디렉터리 구조

```
infra/
├── env/                          # 환경변수 파일
│   ├── .gitignore               # *.env 파일 git 제외
│   ├── setup-env.ps1            # 환경변수 설정 스크립트 (Windows)
│   ├── setup-env.sh             # 환경변수 설정 스크립트 (Linux/Mac)
│   ├── local.env.example        # Local 환경 템플릿
│   ├── dev.env.example          # Dev 환경 템플릿
│   ├── test.env.example         # Test 환경 템플릿
│   └── prod.env.example         # Prod 환경 템플릿
├── docker-compose.local.yml     # Local: DB만
├── docker-compose.dev.yml       # Dev: 전체 스택 + Keycloak
├── docker-compose.test.yml      # Test: CI/CD용
└── docker-compose.prod.yml      # Prod: 운영 환경
```

## 🚀 빠른 시작

### 1. 환경변수 파일 생성

#### Windows (PowerShell):
```powershell
cd infra\env
.\setup-env.ps1 -Environment dev
```

#### Linux/Mac:
```bash
cd infra/env
chmod +x setup-env.sh
./setup-env.sh dev
```

### 2. 환경변수 파일 수정

생성된 `env/dev.env` 파일을 편집기로 열어 필요한 값을 설정합니다:

```bash
# Windows
notepad env\dev.env

# Linux/Mac
vi env/dev.env
```

**필수 설정 항목** (SSO 사용 시):
- `OIDC_ISSUER_URI`: Keycloak Issuer URI
- `CORS_ALLOWED_ORIGINS`: 허용할 Origin (콤마로 구분)

### 3. Docker Compose 실행

```bash
# Dev 환경
docker compose --env-file env/dev.env -f docker-compose.dev.yml up -d

# Local 환경 (DB만)
docker compose --env-file env/local.env -f docker-compose.local.yml up -d

# 로그 확인
docker compose -f docker-compose.dev.yml logs -f backend
```

### 4. 서비스 접속

| 서비스 | URL | 비고 |
|--------|-----|------|
| Frontend | http://localhost:8181 | Vue 3 SPA |
| Backend API | http://localhost:8180 | Spring Boot 4 |
| Swagger UI | http://localhost:8180/swagger-ui.html | Dev 환경만 |
| Keycloak | http://localhost:8280 | Dev 환경만 |
| PostgreSQL | localhost:5542 | DB 클라이언트 접속용 |

## 📋 환경별 구성

### Local (로컬 개발)

**파일**: `docker-compose.local.yml`

**포함 서비스**:
- PostgreSQL 18

**용도**:
- 로컬에서 백엔드/프론트엔드를 IntelliJ/Vite로 직접 실행
- DB만 Docker로 실행

**실행**:
```bash
docker compose -f docker-compose.local.yml up -d
```

### Dev (개발 서버)

**파일**: `docker-compose.dev.yml`

**포함 서비스**:
- PostgreSQL 18
- Backend (Spring Boot 4)
- Frontend (Vue 3 + Nginx)
- Keycloak 23 (SSO IdP)

**용도**:
- 전체 스택을 Docker로 실행
- SSO 테스트
- 통합 테스트

**실행**:
```bash
docker compose --env-file env/dev.env -f docker-compose.dev.yml up -d
```

### Test (CI/CD)

**파일**: `docker-compose.test.yml`

**포함 서비스**:
- PostgreSQL 18
- Backend (테스트 프로파일)

**용도**:
- GitHub Actions CI/CD
- 통합 테스트 자동화

**실행**:
```bash
docker compose --env-file env/test.env -f docker-compose.test.yml up -d
```

### Prod (운영)

**파일**: `docker-compose.prod.yml`

**포함 서비스**:
- PostgreSQL 18
- Backend (프로덕션 프로파일)
- Frontend (프로덕션 빌드)

**용도**:
- 운영 환경 배포
- 외부 Keycloak 사용 (컨테이너 포함 안 함)

**실행**:
```bash
docker compose --env-file env/prod.env -f docker-compose.prod.yml up -d
```

## 🔐 보안 설정

### 환경변수 파일 보안

**중요**: `*.env` 파일은 **절대 Git에 커밋하지 않습니다!**

`.gitignore` 설정:
```gitignore
*.env
!*.env.example
```

### 운영 환경 필수 체크리스트

- [ ] `OIDC_ISSUER_URI` 설정 (SSO 인증 필수)
- [ ] `CORS_ALLOWED_ORIGINS` 명시적 설정 (와일드카드 금지)
- [ ] DB 비밀번호 강력한 값으로 변경
- [ ] `SWAGGER_ENABLED_DEV=false` 설정
- [ ] HTTPS 적용 (Reverse Proxy)
- [ ] 포트 외부 노출 최소화

## 🛠️ 유용한 명령어

### 서비스 관리

```bash
# 전체 시작
docker compose -f docker-compose.dev.yml up -d

# 특정 서비스만 재시작
docker compose -f docker-compose.dev.yml restart backend

# 로그 확인
docker compose -f docker-compose.dev.yml logs -f backend

# 전체 중지
docker compose -f docker-compose.dev.yml down

# 볼륨 포함 삭제 (데이터 초기화)
docker compose -f docker-compose.dev.yml down -v
```

### 상태 확인

```bash
# 실행 중인 컨테이너
docker compose -f docker-compose.dev.yml ps

# 리소스 사용량
docker stats

# 네트워크 확인
docker network ls
docker network inspect infra_default
```

### 문제 해결

```bash
# 컨테이너 내부 접속
docker exec -it pms-dev-backend bash
docker exec -it pms-dev-postgres psql -U pms -d pms

# 이미지 재빌드 (코드 변경 시)
docker compose -f docker-compose.dev.yml up -d --build backend

# 전체 재시작 (깨끗하게)
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.dev.yml up -d --force-recreate
```

## 🔗 관련 문서

- [로컬 개발 가이드](../docs/ARCH/260114/021_LOCAL_DEVELOPMENT_GUIDE.md)
- [SSO 통합 가이드](../docs/ARCH/260115/002_SSO_Implementation_Enterprise_Solution.md)
- [Keycloak 빠른 시작](../docs/ARCH/260115/001_SSO_KEYCLOAK_QUICKSTART.md)

## 📞 문제 발생 시

1. 로그 확인: `docker compose -f docker-compose.dev.yml logs -f`
2. 컨테이너 상태 확인: `docker compose -f docker-compose.dev.yml ps`
3. 네트워크 확인: `docker network inspect infra_default`
4. 이슈 등록: GitHub Issues에 로그 첨부

---

**마지막 업데이트**: 2026-01-15  
**관리자**: PMS2.0 개발팀

