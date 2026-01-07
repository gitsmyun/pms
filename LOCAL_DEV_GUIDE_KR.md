# PMS 로컬 개발 가이드 (기업 표준 권장 흐름)

이 문서는 **로컬 개발에서 매번 3개(DB/Backend/Frontend)를 손으로 켜는 번거로움**을 줄이기 위해,
- (A) PowerShell 스크립트로 **DB + Frontend**를 원커맨드로 실행하고
- (B) IntelliJ(한글 UI)에서 **Backend + Frontend**를 복합(Compound) 실행으로 묶는
권장 표준을 제공합니다.

> 목적: **재현성(=Docker DB)** + **개발 생산성(=IntelliJ 디버깅/프론트 HMR)** + **팀 표준화**

---

## TL;DR (가장 빠른 루틴)

### 1) DB + Frontend 실행(원커맨드)

PowerShell에서(프로젝트 루트)

```powershell
powershell -ExecutionPolicy Bypass -File .\dev.ps1
```

- DB(Postgres)가 없으면 자동으로 `docker compose up -d`
- 프론트 dev server는 `pnpm dev`로 실행
- 화면: http://localhost:5173

### 2) Backend는 IntelliJ에서 실행

- Run Configuration: `PmsBackendApplication`
- Swagger: http://localhost:8080/swagger-ui.html

---

## A) PowerShell 스크립트 사용법

### 파일
- `dev.ps1`: DB up + Frontend 실행
- `dev-stop.ps1`: DB down

### dev.ps1 옵션

```powershell
# DB만 생략
powershell -ExecutionPolicy Bypass -File .\dev.ps1 -NoDb

# Frontend만 생략
powershell -ExecutionPolicy Bypass -File .\dev.ps1 -NoFrontend

# pnpm install 자동 수행 생략(이미 설치돼 있으면 보통 필요 없음)
powershell -ExecutionPolicy Bypass -File .\dev.ps1 -NoInstall
```

### dev-stop.ps1 옵션

```powershell
# 기본: down -v (볼륨까지 삭제 → DB 데이터 초기화)
powershell -ExecutionPolicy Bypass -File .\dev-stop.ps1

# 데이터 유지(down만 수행)
powershell -ExecutionPolicy Bypass -File .\dev-stop.ps1 -KeepVolumes
```

---

## B) IntelliJ (한글)에서 Backend + Frontend를 한 번에 실행하기 (복합/Compound)

### 0) 전제
- Backend Run Configuration(`PmsBackendApplication`)은 이미 존재(EnvFile 사용 포함)
- Frontend는 `frontend/package.json`의 `dev` 스크립트를 실행

### 1) Frontend Run Configuration 만들기 (npm)

1. 상단 메뉴 **`실행` → `실행/디버그 구성 편집…`**
2. 좌측 상단 **`+`(추가)** 클릭
3. 목록에서 **`npm`** 선택
   - 안 보이면 **`더 많은 항목...`** 클릭 후 검색창에 `npm`
4. 우측 설정 입력

- **이름**: `Frontend Dev Server`
- **package.json**: `C:\intelliJ\git\pms\frontend\package.json`
- **명령(Command)**: `run`
- **스크립트(Scripts)**: `dev`
- **패키지 관리자(Package manager)**: `pnpm` (중요)
- **작업 디렉터리(Working directory)**: `C:\intelliJ\git\pms\frontend`

5. 하단 **`적용` → `확인`**

실행 후 아래가 보이면 성공입니다.
- Run 창에 `Local: http://localhost:5173/`

### 2) 복합(Compound) Run Configuration 만들기

1. **`실행` → `실행/디버그 구성 편집…`**
2. 좌측 상단 **`+`(추가)** 클릭
3. **`복합(Compound)`** 선택
4. 설정

- **이름**: `PMS Local (Backend + Frontend)`
- **구성** 목록에 아래 2개 추가
  - `PmsBackendApplication`
  - `Frontend Dev Server`

5. **`적용` → `확인`**

이제 상단 실행 드롭다운에서 `PMS Local (Backend + Frontend)` 선택 후 ▶ 실행하면,
Backend(8080)와 Frontend(5173)가 동시에 켜집니다.

> DB는 보통 하루 시작 시 `dev.ps1` 또는 docker compose로 한 번만 올려두고 유지하는 방식이 가장 편합니다.

---

## 트랜잭션(INSERT/SELECT) 확인 방법

1) 브라우저: http://localhost:5173 접속
2) 프로젝트명 입력 → **프로젝트 생성** 클릭
3) 정상이라면 목록이 reload되며 생성한 프로젝트가 보입니다.

추가 확인(권장):
- 브라우저 개발자도구(Network)에서 `/api/projects` 호출(201/200) 확인
- Backend 콘솔에 SQL 로그 출력(로컬 프로필에서 `show_sql: true`)

---

## 자주 겪는 문제

### 1) pnpm이 없다고 나와요
- Node 설치 후, 아래 중 하나
  - `corepack enable` (권장)
  - 또는 `npm i -g pnpm`

### 2) 8080 API 호출이 안 돼요
- Backend가 실행 중인지 확인
- `infra/.env`의 DB 설정과 Postgres 컨테이너 포트(`DB_PORT`) 확인

### 3) DB 데이터가 사라졌어요
- `dev-stop.ps1` 기본 동작이 `down -v`라서 볼륨을 삭제합니다.
- 데이터를 유지하려면 `-KeepVolumes` 옵션을 사용하세요.

---

## IntelliJ 터미널 한글 깨짐(???)이 보일 때

간혹 IntelliJ Terminal(Windows PowerShell v5.1)에서 출력 인코딩이 CP949/ASCII로 섞이면서
스크립트의 한글 로그가 `?` 또는 깨진 문자로 보일 수 있습니다.

### 해결
- 이번 레포의 `dev.ps1`, `dev-stop.ps1`는 스크립트 시작 시 UTF-8 출력 인코딩을 설정하도록 보강했습니다.
- 그래도 일부 도구(docker/pnpm) 출력이 깨지면, IntelliJ Terminal을 **PowerShell 7(pwsh)** 로 바꾸면 가장 깔끔합니다.
  - IntelliJ: `설정(Settings)` → `도구(Tools)` → `터미널(Terminal)` → `Shell path`를 `pwsh.exe`로 변경

### 참고
- docker compose 경고(`version is obsolete`)는 compose v2에서 `version:` 필드를 더 이상 쓰지 않아 발생하며,
  `infra/docker-compose.local.yml`에서 제거했습니다.
