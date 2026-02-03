# 연결 거부 오류 해결 가이드

**문제**: `https://localhost:8181`, `https://10.127.6.102:8444` 접속 시 `ERR_CONNECTION_REFUSED`

**작성일**: 2026-01-19  
**상태**: 🔴 긴급 해결 중

---

## 🚨 즉시 확인 사항

### 1. GitHub Actions 빌드 상태

**웹 브라우저에서 확인**:
```
https://github.com/gitsmyun/pms/actions
```

**확인 사항**:
- ✅ 빌드 완료 (초록색 체크)?
- ❌ 빌드 실패 (빨간색 X)?
- ⏳ 빌드 진행 중 (노란색 원)?

**예상 시간**: 푸시 후 8-10분

---

### 2. 개발 서버 컨테이너 상태 확인

**SSH로 개발 서버 접속**:
```bash
ssh smyun@10.127.6.102

# 컨테이너 실행 상태 확인
docker ps | grep pms-dev-frontend

# 포트 리스닝 확인
sudo ss -tlnp | grep -E '8181|8444'

# 컨테이너 로그 확인
docker logs pms-dev-frontend --tail 100
```

**예상 정상 출력**:
```bash
# docker ps
CONTAINER ID   IMAGE                                    STATUS
abc123def456   ghcr.io/gitsmyun/pms-frontend:develop-latest   Up 5 minutes

# ss -tlnp
LISTEN  0  511  0.0.0.0:8181  0.0.0.0:*  users:(("nginx",pid=29))
LISTEN  0  511  0.0.0.0:8444  0.0.0.0:*  users:(("nginx",pid=29))
```

---

### 3. 인증서 파일 존재 확인

```bash
ls -la /opt/pms/dev/certs/

# 예상 출력:
# -rw-r--r-- 1 smyun smyun 1285 Jan 19 15:00 dev-pms.crt
# -rw------- 1 smyun smyun 1704 Jan 19 15:00 dev-pms.key
```

---

## 🔧 가능한 원인 및 해결책

### 원인 1: 빌드가 아직 완료 안됨 ⏳

**증상**: GitHub Actions가 아직 진행 중

**해결**: 빌드 완료까지 대기 (5-10분)

---

### 원인 2: 컨테이너가 실행 안됨 ❌

**증상**: 
```bash
docker ps | grep pms-dev-frontend
# 출력 없음
```

**원인 확인**:
```bash
# 컨테이너 상태 확인 (중지/오류 포함)
docker ps -a | grep pms-dev-frontend

# 로그 확인
docker logs pms-dev-frontend
```

**해결**:
```bash
cd /opt/pms/dev

# 수동 재시작
docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  up -d frontend

# 로그 실시간 확인
docker logs pms-dev-frontend -f
```

---

### 원인 3: Nginx 설정 오류 ❌

**증상**:
```bash
docker logs pms-dev-frontend
nginx: [emerg] invalid number of arguments in "ssl_certificate" directive
```

**원인**: nginx.conf 문법 오류 또는 인증서 파일 없음

**해결**:
```bash
# 인증서 파일 확인
ls -la /opt/pms/dev/certs/

# 없으면 생성
cd /opt/pms/dev/certs && \
openssl req -x509 -nodes -days 3650 \
  -newkey rsa:2048 \
  -keyout dev-pms.key \
  -out dev-pms.crt \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=PMS-Dev/CN=10.127.6.102" \
  -addext "subjectAltName=IP:10.127.6.102,DNS:localhost" && \
chmod 644 dev-pms.crt && \
chmod 600 dev-pms.key

# 컨테이너 재시작
cd /opt/pms/dev
docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  restart frontend
```

---

### 원인 4: 포트 충돌 ❌

**증상**: 이미 다른 프로세스가 8181 또는 8444 포트 사용 중

**확인**:
```bash
sudo ss -tlnp | grep -E '8181|8444'
```

**해결**:
```bash
# 기존 프로세스 종료 또는 포트 변경
```

---

### 원인 5: 방화벽 차단 ❌

**증상**: 컨테이너는 실행 중이지만 외부 접속 안됨

**확인**:
```bash
# 방화벽 상태 확인
sudo ufw status

# 또는
sudo firewall-cmd --list-all
```

**해결**:
```bash
# ufw 사용 시
sudo ufw allow 8444/tcp

# firewalld 사용 시
sudo firewall-cmd --permanent --add-port=8444/tcp
sudo firewall-cmd --reload
```

---

## 🚀 긴급 수동 배포 절차

**GitHub Actions 완료 여부와 관계없이 즉시 실행 가능**:

