# Keycloak PKCE 강제 활성화 문제 분석 및 해결

**작업일**: 2026-01-19  
**작업자**: AI Assistant (윤성민 책임 요청)  
**문제**: Web Crypto API 오류가 여전히 발생 (PKCE 비활성화 실패)

---

## 🔍 오류 로그 분석

### 수집된 로그 (docs/ERROR/260119/001_ERROR.md)

```
🔐 [PKCE 지원 여부]
  - PKCE 사용 가능: false          ✅ 감지 로직 정상
  ⚠️ HTTP + IP 접속: Web Crypto API 미지원
  ⚠️ PKCE 비활성화 모드로 전환    ✅ 로그 정상

🔧 [Keycloak Init] 초기화 옵션:
{onLoad: 'login-required', ..., checkLoginIframe: false, …}

❌ [Keycloak Init] 초기화 실패
  - Error: Web Crypto API is not available.
  at ph.createLoginUrl (...)          ← Keycloak이 로그인 URL 생성 중 오류
```

---

## 🚨 핵심 문제

### 1. 디버깅 로직은 정상 작동

```typescript
// main.ts (라인 36-48)
const supportsPKCE = window.isSecureContext || 
                     window.location.hostname === 'localhost' || 
                     window.location.hostname === '127.0.0.1'

console.log('🔐 [PKCE 지원 여부]')
console.log('  - PKCE 사용 가능:', supportsPKCE)  // ← false 출력 ✅
```

**결과**: `supportsPKCE = false` 정상 감지 ✅

### 2. PKCE 비활성화 코드 문제

**수정 전 코드** (라인 60-68):
```typescript
const initOptions: any = {
  // ...
  ...(supportsPKCE ? { pkceMethod: 'S256' } : {}),  // ← 문제!
  // ...
}
```

**문제점**:
- `supportsPKCE = false`일 때: 빈 객체 `{}` 스프레드
- 결과: `pkceMethod` 속성이 **아예 없음**
- **하지만**: Keycloak JS 26.x는 속성이 없으면 **기본적으로 PKCE 활성화!**

### 3. Keycloak JS 26.x 동작 방식

**Keycloak JS 26.2.2 (OAuth 2.1 준수)**:
- PKCE를 **기본적으로 활성화** (보안 강화)
- `pkceMethod` 속성이 없으면 → 자동으로 PKCE 시도
- `pkceMethod: undefined` → PKCE 시도
- `pkceMethod: 'S256'` → PKCE 활성화
- `pkceMethod: false` → **명시적 비활성화** ✅

**증거**:
```
Error: Web Crypto API is not available.
at ph.createLoginUrl (index-0n2vsBg6.js:25:22388)
```
→ Keycloak이 로그인 URL 생성 시 PKCE를 시도하여 Web Crypto API 요구

---

## ✅ 해결 방법

### 수정된 코드

```typescript
// 초기화 옵션 동적 설정
const initOptions: any = {
  onLoad: 'login-required',
  redirectUri: window.location.origin + '/',
  flow: 'standard',

  // ✅ PKCE: 보안 컨텍스트에서만 활성화
  // HTTP + IP 환경에서는 명시적으로 비활성화 (Web Crypto API 미지원)
  // Keycloak 26.x는 기본적으로 PKCE를 강제하므로 false로 명시 필요
  pkceMethod: supportsPKCE ? 'S256' : false,  // ← false 명시!

  responseMode: 'fragment',
  checkLoginIframe: false,
  enableLogging: true,
  messageReceiveTimeout: 10000
}
```

**변경 사항**:
```diff
- ...(supportsPKCE ? { pkceMethod: 'S256' } : {}),
+ pkceMethod: supportsPKCE ? 'S256' : false,
```

**효과**:
- `supportsPKCE = true`: `pkceMethod: 'S256'` (PKCE 활성화)
- `supportsPKCE = false`: `pkceMethod: false` (PKCE 명시적 비활성화) ✅

---

## 📊 변경 전후 비교

### 수정 전

| 환경 | supportsPKCE | initOptions.pkceMethod | Keycloak 동작 | 결과 |
|------|--------------|------------------------|---------------|------|
| localhost | true | `'S256'` | PKCE 활성화 | ✅ 정상 |
| HTTP + IP | false | `undefined` (속성 없음) | **PKCE 자동 활성화** | ❌ 오류 |

### 수정 후

| 환경 | supportsPKCE | initOptions.pkceMethod | Keycloak 동작 | 결과 |
|------|--------------|------------------------|---------------|------|
| localhost | true | `'S256'` | PKCE 활성화 | ✅ 정상 |
| HTTP + IP | false | `false` | **PKCE 비활성화** | ✅ 정상 (예상) |

---

## 🔬 기술적 상세

### Keycloak JS Adapter PKCE 정책

**Keycloak 26.x (2024년 이후)**:
- OAuth 2.1 표준 준수
- PKCE를 기본 보안 메커니즘으로 채택
- Public 클라이언트는 PKCE 사용 **강력 권장**

**PKCE 옵션**:
```typescript
// Keycloak JS Adapter
interface KeycloakInitOptions {
  pkceMethod?: 'S256' | false;  // false = 명시적 비활성화
}
```

**동작**:
1. `pkceMethod` 없음 → **기본 활성화** (안전 모드)
2. `pkceMethod: 'S256'` → 활성화
3. `pkceMethod: false` → **비활성화**

