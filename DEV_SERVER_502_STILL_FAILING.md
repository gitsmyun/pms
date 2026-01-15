# 🚨 Dev 서버 여전히 502 오류 - 즉시 조치 필요

**날짜**: 2026-01-14 18:35 KST  
**상태**: Backend가 여전히 시작 실패 중  
**원인**: 최신 이미지(수정본)를 아직 pull하지 않음

---

## 🔍 현재 상황

### 오류 메시지
```
GET http://localhost:8181/api/projects 502 (Bad Gateway)
목록 로드 실패: SyntaxError: Unexpected token '<', "<html> <h"... is not valid JSON
```

### 문제
- ✅ Backend 수정 완료 (SecurityDevFallbackConfig 추가)
- ✅ GitHub에 push 완료
- ⏳ GitHub Actions 실행 중 또는 완료
- ❌ **Dev 서버가 아직 구버전 이미지 사용 중!**

---

## 🎯 즉시 실행할 명령 (Dev 서버)

### Step 1: GitHub Actions 완료 확인

**브라우저에서**:
```
https://github.com/gitsmyun/pms/actions
```

**확인 사항**:
- ✅ "ci build and publish" 워크플로우 완료
- ✅ 모든 체크 녹색 (✓)
- ✅ 실행 시간: 약 5-10분

**아직 실행 중이라면**: 완료 대기 (5-10분)

---

### Step 2: 최신 이미지 Pull 및 재시작

**Dev 서버 SSH 접속 후**:

```bash
# 현재 위치로 이동
cd /opt/pms/infra  # 또는 실제 경로

# 1. 현재 실행 중인 컨테이너 확인
docker ps | grep pms-dev

# 2. Backend 컨테이너 중지
docker compose -f docker-compose.dev.yml stop backend

# 3. 최신 이미지 Pull (develop-latest)
docker compose -f docker-compose.dev.yml pull backend

# 출력 확인:
# Pulling backend ... done
# 또는
# backend is up to date (이미 최신인 경우)

# 4. Backend 재시작
docker compose -f docker-compose.dev.yml up -d backend

# 5. 로그 확인 (실시간)
docker logs pms-dev-backend -f
```

---

### Step 3: 성공 확인

**로그에서 찾을 메시지**:

✅ **성공 시**:
```
Started PmsBackendApplication in X.XXX seconds
SecurityDevFallbackConfig activated  # ← 새로 추가된 설정!
```

❌ **여전히 실패 시** (구버전):
```
No qualifying bean of type 'org.springframework.security.oauth2.jwt.JwtDecoder' available
```

---

### Step 4: API 테스트

```bash
# Health Check
curl http://localhost:8180/actuator/health
# 예상: {"status":"UP"}

# API 호출
curl http://localhost:8180/api/projects
# 예상: [] (빈 배열) 또는 데이터
```

---

## 🔧 문제 해결 (단계별)

### Case 1: GitHub Actions가 아직 실행 중

**증상**: Actions 페이지에서 노란색 원 (진행 중)

**조치**: 
```
완료 대기 (5-10분)
또는
커피 한 잔 ☕
```

---

### Case 2: GitHub Actions 실패

**증상**: Actions 페이지에서 빨간색 X

**조치**:
```bash
# 로그 확인
# https://github.com/gitsmyun/pms/actions
# 실패한 워크플로우 클릭 → 로그 확인

# 일반적 원인:
# - pnpm 오류 (이미 수정했음)
# - 테스트 실패
# - Docker 빌드 오류
```

---

### Case 3: Pull했는데 여전히 구버전

**증상**: Pull 성공했는데 로그에 여전히 JwtDecoder 오류

**원인**: Docker 캐시 문제

**조치**:
```bash
# 1. 강제 재pull (--no-cache)
docker compose -f docker-compose.dev.yml pull --no-cache backend

# 2. 이미지 확인
docker images | grep pms-backend

# 출력 예:
# ghcr.io/gitsmyun/pms-backend  develop-latest  abc123  2 minutes ago

# 3. 이미지 ID와 시간 확인
# "2 minutes ago" → 최신 ✅
# "3 hours ago" → 구버전 ❌

# 4. 구버전이면 수동 pull
docker pull ghcr.io/gitsmyun/pms-backend:develop-latest

# 5. 재시작
docker compose -f docker-compose.dev.yml up -d backend
```