### 1. SSH 접속
```bash
ssh smyun@10.127.6.102
```

### 2. 최신 이미지 Pull
```bash
cd /opt/pms/dev

docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  pull frontend
```

**예상 출력**:
```
[+] Pulling 1/1
 ✔ frontend Pulled
```

### 3. 컨테이너 재시작
```bash
docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  up -d frontend
```

**예상 출력**:
```
[+] Running 1/1
 ✔ Container pms-dev-frontend  Started
```

### 4. 로그 확인
```bash
docker logs pms-dev-frontend --tail 50
```

**정상 로그**:
```
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/01/19 16:30:00 [notice] 1#1: using the "epoll" event method
2026/01/19 16:30:00 [notice] 1#1: nginx/1.27.3
2026/01/19 16:30:00 [notice] 1#1: start worker processes
2026/01/19 16:30:00 [notice] 1#1: start worker process 29
```

**오류 로그 예시**:
```
nginx: [emerg] cannot load certificate "/etc/nginx/certs/dev-pms.crt": BIO_new_file() failed
nginx: [emerg] SSL_CTX_use_PrivateKey_file("/etc/nginx/certs/dev-pms.key") failed
```

---

## 📊 디버깅 체크리스트

### 단계별 확인

- [ ] **1. GitHub Actions 완료 확인**
  - [ ] https://github.com/gitsmyun/pms/actions 접속
  - [ ] 최신 workflow 초록색 체크?

- [ ] **2. Docker 이미지 존재 확인**
  ```bash
  docker images | grep pms-frontend
  ```

- [ ] **3. 컨테이너 실행 확인**
  ```bash
  docker ps | grep pms-dev-frontend
  ```

- [ ] **4. 포트 리스닝 확인**
  ```bash
  sudo ss -tlnp | grep -E '8181|8444'
  ```

- [ ] **5. 인증서 파일 확인**
  ```bash
  ls -la /opt/pms/dev/certs/
  ```

- [ ] **6. 컨테이너 로그 확인**
  ```bash
  docker logs pms-dev-frontend --tail 100
  ```

- [ ] **7. Nginx 설정 테스트**
  ```bash
  docker exec pms-dev-frontend nginx -t
  ```

---

## 🌐 localhost 접속 불가 원인

### https://localhost:8181 접속 시 ERR_CONNECTION_REFUSED

**원인**: localhost에서는 HTTPS가 아닌 **HTTP만 지원**됩니다!

**올바른 접속 URL**:
```
✅ http://localhost:8181     (HTTP, 포트 8181)
❌ https://localhost:8181    (HTTPS 지원 안함)

✅ https://10.127.6.102:8444 (HTTPS, 포트 8444)
❌ https://10.127.6.102:8181 (HTTPS 지원 안함)
```

**nginx.conf 설정**:
```nginx
# HTTP 서버 (localhost 전용)
server {
  listen 80;
  server_name localhost 127.0.0.1;
}

# HTTPS 서버 (IP 전용)
server {
  listen 443 ssl;
  server_name 10.127.6.102;
}
```

**docker-compose 포트 매핑**:
```yaml
ports:
  - "8181:80"    # HTTP → localhost:8181
  - "8444:443"   # HTTPS → 10.127.6.102:8444
```

---

## ✅ 올바른 접속 방법

### 로컬 PC에서 개발

**HTTP 접속** (localhost):
```
http://localhost:8181
```

### 다른 PC에서 통합 테스트

**HTTPS 접속** (개발 서버 IP):
```
https://10.127.6.102:8444
```

---

## 🎯 즉시 실행할 명령어 (개발 서버)

**한번에 복사해서 실행**:

```bash
# 1. SSH 접속
ssh smyun@10.127.6.102

# 2. 컨테이너 상태 확인
docker ps | grep pms-dev-frontend && \
sudo ss -tlnp | grep -E '8181|8444' && \
ls -la /opt/pms/dev/certs/

# 3. 문제 발견 시 재배포
cd /opt/pms/dev && \
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml pull frontend && \
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d frontend && \
docker logs pms-dev-frontend --tail 50
```

---

## 📝 결과 보고 요청

위 명령어 실행 후 다음 정보를 알려주세요:

1. **GitHub Actions 상태**: 완료? 진행중? 실패?
2. **docker ps 출력**: 컨테이너 실행 중?
3. **ss -tlnp 출력**: 포트 8181, 8444 리스닝?
4. **docker logs 출력**: 오류 메시지?

---

**작성자**: AI Assistant  
**작성일**: 2026-01-19  
**상태**: 🔴 긴급 해결 중
