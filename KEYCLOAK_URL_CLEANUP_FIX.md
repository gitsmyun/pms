# Keycloak OAuth URL 파라미터 정리 문제 분석 및 해결

**작업일**: 2026-01-19  
**작업자**: AI Assistant (윤성민 책임 요청)  
**문제**: Keycloak 로그인 후 OAuth 파라미터가 URL에 남아있는 문제

---

## 🔍 문제 상황

### 사용자 보고 내용

**현상**:
1. Keycloak 로그인 페이지로 리다이렉트 시 → URL에 파라미터 표시
2. 로그인 완료 후 돌아왔을 때 → **URL 파라미터가 여전히 남아있음**
3. 대시보드나 다른 메뉴 클릭 시 → URL이 정리됨

**예시 URL**:
```
http://10.127.6.102:8181/?state=xxx&session_state=yyy&code=zzz
```

**기대 동작**:
```
http://10.127.6.102:8181/
```

---

## 🚨 근본 원인

### 1. URL 정리 시점 문제

**현재 코드 흐름** (수정 전):
```typescript
keycloak.init(options).then((authenticated) => {
  // 1. 인증 성공
  console.log('✅ 인증 완료')
  
  // 2. URL 파라미터 분석
  console.log('🔍 URL 분석...')
  
  // 3. URL 정리 시도
  window.history.replaceState({}, document.title, cleanUrl)  // ← 너무 이른 시점!
  console.log('✅ URL 정리 완료')
  
  // 4. Vue 앱 생성 및 마운트
  const app = createApp(App)
  app.use(router)   // ← Router 초기화
  app.mount('#app') // ← DOM 마운트
})
```

**문제점**:
- `window.history.replaceState()`로 URL을 정리
- **하지만** Vue Router는 아직 초기화되지 않음
- Vue Router가 초기화되면서 **원래 URL을 다시 읽어옴**

### 2. Vue Router의 동작 방식

**Vue Router 초기화 과정**:
```typescript
// router/index.ts
const router = createRouter({
  history: createWebHistory(),  // ← window.location 읽음
  routes
})

// main.ts
app.use(router)   // ← 1. Router 등록
app.mount('#app') // ← 2. 컴포넌트 마운트
                  // ← 3. Router가 현재 경로 설정
                  // ← 4. window.location 기반으로 라우트 결정
```

**문제**:
1. `replaceState()`로 URL 정리 → `http://10.127.6.102:8181/`
2. Vue Router 초기화 → `window.location` 읽음
3. **하지만** 브라우저는 여전히 파라미터를 기억
4. Router가 초기 라우트 설정 시 **원래 URL 복원**

### 3. 브라우저 History API의 특성

**History API 타이밍**:
```javascript
// 1. Keycloak 리다이렉트 (브라우저 기록)
// http://10.127.6.102:8181/?state=...&code=...

// 2. replaceState (JavaScript)
window.history.replaceState({}, '', '/') // ← 브라우저 기록 수정

// 3. Vue Router 초기화 (JavaScript)
// Router가 window.location을 읽을 때
// 브라우저는 여전히 원래 URL을 참조할 수 있음
```

**근본 문제**:
- JavaScript의 `replaceState()`와 Vue Router의 초기화 사이에 **타이밍 이슈**
- Router가 완전히 준비되기 전에 URL을 정리하면 무효화됨

---

## ✅ 해결 방법

### 수정 전 코드

```typescript
keycloak.init(options).then((authenticated) => {
  // ...
  
  // ❌ 너무 이른 시점에 URL 정리
  const cleanUrl = window.location.origin + window.location.pathname
  if (window.location.href !== cleanUrl) {
    window.history.replaceState({}, document.title, cleanUrl)
    console.log('✅ URL 정리 완료')
  }
  
  // Vue 앱 생성
  const app = createApp(App)
  app.use(router)
  app.mount('#app')
})
```

### 수정 후 코드

