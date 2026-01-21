# HTTPS 적용 최종 해결 방안

**작성일**: 2026-01-19  
**상태**: ✅ 해결 방안 확정

---

## 🎯 문제 요약

**증상**: 
- Docker 컨테이너가 계속 재시작 (Restarting)
- 오류: `cannot load certificate "/etc/nginx/certs/dev-pms.crt": No such file or directory`

**원인**:
- 호스트: `/opt/pms/dev/certs/` 파일 존재 ✅
- 컨테이너: `/etc/nginx/certs/` 파일 없음 ❌
- **docker-compose.dev.yml에 볼륨 마운트 설정 누락**

---

## ✅ 최신 기업 웹 프로젝트 권장 방향 검토

### 현재 구조 (비권장)

```
로컬 PC (Git)          WSL Ubuntu (배포)
C:\intelliJ\git\pms    /opt/pms/dev
     ↓                      ↑
   커밋/푸시            수동 복사 필요 ❌
     ↓
  GitHub
```

**문제점**:
- ❌ Git과 배포 환경 분리
- ❌ 코드 변경이 자동 반영 안됨
- ❌ 수동 동기화 필요

### 최신 기업 권장 구조

```
옵션 A: GitOps 방식
로컬 PC → GitHub → CI/CD → 배포 서버 (자동)

옵션 B: 배포 환경도 Git 클론
로컬 PC → GitHub
              ↓
         배포 서버 (git pull)
```

**장점**:
- ✅ 모든 변경사항 Git으로 관리
- ✅ 자동화된 배포 파이프라인
- ✅ 버전 관리 및 롤백 용이

---

## 🚀 즉시 해결 방법 (완료됨)

### 1단계: 파일 복사 (완료 ✅)

**PowerShell 실행 완료**:
```powershell
Copy-Item "infra\docker-compose.dev.yml" "\\wsl.localhost\Ubuntu-22.04\opt\pms\dev\compose\docker-compose.dev.yml" -Force
```

### 2단계: WSL에서 컨테이너 재시작 (필요)

**WSL Ubuntu에서 다음 명령어를 실행하세요**:

```bash
cd /opt/pms/dev

# 1. 볼륨 설정 확인
echo "=== 볼륨 설정 확인 ==="
grep -A 2 "volumes:" compose/docker-compose.dev.yml | grep -B 2 "certs"

# 2. 컨테이너 완전히 제거
echo "=== 컨테이너 제거 ==="
docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  down

# 3. 최신 이미지 Pull
echo "=== 최신 이미지 Pull ==="
docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  pull frontend

# 4. 컨테이너 재생성
echo "=== 컨테이너 재시작 ==="
docker compose -p pms_dev \
  --env-file env/.env.dev \
  -f compose/docker-compose.dev.yml \
  up -d --force-recreate frontend

# 5. 컨테이너 내부 파일 확인 (3초 대기)
sleep 3
echo "=== 컨테이너 내부 인증서 파일 확인 ==="
docker exec pms-dev-frontend ls -la /etc/nginx/certs/ 2>/dev/null || echo "컨테이너 아직 시작 중..."

# 6. 로그 확인
echo "=== 컨테이너 로그 ==="
docker logs pms-dev-frontend --tail 20

# 7. 포트 리스닝 확인
echo "=== 포트 확인 ==="
sudo ss -tlnp | grep -E '8181|8444'

# 8. 컨테이너 상태 확인
echo "=== 컨테이너 상태 ==="
docker ps | grep pms-dev-frontend
```

---

## 🎯 예상 성공 결과

### 1. 볼륨 설정 확인
```
    volumes:
      - /opt/pms/dev/certs:/etc/nginx/certs:ro
```

### 2. 컨테이너 내부 파일
```
-rw-r--r-- 1 root root 1330 Jan 19 16:29 dev-pms.crt
-rw------- 1 root root 1704 Jan 19 16:29 dev-pms.key
```

### 3. 컨테이너 로그
```
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/01/19 17:00:00 [notice] 1#1: using the "epoll" event method
2026/01/19 17:00:00 [notice] 1#1: nginx/1.27.3
2026/01/19 17:00:00 [notice] 1#1: start worker processes
```

### 4. 포트 리스닝
```
LISTEN 0  511  0.0.0.0:8181  0.0.0.0:*
LISTEN 0  511  0.0.0.0:8444  0.0.0.0:*
```

### 5. 컨테이너 상태
```
91e45f58f749  ...  Up 2 minutes  ← "Up", "Restarting" 아님!
```

---

## 🌐 브라우저 테스트

### HTTP (localhost)
```
http://localhost:8181
```

### HTTPS (WSL IP 또는 외부 접속)
```
https://localhost:8444
또는
https://10.127.6.102:8444 (다른 PC에서)
```

**인증서 경고**: "고급" → "계속 진행" 클릭 (자체 서명 인증서이므로 정상)

---

## 💡 장기적 개선 방안 (최신 기업 표준)

### 옵션 1: WSL도 Git 저장소로 관리 (권장)

**구현**:
```bash
# WSL Ubuntu에서
cd /opt/pms
rm -rf dev
git clone https://github.com/gitsmyun/pms.git dev
cd dev
git checkout develop
```

**장점**:
- ✅ Git으로 모든 변경 관리
- ✅ `git pull`로 자동 업데이트
- ✅ 버전 관리 및 롤백 용이

### 옵션 2: GitHub Actions 자동 배포 강화

**구현**:
- GitHub Actions → Docker 이미지 발행 ✅ (이미 구현됨)
- Webhook → WSL에서 자동 pull 및 재시작

### 옵션 3: 파일 동기화 스크립트

**구현**:
```powershell
# sync-to-wsl.ps1
$SOURCE = "C:\intelliJ\git\pms\infra\docker-compose.dev.yml"
$DEST = "\\wsl.localhost\Ubuntu-22.04\opt\pms\dev\compose\docker-compose.dev.yml"

Copy-Item $SOURCE $DEST -Force
Write-Host "동기화 완료!" -ForegroundColor Green
```

Git 커밋 후 자동 실행하도록 설정

---

## 📊 현재 vs 권장 구조 비교

| 항목 | 현재 | 권장 (옵션 1) |
|------|------|---------------|
| Git 관리 | 로컬만 | 로컬 + WSL |
| 배포 | 수동 복사 | git pull |
| 버전 관리 | 부분적 | 완전 |
| 롤백 | 어려움 | 쉬움 (git checkout) |
| CI/CD | GitHub Actions | GitHub Actions + 자동 배포 |
| 유지보수 | 어려움 | 쉬움 |

---

## ✅ 결론

### 즉시 해결 (완료)
1. ✅ PowerShell로 파일 복사 완료
2. ⏳ WSL에서 위 명령어 실행 필요

### 장기 개선 (권장)
1. **WSL도 Git 저장소로 변경** (옵션 1)
2. 또는 **파일 동기화 자동화** (옵션 3)

### 최신 기업 표준 준수
- ✅ GitOps 방식 (모든 인프라를 Git으로 관리)
- ✅ CI/CD 자동화
- ✅ Infrastructure as Code

---

**다음 단계**: WSL Ubuntu에서 위의 "2단계" 명령어를 실행하세요!

**성공 시**: `https://localhost:8444` 또는 `https://10.127.6.102:8444` 접속 가능!

---

**작성자**: AI Assistant  
**작성일**: 2026-01-19  
**상태**: ✅ 파일 복사 완료, WSL 재시작 대기 중
