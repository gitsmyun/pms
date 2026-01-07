# IntelliJ Run Configuration 추가 - 한글 버전 단계별 가이드

**대상**: PMS Frontend (Vite + Vue3)  
**IntelliJ IDEA**: 한글 버전 기준

> 전체 로컬 개발 표준(기업 권장 흐름)은 프로젝트 루트의 `LOCAL_DEV_GUIDE_KR.md`를 참고하세요.

---

## 📌 Step-by-Step 가이드

### Step 1: 구성 편집 메뉴 열기

#### 방법 1 (상단 메뉴 - 가장 쉬움)
1. 상단 메뉴바에서 **실행(Run)** 클릭
2. **구성 편집...(Edit Configurations...)** 클릭

#### 방법 2 (툴바)
1. 상단 툴바 우측의 실행 구성 드롭다운 클릭
   - 현재 실행 구성 이름이 표시된 곳
2. **구성 편집...(Edit Configurations...)** 선택

#### 방법 3 (단축키)
- `Alt + Shift + F10` → `0` 입력

---

### Step 2: npm 구성 추가

1. 좌측 상단의 **+ (추가)** 버튼 클릭
2. 목록에서 **npm** 찾아서 클릭
   - 스크롤 필요할 수 있음
   - 검색창에 "npm" 입력해도 됨

**npm이 안 보이면?**
- **더 많은 항목...** 클릭
- 검색창에 "npm" 입력
- **npm** 선택

---

### Step 3: 설정 입력 (우측 패널)

#### 필수 항목

**1. 이름(Name)**
```
Frontend Dev Server
```
- 또는 원하는 이름 (예: `Vite 개발서버`, `PMS 프론트`)

**2. package.json**
- 경로 자동 인식됨: `C:\intelliJ\git\pms\frontend\package.json`
- 안 되면 폴더 아이콘 클릭하여 수동 선택

**3. 명령(Command)**
```
run
```
- 드롭다운에서 선택

**4. 스크립트(Scripts)**
```
dev
```
- 드롭다운에서 선택 (package.json의 scripts 자동 인식)

**5. 패키지 관리자(Package manager)**
```
pnpm
```
- 기본값 `npm`을 **pnpm**으로 변경
- ⚠️ 중요: 프로젝트가 pnpm 사용 중이므로 꼭 변경!

**6. 작업 디렉터리(Working directory)**
```
C:\intelliJ\git\pms\frontend
```
- 자동 설정됨 (확인만 하면 됨)

---

### Step 4: 저장

1. 하단의 **적용(Apply)** 버튼 클릭
2. **확인(OK)** 버튼 클릭

---

### Step 5: 실행 확인

**상단 툴바 확인**
- 드롭다운에 `Frontend Dev Server` 가 선택되어 있는지 확인

---

## ▶️ 실행 방법

### 방법 1: 툴바에서 실행 (가장 쉬움)
1. 상단 툴바에서 `Frontend Dev Server` 선택
2. 초록색 **▶ (재생)** 버튼 클릭

### 방법 2: 단축키
- **실행**: `Shift + F10`
- **디버그**: `Shift + F9`

### 방법 3: 메뉴
1. **실행(Run)** → **'Frontend Dev Server' 실행**

---

## ✅ 실행 확인

하단에 **Run** 도구 창이 자동으로 열리고 다음과 같이 표시됨:

```
C:\intelliJ\git\pms\frontend>pnpm dev

> frontend@0.0.0 dev
> vite

  VITE v6.x  ready in 1234 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

---

## 💡 전체 스택(Backend + Frontend) 한 번에 실행하기 (복합/Compound)

1. **실행** → **실행/디버그 구성 편집…**
2. **+ (추가)** → **복합(Compound)**
3. 이름: `PMS Local (Backend + Frontend)`
4. 실행할 구성 추가:
   - `PmsBackendApplication` (Spring Boot)
   - `Frontend Dev Server` (Vite)
5. 저장 후 실행

> DB(Postgres)는 보통 `docker compose up -d`로 하루 1번 올려두고 유지하는 방식이 편합니다.
> 더 편하게는 프로젝트 루트의 `dev.ps1`을 사용하세요.

---

## 🧪 빠른 확인(트랜잭션)

1) Backend 실행(8080)
- Swagger UI: http://localhost:8080/swagger-ui.html

2) Frontend 실행(5173)
- 화면: http://localhost:5173

3) 화면에서 프로젝트 생성 → 목록에 반영되면 API 호출 + DB 트랜잭션이 정상입니다.

---

## ❓ 문제 해결

### npm이 pnpm을 인식 못 하는 경우
1. 구성 편집에서 **패키지 관리자**를 `pnpm`으로 확실히 변경했는지 확인
2. IntelliJ 재시작

### "Cannot find package.json"
- **package.json** 경로가 `C:\intelliJ\git\pms\frontend\package.json` 인지 확인
- 폴더 아이콘으로 다시 선택

### 실행 구성이 안 보임
- 상단 툴바 드롭다운 클릭
- 목록에서 `Frontend Dev Server` 찾아서 선택
