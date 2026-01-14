# 🎯 Dev 서버 502 오류 - 최종 요약 및 조치 방법

**날짜**: 2026-01-14  
**오류**: 502 Bad Gateway  
**위치**: `:8181/api/projects`

---

## ✅ 핵심 요약

### 오류 의미
- **502 Bad Gateway**: Frontend(Nginx) → Backend로 요청 전달했지만 Backend가 응답 못함
- **JSON 파싱 오류**: JSON 대신 HTML(Nginx 오류 페이지) 반환됨

### 가장 가능성 높은 원인 (우선순위)
1. 🚨 **Backend 컨테이너가 실행 안됨** (80%)
2. ⏳ **Backend가 아직 시작 중** (15%)
3. ⚙️ **환경 변수 누락/DB 연결 실패** (5%)

---

## 🔧 즉시 실행할 명령 (Dev 서버)

### Step 1: 상태 확인
```bash
# 컨테이너 확인
docker ps -a | grep pms-dev

# 예상 출력:
# pms-dev-backend   Up 5 minutes   0.0.0.0:8080->8080/tcp
# pms-dev-frontend  Up 5 minutes   0.0.0.0:8081->80/tcp
# pms-dev-postgres  Up 5 minutes   0.0.0.0:5542->5432/tcp
```

### Step 2: Backend 로그 확인 (가장 중요!)
```bash
docker logs pms-dev-backend --tail 100

# 찾을 키워드:
# ✅ "Started PmsBackendApplication" → 정상
# ❌ "Failed to configure a DataSource" → DB 연결 실패
# ❌ "Driver claims to not accept jdbcUrl" → 환경 변수 누락
```

### Step 3-A: Backend가 없거나 종료됨
```bash
cd /path/to/pms/infra

# 다운 후 재시작
docker compose -f docker-compose.dev.yml down
docker compose -f docker-compose.dev.yml pull
docker compose -f docker-compose.dev.yml up -d

# 로그 실시간 확인
docker logs pms-dev-backend -f
```

### Step 3-B: Backend가 실행 중이지만 응답 없음
```bash
# Health check
curl http://localhost:8080/actuator/health

# 컨테이너 내부 확인
docker exec pms-dev-backend curl localhost:8080/actuator/health

# 환경 변수 확인
docker inspect pms-dev-backend | grep -A 20 Env | grep -E "(DB_|SPRING_)"
```

---

## 📋 원인별 해결 방법

### Case 1: Backend 컨테이너가 없음

**확인**:
```bash
docker ps -a | grep backend
# 출력 없음 또는 Exited 상태
```

**원인**: 이미지 pull 실패

**해결**:
```bash
# GitHub Actions 확인
# https://github.com/gitsmyun/pms/actions
# "ci build and publish" 워크플로우 성공 확인

# GHCR 패키지 확인
# https://github.com/gitsmyun?tab=packages
# pms-backend:develop-latest 존재 확인

# 수동 pull 테스트
docker pull ghcr.io/gitsmyun/pms-backend:develop-latest

# 인증 필요 시
echo $GITHUB_TOKEN | docker login ghcr.io -u gitsmyun --password-stdin

# 재시작
docker compose -f docker-compose.dev.yml up -d
```

---

### Case 2: 환경 변수 누락

**확인**:
```bash
# 로그에서 확인
docker logs pms-dev-backend | grep "jdbcUrl"
# 출력: Driver claims to not accept jdbcUrl, jdbc:postgresql://${DB_HOST}...
```

**원인**: `.env.dev` 파일 없음 또는 변수 누락

**해결**:
```bash
# .env.dev 파일 확인
cat /path/to/infra/.env.dev

# 없다면 생성
cp /path/to/infra/env/dev.env.example /path/to/infra/.env.dev

# 필수 내용 (최소):
cat > /path/to/infra/.env.dev <<EOF
BACKEND_TAG=develop-latest
FRONTEND_TAG=develop-latest
REPO_OWNER=gitsmyun

SPRING_PROFILES_ACTIVE_DEV=dev
DB_HOST=postgres
DB_PORT=5432
DB_NAME=pms
DB_USER=pms
DB_PASSWORD=pms
SERVER_PORT=8080

OIDC_ISSUER_URI=
CORS_ALLOWED_ORIGINS=
EOF

# 재시작
docker compose -f docker-compose.dev.yml --env-file .env.dev down
docker compose -f docker-compose.dev.yml --env-file .env.dev up -d
```

