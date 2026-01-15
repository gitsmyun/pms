# ⚡ Dev 서버 502 - 3분 해결 가이드

**현재 상황**: Backend가 시작 실패 중  
**원인**: 구버전 이미지 사용  
**해결**: 최신 이미지 Pull

---

## 1️⃣ GitHub Actions 확인 (30초)

### 브라우저에서:
```
https://github.com/gitsmyun/pms/actions
```

### 상태 확인:
- ✅ **녹색 체크 (✓)**: 완료! → 2단계로
- 🟡 **노란색 원**: 진행 중 → 5분 대기
- ❌ **빨간색 X**: 실패 → 로그 확인 필요

---

## 2️⃣ Dev 서버 업데이트 (2분)

### SSH 접속:
```bash
ssh user@dev-server
```

### 한 줄 명령어 (복사-붙여넣기):
```bash
cd /opt/pms/infra && docker compose -f docker-compose.dev.yml pull backend && docker compose -f docker-compose.dev.yml restart backend && docker logs pms-dev-backend -f
```

### 성공 확인:
```
Started PmsBackendApplication in X seconds
```

---

## 3️⃣ 테스트 (30초)

```bash
# Health Check
curl http://localhost:8180/actuator/health

# API 호출
curl http://localhost:8180/api/projects

# 브라우저
http://dev-server:8181
```

---

## ❌ 여전히 실패?

### A. GitHub Actions가 노란색 (진행 중)
→ **5-10분 대기** 후 다시 시도

### B. Pull했는데 여전히 실패
```bash
# 이미지 확인
docker images | grep pms-backend | grep develop-latest

# 생성 시간이 "3 hours ago"라면 구버전!
# 강제 재pull:
docker pull ghcr.io/gitsmyun/pms-backend:develop-latest --no-cache
docker compose -f docker-compose.dev.yml restart backend
```

### C. Backend는 정상인데 502
```bash
# Frontend 재시작
docker compose -f docker-compose.dev.yml restart frontend

# 브라우저 캐시 클리어
Ctrl + Shift + R
```

---

## 📞 도움 요청 시

```bash
# 이 정보 공유:
docker logs pms-dev-backend --tail 50
docker images | grep pms-backend
docker ps -a | grep pms-dev
```

---

**예상 해결 시간**: 10-15분  
**상세 가이드**: `DEV_SERVER_502_STILL_FAILING.md`

