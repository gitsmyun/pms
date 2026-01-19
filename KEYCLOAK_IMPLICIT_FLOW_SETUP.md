# Keycloak Implicit Flow 설정 (HTTP+IP 환경용)

**작업일**: 2026-01-19  
**긴급**: IP 접속 Web Crypto API 오류 해결

---

## 🚨 최종 해결 방법: Implicit Flow

### 문제 요약

**Keycloak JS 26.2.2**:
- `pkceMethod: false` 설정해도 여전히 PKCE 시도
- Standard Flow는 PKCE를 강제하는 것으로 보임
- HTTP + IP 환경에서 Web Crypto API 미지원

**최종 해결책**: 
- HTTP + IP 환경: **Implicit Flow** 사용 (PKCE 불필요)
- HTTPS 또는 localhost: **Standard Flow + PKCE S256**

---

## ✅ Keycloak 서버 설정 변경 필요

### Admin Console 설정

```
http://localhost:8280/admin
또는
http://10.127.6.102:8280/admin

Realm: pms
Client: pms-frontend
```

### 1. Settings 탭

```yaml
Client ID: pms-frontend
Client Protocol: openid-connect
Access Type: public

# ✅ Flow 설정 (모두 활성화)
Standard Flow Enabled: ON          # Standard Flow (PKCE 지원)
Implicit Flow Enabled: ON          # ← 추가! Implicit Flow
Direct Access Grants Enabled: OFF
```

### 2. Valid Redirect URIs

```
http://localhost:8181/*
http://10.127.6.102:8181/*
https://10.127.6.102:8443/*   (HTTPS 적용 시)
```

### 3. Web Origins

```
http://localhost:8181
http://10.127.6.102:8181
https://10.127.6.102:8443     (HTTPS 적용 시)
```

### 4. Advanced Settings (선택)

```yaml
# PKCE는 Standard Flow에서만 작동
Proof Key for Code Exchange Code Challenge Method: S256
```

---

## 📊 Flow 비교

### Standard Flow (Authorization Code)

**장점**:
- ✅ 가장 안전 (PKCE 포함)
- ✅ Refresh Token 지원
- ✅ OAuth 2.1 표준

**단점**:
- ❌ PKCE 필수 (Web Crypto API 필요)
- ❌ HTTP + IP에서 사용 불가

**사용 조건**:
- HTTPS 또는 localhost

### Implicit Flow

**장점**:
- ✅ PKCE 불필요
- ✅ Web Crypto API 불필요
- ✅ HTTP + IP에서 사용 가능

**단점**:
- ⚠️ 보안 수준 낮음
- ⚠️ Access Token이 URL fragment에 노출
- ⚠️ Refresh Token 미지원 (일부 구현)

**사용 조건**:
- 개발 환경 임시 사용
- 프로덕션에서는 권장 안함

---

## 🔧 프론트엔드 코드 (이미 수정됨)

```typescript
const supportsPKCE = window.isSecureContext || 
                     window.location.hostname === 'localhost'

const initOptions: any = {
  onLoad: 'login-required',
  redirectUri: window.location.origin + '/',
  
  // ✅ PKCE 미지원 환경에서는 implicit flow
  flow: supportsPKCE ? 'standard' : 'implicit',
  
  responseMode: 'fragment',
  checkLoginIframe: false,
  enableLogging: true,
  messageReceiveTimeout: 10000
}

// Standard Flow에서만 PKCE 설정
if (supportsPKCE && initOptions.flow === 'standard') {
  initOptions.pkceMethod = 'S256'
}
```

**동작**:
- `localhost:8181`: Standard Flow + PKCE S256
- `10.127.6.102:8181`: Implicit Flow (PKCE 없음)

---

## 🎯 설정 절차

### 1. Keycloak Admin Console 접속

```bash
# 브라우저에서
http://localhost:8280/admin

# 로그인
Username: admin
Password: admin
```

### 2. Client 설정 변경

```
1. Realm 선택: pms
2. 좌측 메뉴: Clients
3. Client ID: pms-frontend 클릭
4. Settings 탭:
   - Implicit Flow Enabled: ON으로 변경  ← 중요!
   - Save 클릭
```

### 3. 코드 배포 (자동)

```
1. Git 푸시 완료 (이미 됨)
2. GitHub Actions 빌드 (5-10분)
3. 개발 서버 배포 (최대 10분)
```

### 4. 테스트

```bash
# IP 접속
http://10.127.6.102:8181

# 예상 로그
🔐 [PKCE 지원 여부]
  - PKCE 사용 가능: false
  ⚠️ Implicit Flow 사용 (PKCE 미지원 환경)

🔧 [Keycloak Init] 초기화 옵션:
{..., flow: 'implicit', responseMode: 'fragment', ...}

✅ [Keycloak Init] 초기화 완료  ← 오류 없음!
```

---

## ⚠️ 보안 고려사항

### Implicit Flow의 보안 위험

1. **Access Token 노출**
   - Token이 URL fragment에 포함
   - 브라우저 히스토리에 남을 수 있음
   - 중간자 공격 위험

2. **Refresh Token 제한**
   - 일부 구현에서는 Refresh Token 미지원
   - Token 만료 시 재로그인 필요

3. **CSRF 보호 약화**
   - PKCE가 없어 보안 레벨 낮음

### 권장 사항

**개발 환경**:
- ✅ Implicit Flow 허용 (임시)
- ⚠️ 폐쇄망 또는 개발 전용

**프로덕션 환경**:
- ✅ HTTPS 적용 필수
- ✅ Standard Flow + PKCE S256
- ❌ Implicit Flow 사용 금지

---

## 📝 체크리스트

### Keycloak 서버 설정

- [ ] Admin Console 접속
- [ ] `pms-frontend` 클라이언트 선택
- [ ] `Implicit Flow Enabled: ON` 설정
- [ ] Save

### 테스트

- [ ] 코드 배포 대기 (20분)
- [ ] `http://10.127.6.102:8181` 접속
- [ ] 브라우저 콘솔 확인
- [ ] `flow: 'implicit'` 로그 확인
- [ ] 로그인 성공 확인
- [ ] URL 정리 확인

### 향후 계획

- [ ] HTTPS 적용 (자체 서명 인증서)
- [ ] Standard Flow로 복귀
- [ ] PKCE S256 활성화
- [ ] Implicit Flow 비활성화

---

**긴급 조치**: Keycloak Admin Console에서 Implicit Flow를 활성화하세요!
