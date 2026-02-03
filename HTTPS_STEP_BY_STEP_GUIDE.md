# HTTPS 적용 - 순차적 작업 가이드

**작성일**: 2026-01-19  
**목적**: Docker 컨테이너 안전하게 내리고 수정 후 재시작

---

## 📋 순차적 작업 절차

### 1단계: Docker 컨테이너 내리기

**WSL Ubuntu에서 실행**:

```bash
cd /opt/pms/dev

# 모든 컨테이너 안전하게 중지
docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  down

# 확인 (아무것도 안 나와야 정상)
docker ps | grep pms-dev
```

**예상 출력**:
```
[+] Running 4/4
 ✔ Container pms-dev-frontend  Removed
 ✔ Container pms-dev-backend   Removed
 ✔ Container pms-dev-postgres  Removed
 ✔ Network pms_dev_default     Removed
```

---

### 2단계: docker-compose.dev.yml 파일 수정

**파일 열기**:

```bash
nano /opt/pms/dev/compose/docker-compose.dev.yml
```

**수정할 내용**:

1. `frontend:` 섹션을 찾습니다 (대략 75번째 줄 근처)

2. 현재 상태 (예상):
```yaml
  frontend:
    image: ${FRONTEND_IMAGE:-ghcr.io/${REPO_OWNER:-gitsmyun}/pms-frontend}:${FRONTEND_TAG:-develop-latest}
    container_name: pms-dev-frontend
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - "${FRONTEND_PORT_DEV:-8181}:80"
```

3. **다음 두 줄을 추가**:
```yaml
  frontend:
    image: ${FRONTEND_IMAGE:-ghcr.io/${REPO_OWNER:-gitsmyun}/pms-frontend}:${FRONTEND_TAG:-develop-latest}
    container_name: pms-dev-frontend
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - "${FRONTEND_PORT_DEV:-8181}:80"      # HTTP (localhost 개발용)
      - "${FRONTEND_HTTPS_PORT_DEV:-8444}:443"  # HTTPS (IP 접속용)
    volumes:
      - /opt/pms/dev/certs:/etc/nginx/certs:ro  # SSL 인증서 마운트 ← 이 두 줄 추가!
```

**주의사항**:
- **들여쓰기(인덴트)가 정확해야 합니다!**
- `volumes:`는 `ports:`, `depends_on:`과 같은 레벨
- `-` 앞에 공백 2개
- 공백은 스페이스만 사용 (탭 사용 금지)

**저장 방법**:
1. `Ctrl + O` (저장)
2. `Enter` (파일명 확인)
3. `Ctrl + X` (종료)

---

### 3단계: 수정 내용 확인

**수정이 제대로 되었는지 확인**:

```bash
cd /opt/pms/dev

# frontend 섹션 전체 출력
grep -A 12 "frontend:" compose/docker-compose.dev.yml
```

**예상 출력** (volumes가 보여야 함):
```yaml
  frontend:
    image: ${FRONTEND_IMAGE:-ghcr.io/${REPO_OWNER:-gitsmyun}/pms-frontend}:${FRONTEND_TAG:-develop-latest}
    container_name: pms-dev-frontend
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - "${FRONTEND_PORT_DEV:-8181}:80"
      - "${FRONTEND_HTTPS_PORT_DEV:-8444}:443"
    volumes:
      - /opt/pms/dev/certs:/etc/nginx/certs:ro
```

**확인 포인트**:
- ✅ `volumes:` 줄이 보임
- ✅ `/opt/pms/dev/certs:/etc/nginx/certs:ro` 줄이 보임

---

### 4단계: 인증서 파일 확인 (재확인)

```bash
ls -la /opt/pms/dev/certs/
```

**예상 출력**:
```
-rw-r--r-- 1 smyun smyun 1330 Jan 19 16:29 dev-pms.crt
-rw------- 1 smyun smyun 1704 Jan 19 16:29 dev-pms.key
```

**만약 파일이 없다면**:
```bash
cd /opt/pms/dev/certs && \
openssl req -x509 -nodes -days 3650 \
  -newkey rsa:2048 \
  -keyout dev-pms.key \
  -out dev-pms.crt \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=PMS-Dev/CN=10.127.6.102" \
  -addext "subjectAltName=IP:10.127.6.102,DNS:localhost" && \
chmod 644 dev-pms.crt && \
chmod 600 dev-pms.key && \
ls -la
```

---

### 5단계: Docker 컨테이너 다시 올리기

**최신 이미지 Pull 후 재시작**:

```bash
cd /opt/pms/dev

# 최신 이미지 Pull
docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  pull

# 컨테이너 시작
docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  up -d

# 3초 대기
sleep 3
```

**예상 출력**:
```
[+] Pulling 3/3
 ✔ frontend Pulled
 ✔ backend Pulled  
 ✔ postgres Pulled

[+] Running 3/3
 ✔ Container pms-dev-postgres  Started
 ✔ Container pms-dev-backend   Started
 ✔ Container pms-dev-frontend  Started
```

---

### 6단계: 최종 검증

**순서대로 실행하며 확인**:

