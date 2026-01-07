# IntelliJ에서 Vite 프론트엔드 실행 가이드

**작성일**: 2026-01-05  
**대상**: PMS 프론트엔드 (Vue3 + Vite + TypeScript)

---

## 1. IntelliJ에서 실행하는 방법 (3가지)

### 방법 1: 터미널에서 실행 (가장 간단, 권장)

#### 1-1. IntelliJ 하단 터미널 열기
- `Alt + F12` (단축키)
- 또는 하단의 **Terminal** 탭 클릭

#### 1-2. frontend 폴더로 이동
```bash
cd frontend
```

#### 1-3. 개발 서버 실행
```bash
pnpm dev
```

#### 1-4. 실행 결과 확인
```
VITE v6.4.1  ready in 1234 ms

➜  Local:   http://localhost:5173/
➜  Network: use --host to expose
```

#### 1-5. 브라우저에서 확인
- IntelliJ 터미널에서 `http://localhost:5173/` 링크를 **Ctrl + 클릭**
- 또는 브라우저에서 직접 `http://localhost:5173` 입력

---

### 방법 2: IntelliJ Run Configuration 생성 (추천)

#### 2-1. Run Configuration 추가 (한글 버전 상세 가이드)

##### Step 1: 실행 구성 편집 메뉴 열기
**방법 A (메뉴 사용)**
1. 상단 메뉴: **실행(Run)** → **구성 편집(Edit Configurations...)** 클릭
   - 또는 **실행** → **구성 편집...**

**방법 B (툴바 사용)**
1. 상단 툴바 우측의 실행 구성 드롭다운 클릭 (현재 구성 이름 표시된 곳)
2. **구성 편집...(Edit Configurations...)** 선택

**방법 C (단축키)**
- `Alt + Shift + F10` → `0` (구성 편집)

##### Step 2: 새 구성 추가
1. 좌측 상단의 **+ (추가)** 버튼 클릭
2. 스크롤하여 **npm** 찾아서 선택
   - 만약 npm이 보이지 않으면:
     - **더 많은 항목...** 클릭
     - 검색창에 "npm" 입력
     - **npm** 선택

##### Step 3: 구성 상세 설정
구성 편집 창 우측 패널에서 다음 항목들을 입력:

**[기본 설정]**
- **이름(Name)**: `Frontend Dev Server`
  - 또는 원하는 이름 (예: `Vite 개발서버`, `PMS 프론트`)

**[Node.js 및 NPM]**
- **package.json**: 
  - 경로 확인: `C:\intelliJ\git\pms\frontend\package.json`
  - 또는 폴더 아이콘 클릭하여 선택

- **명령(Command)**: `run` 
  - 드롭다운에서 선택 가능

- **스크립트(Scripts)**: `dev`
  - 드롭다운에서 package.json의 scripts 확인 가능
  - 자동으로 `"dev": "vite"` 인식됨

**[선택 사항]**
- **패키지 관리자(Package manager)**: `pnpm`
  - 기본값은 `npm`이지만, 프로젝트가 pnpm 사용 중이므로 변경
  - 드롭다운에서 선택: npm / yarn / pnpm 중 **pnpm** 선택

- **환경 변수(Environment variables)**: 
  - 필요 시 추가 (기본값: 비워둠)

- **Node 옵션(Node options)**:
  - 특별한 경우가 아니면 비워둠

##### Step 4: 작업 디렉터리 확인
- **작업 디렉터리(Working directory)**:
  - 자동으로 설정됨: `C:\intelliJ\git\pms\frontend`
  - package.json 위치 기준으로 자동 설정
  - 수동 변경 필요 시 폴더 아이콘 클릭

##### Step 5: 저장
1. 하단의 **적용(Apply)** 버튼 클릭
2. **확인(OK)** 버튼 클릭하여 창 닫기

##### Step 6: 실행 구성 확인
- 상단 툴바에서 방금 생성한 `Frontend Dev Server` 가 선택되어 있는지 확인

#### 2-2. 실행 방법

##### 방법 A: 툴바에서 실행
1. 상단 툴바에서 **Frontend Dev Server** 선택 (드롭다운)
2. 초록색 **▶ (재생)** 버튼 클릭
   - 또는 벌레 모양 아이콘 클릭 (디버그 모드)