---

### Case 4: Pull 성공, Backend 시작했지만 여전히 502

**증상**: 
- ✅ "Started PmsBackendApplication" 로그 확인
- ✅ Health check 성공
- ❌ Frontend에서 여전히 502

**원인**: Nginx 캐시 또는 Frontend 컨테이너 문제

**조치**:
```bash
# 1. Frontend 재시작
docker compose -f docker-compose.dev.yml restart frontend

# 2. 브라우저 캐시 클리어
# Ctrl + Shift + R (하드 리프레시)
# 또는 시크릿 모드로 접속

# 3. Network 확인
docker exec pms-dev-frontend wget -O- http://backend:8080/actuator/health
# 예상: {"status":"UP"}
```

---

## 📊 타임라인 (예상)

```
현재 시각: 18:35
  ↓
GitHub Actions 실행 중...
  ↓
18:40-18:45: Actions 완료 (예상)
  ↓
18:45: Dev 서버에서 pull
  ↓
18:46: Backend 재시작
  ↓
18:47: 정상 작동 ✅
```

---

## 🎯 빠른 체크리스트

Dev 서버 관리자용:

```bash
# 1. GitHub Actions 완료 확인
□ https://github.com/gitsmyun/pms/actions
□ 녹색 체크 확인

# 2. Dev 서버 접속
□ ssh user@dev-server

# 3. 최신 이미지 pull
□ cd /opt/pms/infra
□ docker compose -f docker-compose.dev.yml pull backend

# 4. 재시작
□ docker compose -f docker-compose.dev.yml up -d backend

# 5. 로그 확인
□ docker logs pms-dev-backend -f
□ "Started PmsBackendApplication" 확인

# 6. 테스트
□ curl http://localhost:8180/actuator/health
□ curl http://localhost:8180/api/projects

# 7. Frontend 확인
□ 브라우저에서 http://dev-server:8181
□ 502 오류 없는지 확인
```

---

## 🚀 한 번에 실행 (복사-붙여넣기)

```bash
#!/bin/bash
echo "=== PMS Dev Backend 업데이트 ==="

# 위치 확인
cd /opt/pms/infra || { echo "경로 오류!"; exit 1; }

echo "1. 현재 상태 확인..."
docker ps | grep pms-dev-backend

echo "2. Backend 중지..."
docker compose -f docker-compose.dev.yml stop backend

echo "3. 최신 이미지 Pull..."
docker compose -f docker-compose.dev.yml pull backend

echo "4. Backend 시작..."
docker compose -f docker-compose.dev.yml up -d backend

echo "5. 로그 확인 (10초)..."
sleep 10
docker logs pms-dev-backend --tail 30

echo "6. Health Check..."
curl -s http://localhost:8180/actuator/health | jq .

echo "=== 완료! ==="
echo "Frontend 접속: http://dev-server:8181"
```

---

## 📞 여전히 안 되면

### 로그 공유 필요

```bash
# Backend 전체 로그
docker logs pms-dev-backend > backend-full.log

# 최근 100줄
docker logs pms-dev-backend --tail 100

# 이미지 정보
docker images | grep pms-backend

# 컨테이너 상태
docker ps -a | grep pms-dev
```

이 정보를 공유해주시면 추가 진단 가능합니다!

---

## 🎯 핵심 요약

**문제**: 
- Backend가 여전히 구버전 이미지 사용 중
- 수정된 코드(SecurityDevFallbackConfig)가 반영 안됨

**해결**:
1. ✅ GitHub Actions 완료 대기
2. ✅ `docker compose pull backend`
3. ✅ `docker compose up -d backend`
4. ✅ 로그에서 "Started PmsBackendApplication" 확인

**예상 소요 시간**: 
- GitHub Actions: 5-10분 (이미 시작됨)
- Pull & 재시작: 2-3분
- **총 10-15분 이내 해결**

---

**작성**: GitHub Copilot  
**긴급도**: 🚨 P0  
**다음 액션**: Dev 서버 관리자가 위 명령 실행

