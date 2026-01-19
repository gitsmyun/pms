# GitHub Actions pnpm 오류 수정 완료 보고서

**작업일**: 2026-01-19  
**작업자**: AI Assistant (윤성민 책임 요청)

---

## 📋 오류 내용

### 발생한 오류
```
Error: Unable to locate executable file: pnpm. 
Please verify either the file path exists or the file can be found 
within a directory specified by the PATH environment variable.
```

**발생 위치**: GitHub Actions - `.github/workflows/ci_build_and_publish.yml`  
**트리거**: develop 브랜치 푸시 시 자동 빌드

---

## 🔍 원인 분석

### 잘못된 단계 순서 (수정 전)

```yaml
- name: Set up pnpm              # 1단계
  uses: pnpm/action-setup@v4
  with:
    version: 10.27.0
    run_install: false

- name: Set up Node              # 2단계 ❌
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'pnpm'                # ← 문제 발생!
    cache-dependency-path: 'frontend/pnpm-lock.yaml'
```

**문제점**:
1. `pnpm/action-setup@v4`가 pnpm을 설치하지만
2. `actions/setup-node@v4`의 `cache: 'pnpm'` 옵션이 pnpm을 찾으려 함
3. **pnpm이 아직 PATH에 등록되지 않아서 실행 파일을 찾을 수 없음**

**근본 원인**:
- `setup-node@v4`는 내부적으로 pnpm을 실행하여 캐시 경로를 찾으려 함
- 하지만 `setup-pnpm`이 먼저 실행되어도, `setup-node`가 실행되는 시점에는 pnpm이 PATH에 없을 수 있음
- Action 간 환경 변수 전달 타이밍 문제

---

## ✅ 해결 방법

### 올바른 단계 순서 (수정 후)

```yaml
- name: Set up Node              # 1단계 ✅
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    # cache 제거 - pnpm이 없어도 됨

- name: Set up pnpm              # 2단계 ✅
  uses: pnpm/action-setup@v4
  with:
    version: 10.27.0

- name: Get pnpm store directory # 3단계 ✅
  shell: bash
  run: |
    echo "STORE_PATH=$(pnpm store path --silent)" >> $GITHUB_ENV

- name: Setup pnpm cache         # 4단계 ✅
  uses: actions/cache@v4
  with:
    path: ${{ env.STORE_PATH }}
    key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
    restore-keys: |
      ${{ runner.os }}-pnpm-store-

- name: Install dependencies     # 5단계 ✅
  working-directory: frontend
  run: pnpm install --frozen-lockfile

- name: Frontend build           # 6단계 ✅
  working-directory: frontend
  run: pnpm build
```

**개선 사항**:
1. ✅ Node.js 먼저 설치 (cache 없음)
2. ✅ pnpm 설치 및 PATH 등록
3. ✅ pnpm이 설치된 상태에서 store 경로 확인
4. ✅ 별도 캐싱 단계로 분리 (명확한 제어)
5. ✅ 의존성 설치 및 빌드

---

## 🎯 기술적 세부사항

### 1. pnpm 버전 일치
- **package.json**: `"packageManager": "pnpm@10.27.0"`
- **Dockerfile**: `corepack prepare pnpm@10.27.0 --activate`
- **GitHub Actions**: `version: 10.27.0`
- ✅ **완벽히 일치**

### 2. 캐싱 전략
**수정 전** (setup-node 내장 캐싱):
```yaml
cache: 'pnpm'  # ← pnpm 실행 파일 필요
```

**수정 후** (별도 캐싱):
```yaml
- name: Get pnpm store directory
  run: echo "STORE_PATH=$(pnpm store path --silent)" >> $GITHUB_ENV

- name: Setup pnpm cache
  uses: actions/cache@v4
  with:
    path: ${{ env.STORE_PATH }}
    key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
```