```bash
# 1. 컨테이너 상태 확인
echo "=== 1. 컨테이너 상태 ==="
docker ps | grep pms-dev-frontend

# 2. 컨테이너 내부 인증서 파일 확인
echo "=== 2. 컨테이너 내부 인증서 ==="
docker exec pms-dev-frontend ls -la /etc/nginx/certs/

# 3. Nginx 설정 테스트
echo "=== 3. Nginx 설정 테스트 ==="
docker exec pms-dev-frontend nginx -t

# 4. 컨테이너 로그
echo "=== 4. 컨테이너 로그 ==="
docker logs pms-dev-frontend --tail 20

# 5. 포트 리스닝
echo "=== 5. 포트 리스닝 ==="
sudo ss -tlnp | grep -E '8181|8444'
```

---

### 7단계: 성공 확인

#### ✅ 성공 기준

**1. 컨테이너 상태**:
```
91e45f58f749  ...  Up 1 minute  ← "Up"이 보이면 성공!
```

**2. 컨테이너 내부 인증서**:
```
-rw-r--r-- 1 root root 1330 Jan 19 16:29 dev-pms.crt
-rw------- 1 root root 1704 Jan 19 16:29 dev-pms.key
```

**3. Nginx 설정 테스트**:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**4. 컨테이너 로그**:
```
nginx/1.27.3
start worker processes
```

**5. 포트 리스닝**:
```
LISTEN 0 511 0.0.0.0:8181
LISTEN 0 511 0.0.0.0:8444
```

---

### 8단계: 브라우저 테스트

#### HTTP 테스트 (먼저)

```
http://localhost:8181
```

**예상**: 정상 접속, Keycloak 로그인 페이지

#### HTTPS 테스트 (최종 목표!)

```
https://localhost:8444
```

**예상**: 
1. 인증서 경고 표시
2. "고급" → "계속 진행" 클릭
3. Keycloak 로그인 페이지 표시
4. 로그인 성공 → 대시보드 표시

**F12 → Console 확인**:
```
🔐 [환경 감지]
  - Protocol: https:
  - Is HTTPS: true
  - Can Use PKCE: true

✅ Standard Flow + PKCE S256 활성화

🔧 [Keycloak Init] 초기화 옵션:
{
  flow: 'standard',
  pkceMethod: 'S256'
}

✅ [Keycloak Init] 초기화 완료
```

---

## 🚨 문제 발생 시 해결

### 문제 1: nano 편집기가 어렵다

**대안**: vi 사용

```bash
vi /opt/pms/dev/compose/docker-compose.dev.yml
```

**vi 사용법**:
1. `i` 키 → 입력 모드
2. 내용 수정
3. `ESC` 키 → 명령 모드
4. `:wq` 입력 → 저장 및 종료

---

### 문제 2: 컨테이너가 계속 재시작 (Restarting)

**원인**: 인증서 파일이 마운트 안됨

**확인**:
```bash
docker exec pms-dev-frontend ls -la /etc/nginx/certs/
```

**파일이 없으면**:
- 3단계로 돌아가서 volumes 설정 재확인
- 들여쓰기가 정확한지 확인

---

### 문제 3: 포트가 리스닝 안됨

**원인**: Nginx 시작 실패

**확인**:
```bash
docker logs pms-dev-frontend
```

**오류 확인 후 조치**

---

## 📝 빠른 실행 스크립트

**전체 과정을 한번에 실행** (파일 수정은 수동):

```bash
cd /opt/pms/dev

# 1. 컨테이너 중지
echo "1. 컨테이너 중지..."
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml down

# 2. 파일 수정 안내
echo ""
echo "2. 다음 명령어로 파일을 수정하세요:"
echo "   nano compose/docker-compose.dev.yml"
echo ""
echo "   frontend 섹션에 다음 두 줄 추가:"
echo "   volumes:"
echo "     - /opt/pms/dev/certs:/etc/nginx/certs:ro"
echo ""
read -p "파일 수정을 완료했으면 Enter를 누르세요..."

# 3. 수정 확인
echo ""
echo "3. 수정 내용 확인:"
grep -A 12 "frontend:" compose/docker-compose.dev.yml
echo ""
read -p "volumes 설정이 보이면 Enter를 누르세요..."

# 4. 컨테이너 재시작
echo ""
echo "4. 컨테이너 재시작..."
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d
sleep 3

# 5. 검증
echo ""
echo "5. 검증..."
echo "=== 컨테이너 내부 인증서 ==="
docker exec pms-dev-frontend ls -la /etc/nginx/certs/
echo ""
echo "=== 로그 ==="
docker logs pms-dev-frontend --tail 10
echo ""
echo "=== 포트 ==="
sudo ss -tlnp | grep -E '8181|8444'
```

---

## ✅ 완료 체크리스트

작업 완료 후 체크:

- [ ] 1단계: Docker 컨테이너 중지 완료
- [ ] 2단계: docker-compose.dev.yml 파일 수정 완료
- [ ] 3단계: volumes 설정 확인 완료
- [ ] 4단계: 인증서 파일 존재 확인
- [ ] 5단계: Docker 컨테이너 재시작 완료
- [ ] 6단계: 컨테이너 내부 인증서 파일 확인됨
- [ ] 7단계: Nginx 정상 시작 확인
- [ ] 8단계: 포트 8181, 8444 리스닝 확인
- [ ] 9단계: http://localhost:8181 정상 접속
- [ ] 10단계: https://localhost:8444 정상 접속 ✅

---

**작성자**: AI Assistant  
**작성일**: 2026-01-19  
**상태**: ✅ 순차적 작업 가이드 완성