##### 방법 B: 단축키 사용
- **실행**: `Shift + F10`
- **디버그 모드**: `Shift + F9`

##### 방법 C: 메뉴에서 실행
1. **실행(Run)** → **'Frontend Dev Server' 실행(Run 'Frontend Dev Server')**
2. 또는 **실행** → **'Frontend Dev Server' 디버그(Debug 'Frontend Dev Server')**

#### 2-3. 실행 결과 확인

##### Run 도구 창 (하단)
실행하면 IntelliJ 하단에 **Run** 도구 창이 자동으로 열림:

```
C:\intelliJ\git\pms\frontend>pnpm dev

> frontend@0.0.0 dev
> vite

  VITE v6.4.1  ready in 1234 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
```

##### 콘솔 기능
- **링크 클릭**: `http://localhost:5173/` 클릭하면 브라우저 자동 열림
- **로그 확인**: 실시간 Vite 로그 확인
- **검색**: `Ctrl + F` (로그 내 검색)

#### 2-4. 제어 버튼 (Run 도구 창 좌측)

- **⬛ 중지**: 서버 종료 (단축키: `Ctrl + F2`)
- **🔄 재실행**: 서버 재시작
- **⏸ 일시정지**: 콘솔 출력 일시정지
- **📋 복사**: 로그 복사
- **🗑️ 지우기**: 콘솔 내용 지우기

#### 2-5. 장점
- ✅ **통합 관리**: IntelliJ에서 모든 로그 확인
- ✅ **쉬운 제어**: 버튼 클릭으로 시작/중지/재시작
- ✅ **디버깅**: 디버그 모드 전환 가능
- ✅ **자동 재실행**: 코드 변경 후 재시작 설정 가능
- ✅ **히스토리**: 실행 기록 자동 저장

#### 2-6. 추가 팁

##### 여러 구성 동시 실행
1. **실행** → **구성 편집...**
2. 좌측 상단 **+** → **복합(Compound)** 선택
3. 이름: `Full Stack (DB + Backend + Frontend)`
4. 우측에서 실행할 구성들 추가:
   - Backend (PmsBackendApplication)
   - Frontend Dev Server
5. 저장 후 실행하면 백엔드와 프론트엔드 동시 실행

##### 실행 전 작업 추가
1. 구성 편집 창에서 `Frontend Dev Server` 선택
2. 하단 **실행 전(Before launch)** 섹션
3. **+** 클릭 → 원하는 작업 추가 가능
   - 예: Gradle 빌드, npm install 등

---

### 방법 3: package.json 스크립트 직접 실행

#### 3-1. package.json 열기
`frontend/package.json` 파일 열기

#### 3-2. scripts 섹션에서 실행
```json
"scripts": {
  "dev": "vite",        // ← 이 줄 옆의 ▶ 아이콘 클릭
  "build": "vue-tsc -b && vite build",
  "preview": "vite preview"
}
```

---

## 2. 브라우저에서 시각적 확인

### 2-1. 개발 서버 실행 후
브라우저에서 `http://localhost:5173` 접속

### 2-2. 확인 항목
- ✅ "프로젝트 관리" 제목 표시
- ✅ "새 프로젝트 생성" 폼 표시
- ✅ "프로젝트 목록" 섹션 표시
- ✅ Tailwind CSS 스타일 적용 (흰색 카드, 그림자 등)

---

## 3. Backend와 함께 실행 (전체 시스템)

### 3-1. 실행 순서

#### Step 1: DB 실행
```bash
cd infra
docker compose -f docker-compose.local.yml up -d
```

#### Step 2: Backend 실행 (IntelliJ)
1. `backend/pms-backend/src/main/java/com/company/pms/PmsBackendApplication.java` 열기
2. `main` 메서드 옆 ▶ 클릭
3. 또는 **Run Configuration**에서 `local` 프로필로 실행

확인: `http://localhost:8080/swagger-ui.html`

#### Step 3: Frontend 실행
```bash
cd frontend
pnpm dev
```

확인: `http://localhost:5173`

### 3-2. API 연동 테스트 시나리오

#### 시나리오 1: 프로젝트 목록 조회
1. `http://localhost:5173` 접속
2. "프로젝트 목록" 섹션 확인
3. 데이터가 있으면 목록 표시, 없으면 "프로젝트가 없습니다" 표시