### Web Crypto API 요구 사항

**PKCE S256 프로세스**:
```javascript
// PKCE Code Verifier 생성
const codeVerifier = generateRandomString(128)

// Code Challenge 생성 (SHA-256 해싱 필요)
const codeChallenge = await crypto.subtle.digest('SHA-256', codeVerifier)
//                          ^^^^^^^^^^^^
//                          Web Crypto API 필요!
```

**보안 컨텍스트 요구**:
- `crypto.subtle`은 **Secure Context**에서만 사용 가능
- Secure Context = HTTPS 또는 localhost
- HTTP + IP = **비보안 컨텍스트** → `crypto.subtle` 없음

---

## 🎯 예상 결과

### 수정 후 로그 (예상)

```
🔐 [PKCE 지원 여부]
  - PKCE 사용 가능: false

🔧 [Keycloak Init] 초기화 옵션:
{
  onLoad: 'login-required',
  redirectUri: 'http://10.127.6.102:8181/',
  flow: 'standard',
  pkceMethod: false,              ← ✅ 명시적 비활성화
  responseMode: 'fragment',
  checkLoginIframe: false,
  enableLogging: true,
  messageReceiveTimeout: 10000
}

✅ [Keycloak Init] 초기화 성공    ← ✅ 오류 없음
  - 인증 상태: ✅ 인증됨

🔍 [URL 분석] 현재 URL 상태
  - OAuth 파라미터 존재: true
  - Search: ?state=...&code=...   ← URL 파라미터 분석 가능

🧹 [URL 정리] 파라미터 제거 중...
  ✅ URL 정리 완료
```

---

## ⚠️ 보안 고려사항

### PKCE 비활성화의 의미

**보안 수준**:
- ✅ PKCE 활성화: Authorization Code 탈취 방지 (높은 보안)
- ⚠️ PKCE 비활성화: 중간자 공격 위험 증가 (낮은 보안)

**현재 상황**:
- **개발 환경**: HTTP + IP (임시)
- **보안 위험**: 제한적 (폐쇄망 또는 개발 전용)
- **권장 사항**: HTTPS 적용 후 PKCE 활성화

### 프로덕션 배포 시

**필수 조치**:
1. ✅ HTTPS 적용 (Let's Encrypt 또는 자체 인증서)
2. ✅ PKCE S256 활성화
3. ✅ 보안 컨텍스트 확보

**체크리스트**:
- [ ] HTTPS 인증서 발급
- [ ] Nginx HTTPS 설정
- [ ] Keycloak HTTPS 설정
- [ ] PKCE 활성화 확인
- [ ] 보안 감사 수행

---

## 📦 배포 절차

### 1. 로컬 테스트
```bash
# 프론트엔드 빌드
cd frontend
pnpm build

# Docker 이미지 빌드
docker build -t pms-frontend:test .

# 테스트 실행
docker run -p 8181:80 pms-frontend:test
```

### 2. Git 커밋 및 푸시
```bash
git add frontend/src/main.ts
git commit -m "fix: Keycloak PKCE 명시적 비활성화 (HTTP+IP 환경)"
git push origin develop
```

### 3. GitHub Actions 확인
- Frontend job 성공 확인
- GHCR 이미지 푸시 확인

### 4. 개발 서버 배포
- systemd timer 자동 배포 (최대 10분)
- 또는 수동 배포:
```bash
docker compose -f /opt/pms/dev/compose/docker-compose.dev.yml pull
docker compose -f /opt/pms/dev/compose/docker-compose.dev.yml up -d
```

---

## 📝 검증 방법

### 브라우저 콘솔 로그 확인

**확인 항목**:
1. ✅ PKCE 사용 가능: false
2. ✅ pkceMethod: false (초기화 옵션)
3. ✅ Keycloak 초기화 성공
4. ✅ URL 파라미터 분석 (query vs hash)
5. ✅ 로그인 성공

**기대 로그**:
```
🔧 [Keycloak Init] 초기화 옵션:
{..., pkceMethod: false, ...}

✅ [Keycloak Init] 초기화 완료
  - 인증 상태: ✅ 인증됨
```

### 진단 페이지 확인
```
http://10.127.6.102:8181/browser-env-check.html
```

---

## 📚 참고 자료

### Keycloak 문서
- [Keycloak JS Adapter](https://www.keycloak.org/docs/latest/securing_apps/#_javascript_adapter)
- [PKCE Support](https://www.keycloak.org/docs/latest/securing_apps/#pkce-support)

### OAuth 2.1 / PKCE
- [RFC 7636: Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636)
- [OAuth 2.1 Draft](https://oauth.net/2.1/)

### Web Crypto API
- [MDN: Secure Contexts](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts)
- [MDN: SubtleCrypto](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto)

---

## ✅ 완료

**수정 파일**: `frontend/src/main.ts`  
**변경 내용**: `pkceMethod: supportsPKCE ? 'S256' : false`  
**예상 결과**: HTTP + IP 환경에서 Keycloak 정상 동작

**다음 단계**:
1. Git 커밋 및 푸시
2. GitHub Actions 성공 확인
3. 개발 서버 배포 및 테스트
4. 브라우저 콘솔 로그 확인

---

**문의**: 윤성민 책임  
**작업일**: 2026-01-19