```typescript
keycloak.init(options).then((authenticated) => {
  // ...
  
  // Vue 앱 생성 및 마운트
  const app = createApp(App)
  app.provide('keycloak', keycloak)
  app.use(router)
  app.mount('#app')
  
  console.log('✅ [Vue] 앱 마운트 완료')
  
  // ✅ Vue Router 초기화 완료 후 URL 정리
  router.isReady().then(() => {
    console.log('🧹 [URL 정리] Vue Router 준비 완료, URL 정리 시작')
    
    // OAuth 파라미터 확인
    const urlParams = new URLSearchParams(window.location.search)
    const hasAuthParams = urlParams.has('code') || 
                           urlParams.has('state') || 
                           urlParams.has('session_state')
    
    const hashParams = new URLSearchParams(window.location.hash.substring(1))
    const hasHashAuthParams = hashParams.has('code') || 
                               hashParams.has('state') || 
                               hashParams.has('session_state')
    
    // OAuth 파라미터가 있으면 정리
    if (hasAuthParams || hasHashAuthParams) {
      console.log('  - OAuth 파라미터 감지:', {
        query: hasAuthParams,
        hash: hasHashAuthParams
      })
      
      // Router의 현재 경로 (파라미터 제외)
      const currentPath = router.currentRoute.value.path
      
      console.log('  - 이전 URL:', window.location.href)
      console.log('  - 정리 후 경로:', currentPath)
      
      // ✅ Router의 replace를 사용하여 깔끔하게 정리
      router.replace({
        path: currentPath,
        query: {},  // 모든 query 파라미터 제거
        hash: ''    // hash 제거
      }).then(() => {
        console.log('  ✅ URL 정리 완료 (Router 사용)')
        console.log('  - 최종 URL:', window.location.href)
      }).catch((err) => {
        console.warn('  ⚠️ URL 정리 중 오류:', err)
        // Fallback: 직접 replaceState 사용
        const cleanUrl = window.location.origin + currentPath
        window.history.replaceState({}, document.title, cleanUrl)
        console.log('  ✅ URL 정리 완료 (Fallback)')
      })
    } else {
      console.log('  ✅ OAuth 파라미터 없음, URL 정리 불필요')
    }
  })
})
```

---

## 🎯 핵심 개선 사항

### 1. 올바른 타이밍

**수정 전**:
```
Keycloak 인증 → URL 정리 → Vue Router 초기화
                  ❌ 무효화됨
```

**수정 후**:
```
Keycloak 인증 → Vue Router 초기화 → router.isReady() → URL 정리
                                                        ✅ 정상 동작
```

### 2. Vue Router API 사용

**수정 전**:
```typescript
// 브라우저 API 직접 사용
window.history.replaceState({}, document.title, cleanUrl)
// → Vue Router와 동기화 안됨
```

**수정 후**:
```typescript
// Vue Router API 사용
router.replace({
  path: currentPath,
  query: {},  // 파라미터 제거
  hash: ''
})
// → Vue Router가 자동으로 history 관리
```

### 3. Fallback 메커니즘

```typescript
router.replace(...).then(() => {
  console.log('✅ Router 사용 성공')
}).catch((err) => {
  console.warn('⚠️ Router 오류, Fallback 사용')
  // 직접 replaceState 사용
  window.history.replaceState({}, document.title, cleanUrl)
})
```

---

## 📊 동작 흐름 비교

### 수정 전 (문제 있음)

```
1. 사용자 접속
   ↓
2. Keycloak 리다이렉트
   URL: http://10.127.6.102:8181/?state=...&code=...
   ↓
3. Keycloak 인증 완료
   ↓
4. main.ts 실행
   ├─ keycloak.init() 성공
   ├─ window.history.replaceState() ← URL 정리 시도
   │  URL: http://10.127.6.102:8181/
   ├─ Vue 앱 생성
   ├─ router 초기화 ← window.location 읽음
   │  원래 URL 복원: http://10.127.6.102:8181/?state=...
   └─ app.mount()
   ↓
5. 화면 표시
   URL: http://10.127.6.102:8181/?state=...&code=... ❌ 파라미터 남음
```

### 수정 후 (정상 동작)

```
1. 사용자 접속
   ↓
2. Keycloak 리다이렉트
   URL: http://10.127.6.102:8181/?state=...&code=...
   ↓
3. Keycloak 인증 완료
   ↓
4. main.ts 실행
   ├─ keycloak.init() 성공
   ├─ Vue 앱 생성
   ├─ router 초기화
   ├─ app.mount()
   └─ router.isReady() 대기
   ↓
5. Router 준비 완료
   ├─ OAuth 파라미터 감지
   ├─ router.replace({ query: {}, hash: '' })
   │  URL: http://10.127.6.102:8181/ ← 정리 성공
   └─ 로그: "✅ URL 정리 완료"
   ↓
6. 화면 표시
   URL: http://10.127.6.102:8181/ ✅ 깨끗한 URL
```

---

## 🔬 기술적 세부사항

### router.isReady() Promise

**Vue Router의 isReady()**:
```typescript
router.isReady(): Promise<void>
```

**역할**:
- Router의 초기 네비게이션이 완료될 때까지 대기
- 모든 async 가드와 컴포넌트가 로드될 때까지 대기
- SSR (Server-Side Rendering) 지원

**사용 이유**:
- Router가 완전히 준비된 후 URL 정리
- 초기 라우트 설정이 완료된 후 작업 수행

### router.replace() vs window.history.replaceState()