#### 시나리오 2: 프로젝트 생성 (성공)
1. "프로젝트명" 입력: `테스트 프로젝트`
2. "설명" 입력: `프론트엔드 연동 테스트`
3. "프로젝트 생성" 버튼 클릭
4. 성공 시: 폼이 초기화되고 목록에 새 프로젝트 표시

#### 시나리오 3: Validation 실패 (400 에러)
1. "프로젝트명" 비워두고 "프로젝트 생성" 클릭
2. 빨간색 에러 박스 표시:
   ```
   요청 검증 실패
   요청이 올바르지 않습니다.
   코드: PMS-REQ-400-001
   • name: 프로젝트명은 필수입니다.
   ```

#### 시나리오 4: 도메인 검증 실패 (400 에러)
1. "프로젝트명"에 공백만 입력: `   `
2. "프로젝트 생성" 클릭
3. 에러 표시:
   ```
   프로젝트명 필수
   요청이 올바르지 않습니다.
   코드: PMS-PRJ-400-001
   [디버그] 프로젝트명은 필수입니다.
   ```

---

## 4. Hot Module Replacement (HMR) 확인

### 4-1. 파일 수정 후 자동 반영
1. Vite 개발 서버 실행 상태에서
2. `frontend/src/views/ProjectsView.vue` 파일 열기
3. 제목 수정:
   ```vue
   <h1 class="text-3xl font-bold text-gray-900 mb-8">프로젝트 관리</h1>
   ```
   →
   ```vue
   <h1 class="text-3xl font-bold text-gray-900 mb-8">PMS 프로젝트 관리 시스템</h1>
   ```
4. 저장 (`Ctrl + S`)
5. 브라우저에서 **자동 새로고침** 없이 변경사항 즉시 반영

---

## 5. IntelliJ 브라우저 연동

### 5-1. Built-in Browser 사용
1. IntelliJ 우측 상단 브라우저 아이콘 클릭
2. `http://localhost:5173` 입력
3. IntelliJ 내부 브라우저에서 확인 가능

### 5-2. 외부 브라우저 자동 열기
IntelliJ 설정:
1. **File** → **Settings** (Ctrl + Alt + S)
2. **Tools** → **Web Browsers**
3. 원하는 브라우저 선택 및 활성화

---

## 6. 개발 팁

### 6-1. Vue DevTools 설치 (권장)
- Chrome: [Vue.js devtools](https://chrome.google.com/webstore)
- 설치 후 F12 → Vue 탭에서 컴포넌트 구조/상태 확인

### 6-2. Network 탭 확인
1. F12 → Network 탭
2. `/api/projects` 호출 확인
3. Status: 200 (성공), 400 (실패), 404 (없음)
4. Response 탭에서 Problem Details 구조 확인

### 6-3. Console 확인
- F12 → Console 탭
- API 오류 시 `console.error()` 로그 확인

---

## 7. 자주 발생하는 문제

### 문제 1: "Cannot GET /"
**원인**: 개발 서버가 실행되지 않음  
**해결**: `pnpm dev` 실행 확인

### 문제 2: CORS 에러
**원인**: Vite Proxy 설정 누락  
**해결**: `vite.config.ts`에 proxy 설정 확인

### 문제 3: 포트 이미 사용 중
**원인**: 5173 포트가 다른 프로세스에서 사용 중  
**해결**:
```bash
# 포트 확인
netstat -ano | findstr :5173

# 프로세스 종료
taskkill /PID [프로세스ID] /F
```

### 문제 4: Hot Reload가 작동하지 않음
**원인**: 파일 watcher 제한  
**해결**: IntelliJ 재시작 또는 Vite 서버 재시작

---

## 8. 중지 방법

### 터미널 실행 시
- `Ctrl + C` (터미널에서)

### Run Configuration 실행 시
- 빨간 중지 버튼 클릭
- 단축키: `Ctrl + F2`

---

## 요약: 가장 빠른 실행 방법

```bash
# 1. IntelliJ 터미널 열기 (Alt + F12)
cd frontend

# 2. 개발 서버 실행
pnpm dev

# 3. 브라우저에서 Ctrl + 클릭
http://localhost:5173
```

**완료!** 🎉

