# 🚀 SSO IdP 빠른 시작 - Keycloak (Dev/Test)

**소요 시간**: 10분  
**난이도**: ⭐⭐☆☆☆

---

## 📋 준비물

- [x] Docker 실행 중
- [x] 인터넷 연결
- [x] 브라우저

---

## ⚡ 1단계: Keycloak 시작 (2분)

```bash
cd /opt/pms/infra

# docker-compose.dev.yml에 keycloak 추가 (아래 복사)
cat >> docker-compose.dev.yml << 'EOF'

  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    container_name: pms-dev-keycloak
    restart: unless-stopped
    ports:
      - "8280:8080"
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_HOSTNAME: localhost
      KC_HOSTNAME_PORT: 8280
      KC_HTTP_ENABLED: true
      KC_HOSTNAME_STRICT: false
      KC_HOSTNAME_STRICT_HTTPS: false
    command:
      - start-dev
    volumes:
      - keycloak-data:/opt/keycloak/data
EOF

# volumes 섹션에 추가
cat >> docker-compose.dev.yml << 'EOF'

volumes:
  keycloak-data:
EOF

# Keycloak 시작
docker compose -f docker-compose.dev.yml up -d keycloak

# 로그 확인 (1-2분 소요)
docker logs pms-dev-keycloak -f
# "Listening on: http://0.0.0.0:8080" 나오면 성공!
```

---

## ⚡ 2단계: Keycloak 설정 (5분)

### 브라우저에서 http://localhost:8280 접속

**로그인**:
- Username: `admin`
- Password: `admin`

### A. Realm 생성
1. 왼쪽 상단 **"Master"** 클릭
2. **"Create Realm"**
3. Name: `pms`
4. **Create**

### B. Client 생성
1. 왼쪽 메뉴 **"Clients"**
2. **"Create client"**
3. **General Settings**:
   - Client ID: `pms-frontend`
   - **Next**
4. **Capability config**:
   - Client authentication: `OFF`
   - ✅ Standard flow
   - ✅ Direct access grants
   - **Next**
5. **Login settings**:
   - Valid redirect URIs: `http://localhost:5173/*`
   - Valid redirect URIs: `http://localhost:8181/*`
   - Web origins: `http://localhost:5173`
   - Web origins: `http://localhost:8181`
   - **Save**

### C. 테스트 사용자 생성
1. 왼쪽 메뉴 **"Users"**
2. **"Add user"**
3. Username: `testuser`
4. Email: `test@example.com`
5. **Create**
6. **Credentials** 탭
7. **Set password**:
   - Password: `test1234`
   - Temporary: `OFF`
   - **Save**

---

## ⚡ 3단계: Backend 연동 (2분)

```bash
# .env.dev 파일 수정
vi /opt/pms/infra/.env.dev

# 추가 또는 수정:
OIDC_ISSUER_URI=http://keycloak:8080/realms/pms
OIDC_CLIENT_ID=pms-frontend
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://localhost:8181

# Backend 재시작
docker compose -f docker-compose.dev.yml restart backend

# 로그 확인
docker logs pms-dev-backend -f
# "Started PmsBackendApplication" 확인
```

---

## ⚡ 4단계: 테스트 (1분)

```bash
# 1. 토큰 발급
TOKEN=$(curl -s -X POST "http://localhost:8280/realms/pms/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=pms-frontend" \
  -d "username=testuser" \
  -d "password=test1234" \
  | jq -r '.access_token')

# 2. 토큰 확인
echo $TOKEN

# 3. API 호출 (토큰 없이 → 401)
curl http://localhost:8180/api/projects

# 4. API 호출 (토큰 있음 → 200)
curl http://localhost:8180/api/projects \
  -H "Authorization: Bearer $TOKEN"
```

---

## ✅ 성공 확인

### Backend 로그에서:
```
SecurityOidcConfig activated
JwtDecoder created
Using issuer-uri: http://keycloak:8080/realms/pms
```

### API 호출 결과:
```bash
# 토큰 없음
curl http://localhost:8180/api/projects
# → 401 Unauthorized ✅

# 토큰 있음
curl -H "Authorization: Bearer $TOKEN" http://localhost:8180/api/projects
# → 200 OK ([] 또는 데이터) ✅
```

---

## 🎯 다음 단계

### Frontend 연동 준비:
1. OIDC 라이브러리 설치
2. 로그인 UI 구현
3. 토큰 저장 및 관리

### 상세 가이드:
📘 `033_SSO_IdP_Setup_Guide_260114.md` 참조

---

## 🔧 문제 해결

### Keycloak 접속 안됨
```bash
docker logs pms-dev-keycloak
# 1-2분 기다려야 함
```

### Backend 시작 실패
```bash
docker logs pms-dev-backend
# OIDC_ISSUER_URI 확인
# 컨테이너 네트워크: keycloak:8080 사용
```

### 토큰 발급 실패
- Username/Password 확인
- Realm 이름 확인 (pms)
- Client ID 확인 (pms-frontend)

---

**완료! 이제 SSO 기반 인증이 작동합니다!** 🎉