| 방법 | 장점 | 단점 |
|------|------|------|
| **router.replace()** | Vue Router와 완전 동기화<br>라우트 가드 실행<br>컴포넌트 업데이트 자동 | Router 초기화 필수 |
| **window.history.replaceState()** | 브라우저 직접 제어<br>빠른 실행 | Vue Router와 불일치<br>수동 동기화 필요 |

**선택**: `router.replace()` 사용 (Vue 생태계 통합)

---

## 🎯 예상 결과

### 브라우저 콘솔 로그

**수정 후 예상 로그**:
```
🔐 [PKCE 지원 여부]
  - PKCE 사용 가능: false

🔧 [Keycloak Init] 초기화 옵션:
{..., pkceMethod: false, ...}

✅ [Keycloak Init] 초기화 완료
  - 인증 상태: ✅ 인증됨

🔍 [URL 분석] 현재 URL 상태
  - Full URL: http://10.127.6.102:8181/?state=xxx&code=yyy
  - Search: ?state=xxx&code=yyy
  - OAuth 파라미터 존재: true

🎨 [Vue] 앱 생성 및 마운트 시작...
✅ [Vue] 앱 마운트 완료

🧹 [URL 정리] Vue Router 준비 완료, URL 정리 시작
  - OAuth 파라미터 감지: { query: true, hash: false }
  - 이전 URL: http://10.127.6.102:8181/?state=xxx&code=yyy
  - 정리 후 경로: /
  ✅ URL 정리 완료 (Router 사용)
  - 최종 URL: http://10.127.6.102:8181/
```

### URL 변경 과정

```
1. 초기: http://10.127.6.102:8181/?state=xxx&session_state=yyy&code=zzz
2. Router 준비 완료
3. router.replace() 실행
4. 최종: http://10.127.6.102:8181/
```

**브라우저 주소창**: `http://10.127.6.102:8181/` ✅

---

## 📝 검증 방법

### 1. 로그인 프로세스 테스트

```
1. http://10.127.6.102:8181 접속
2. Keycloak 로그인 페이지로 리다이렉트
3. 로그인 완료
4. 원래 페이지로 돌아옴
5. 브라우저 주소창 확인: http://10.127.6.102:8181/ ← 파라미터 없음 ✅
```

### 2. 브라우저 콘솔 로그 확인

**확인 항목**:
- ✅ `[URL 분석]` 로그에서 OAuth 파라미터 감지
- ✅ `[URL 정리]` 로그 표시
- ✅ "Router 사용" 메시지 (또는 "Fallback" 메시지)
- ✅ 최종 URL이 파라미터 없는 깨끗한 URL

### 3. 네비게이션 테스트

```
1. 로그인 후 대시보드 표시
   → URL: http://10.127.6.102:8181/ ✅
   
2. 프로젝트 메뉴 클릭
   → URL: http://10.127.6.102:8181/projects ✅
   
3. 홈으로 돌아가기
   → URL: http://10.127.6.102:8181/ ✅
```

---

## 🔄 관련 수정 사항

### 변경된 파일

- **frontend/src/main.ts**
  - URL 정리 로직을 `router.isReady()` 이후로 이동
  - `router.replace()` 사용으로 변경
  - Fallback 메커니즘 추가

### 영향 받는 기능

- ✅ Keycloak 로그인 플로우
- ✅ URL 파라미터 정리
- ✅ 브라우저 히스토리 관리
- ✅ Vue Router 네비게이션

### 호환성

- ✅ Vue 3.5.x
- ✅ Vue Router 4.5.x
- ✅ Keycloak JS 26.2.2
- ✅ 모든 주요 브라우저

---

## ⚠️ 주의 사항

### 1. router.isReady() 타임아웃

만약 Router 초기화가 실패하면 URL 정리도 실패합니다.

**해결책**: 타임아웃 추가 (필요시)
```typescript
const timeout = new Promise((resolve) => setTimeout(resolve, 5000))
Promise.race([router.isReady(), timeout]).then(() => {
  // URL 정리 로직
})
```

### 2. 비동기 가드

Router에 async 가드가 있으면 `isReady()`가 늦어질 수 있습니다.

**현재 상태**: 
- `router/index.ts`의 `beforeEach` 가드는 동기
- 문제 없음

### 3. SSR 호환성

현재 CSR (Client-Side Rendering)만 사용하므로 문제 없음.

---

## ✅ 완료

**수정 파일**: `frontend/src/main.ts`  
**핵심 변경**: URL 정리 시점을 `router.isReady()` 이후로 이동  
**예상 결과**: Keycloak 로그인 후 깨끗한 URL 표시

**다음 단계**:
1. Git 커밋 및 푸시
2. GitHub Actions 빌드 확인
3. 개발 서버 배포 대기
4. 브라우저에서 로그인 테스트
5. URL 파라미터 정리 확인

---

**문의**: 윤성민 책임  
**작업일**: 2026-01-19