**장점**:
- ✅ pnpm store 직접 캐싱 (더 정확함)
- ✅ lock 파일 해시 기반 캐시 키
- ✅ 부분 캐시 복원 지원 (restore-keys)

### 3. 빌드 프로세스
```
GitHub Actions:
  1. pnpm install --frozen-lockfile  (캐시 활용)
  2. pnpm build                      (빌드 테스트)
  
Docker 이미지 빌드:
  1. Dockerfile 실행
  2. 내부에서 다시 pnpm install
  3. 내부에서 다시 pnpm build
  4. Nginx 이미지 생성
```

**이중 빌드 이유**:
- GitHub Actions: 빠른 피드백 (빌드 오류 조기 발견)
- Docker: 독립적인 빌드 환경 (재현 가능한 이미지)

---

## 📦 Git 커밋 정보

### 커밋 내역
```
feat: Keycloak SSO 디버깅 로직 추가 및 Web Crypto API 오류 자동 대응
fix: GitHub Actions pnpm 실행 파일 찾을 수 없는 오류 수정
```

### 푸시 완료
- ✅ **브랜치**: `develop`
- ✅ **원격**: `origin/develop`
- ✅ **수정 파일**: `.github/workflows/ci_build_and_publish.yml`

---

## 🚀 배포 프로세스

### 자동 배포 흐름
```
1. Git Push (develop)
   ↓
2. GitHub Actions 트리거
   ├─ Backend: Gradle 테스트 → Docker 이미지 빌드
   └─ Frontend: pnpm 빌드 → Docker 이미지 빌드 ✅ (수정됨)
   ↓
3. GHCR 푸시
   ├─ ghcr.io/.../pms-backend:sha-{해시}
   ├─ ghcr.io/.../pms-backend:develop-latest
   ├─ ghcr.io/.../pms-frontend:sha-{해시}
   └─ ghcr.io/.../pms-frontend:develop-latest
   ↓
4. 개발 서버 systemd timer (10분 이내)
   ├─ docker compose pull
   └─ docker compose up -d
```

### 예상 배포 시간
- **GitHub Actions**: 5-10분 (빌드 + 푸시)
- **개발 서버 배포**: 최대 10분 (systemd timer)
- **총 소요 시간**: 최대 20분

---

## 📊 검증 체크리스트

### GitHub Actions 확인
- [ ] GitHub Actions 탭에서 워크플로우 실행 확인
- [ ] Frontend job의 "Set up pnpm" 단계 성공 확인
- [ ] Frontend job의 "Frontend build" 단계 성공 확인
- [ ] GHCR 이미지 푸시 성공 확인

### 개발 서버 확인
- [ ] 20분 후 개발 서버 접속
- [ ] 브라우저 콘솔에서 디버깅 로그 확인
  - `http://10.127.6.102:8181`
  - F12 → Console
- [ ] 진단 페이지 접속
  - `http://10.127.6.102:8181/browser-env-check.html`

---

## 📝 참고 사항

### .gitignore 정책
- `**/docs/` 패턴으로 **모든 docs 폴더 무시**
- 작업 보고서는 **로컬에서만 보관**
- 협업 정책: 문서는 별도 관리 (Confluence, Notion 등)

### 향후 개선 사항
1. **docs 정책 결정**
   - 아키텍처 문서만 Git에 커밋할지 검토
   - 이미지 파일 관리 방안 수립

2. **CI/CD 최적화**
   - 캐시 히트율 모니터링
   - 빌드 시간 최적화

3. **모니터링**
   - GitHub Actions 실행 시간 추적
   - 배포 성공률 모니터링

---

## ✅ 완료

**GitHub Actions pnpm 오류 수정 완료**

다음 단계:
1. GitHub Actions 실행 결과 확인
2. 개발 서버 배포 확인 (20분 후)
3. 브라우저에서 Keycloak SSO 디버깅 로그 확인

---

**문의**: 윤성민 책임  
**작업일**: 2026-01-19