---

### Case 3: DB 연결 실패

**확인**:
```bash
docker logs pms-dev-backend | grep -i "Failed to configure a DataSource"
```

**원인**: Postgres 컨테이너 미실행 또는 비밀번호 불일치

**해결**:
```bash
# Postgres 상태 확인
docker ps | grep postgres

# Postgres 로그 확인
docker logs pms-dev-postgres

# Postgres 접속 테스트
docker exec pms-dev-postgres psql -U pms -d pms -c "SELECT 1"

# 실패 시 Postgres 재시작
docker compose -f docker-compose.dev.yml restart postgres

# Backend 재시작
docker compose -f docker-compose.dev.yml restart backend
```

---

### Case 4: Backend가 시작 중

**확인**:
```bash
docker logs pms-dev-backend --tail 50
# "Started PmsBackendApplication" 메시지가 없음
# Flyway 마이그레이션 진행 중
```

**원인**: Spring Boot 앱이 느리게 시작 중

**해결**:
```bash
# 1-2분 기다림
sleep 120

# 다시 확인
curl http://localhost:8080/actuator/health

# 여전히 실패하면
docker logs pms-dev-backend -f
# 오류 메시지 확인
```

---

## 🎯 빠른 체크리스트

### Dev 서버 관리자용
- [ ] SSH로 Dev 서버 접속
- [ ] `docker ps -a | grep pms-dev` 실행
- [ ] `docker logs pms-dev-backend --tail 100` 확인
- [ ] "Started PmsBackendApplication" 메시지 찾기
  - ✅ 있음 → 네트워크 문제 (030 문서 참조)
  - ❌ 없음 → 시작 실패 (아래 계속)
- [ ] 오류 메시지 확인:
  - "Failed to configure a DataSource" → DB 연결 실패
  - "Driver claims to not accept jdbcUrl" → 환경 변수 누락
  - "Flyway" 오류 → 마이그레이션 실패
- [ ] `.env.dev` 파일 존재 확인
- [ ] GitHub Actions 성공 확인
- [ ] `docker compose down && docker compose pull && docker compose up -d`

---

## 📞 도움 요청 시 제공할 정보

1. **컨테이너 상태**:
   ```bash
   docker ps -a | grep pms-dev
   ```

2. **Backend 로그** (최근 100줄):
   ```bash
   docker logs pms-dev-backend --tail 100
   ```

3. **환경 변수**:
   ```bash
   docker inspect pms-dev-backend | grep -A 30 Env
   ```

4. **GitHub Actions 상태**:
   - URL: https://github.com/gitsmyun/pms/actions
   - 최근 워크플로우 실행 결과 스크린샷

---

## 🔗 관련 문서

- **030_Dev_Server_502_BadGateway_Analysis_260114.md**: 상세 분석 및 모든 케이스
- **029_Corrected_Approach_Direct_Develop_Push_260114.md**: CI/CD 흐름 및 진행 상황
- **024_PMS2_CurrentStatus_Review_and_NextSteps_260114.md**: 전체 프로젝트 현황

---

## 💡 임시 해결 방법 (긴급 시)

Dev 서버가 계속 실패한다면 **로컬 프로파일**로 임시 우회:

```bash
# .env.dev 수정
SPRING_PROFILES_ACTIVE_DEV=local  # dev → local

# 재시작
docker compose -f docker-compose.dev.yml restart backend
```

**주의**: `local` 프로파일은 인증 없음(permitAll), Dev 환경에서는 권장하지 않음. 문제 해결 후 `dev`로 복원 필요.

---

**작성**: GitHub Copilot  
**긴급도**: 🚨 P0 (즉시 조치 필요)  
**예상 해결 시간**: 5-30분 (원인 파악 후)

