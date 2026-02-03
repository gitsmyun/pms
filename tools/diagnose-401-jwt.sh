#!/bin/bash
# 401 오류 상세 진단 - JWT 토큰 전달 확인

echo "========================================"
echo "🔍 401 Unauthorized 오류 완전 진단"
echo "========================================"
echo ""

echo "📍 진단 시작 시각: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ========================================
# Part 1: Backend 상태 확인
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Part 1: Backend 상태 확인"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "1️⃣ Backend 컨테이너 상태"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep pms-dev-backend
echo ""

echo "2️⃣ Backend 헬스 체크"
echo "----------------------------------------"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ Backend 응답 없음!"
echo ""

echo "3️⃣ Backend 환경 변수 - OIDC 설정"
echo "----------------------------------------"
echo "OIDC_ISSUER_URI:"
docker exec pms-dev-backend env 2>/dev/null | grep "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI" || echo "❌ 환경 변수 없음!"
echo ""
echo "CORS 설정:"
docker exec pms-dev-backend env 2>/dev/null | grep "CORS_ALLOWED_ORIGINS" || echo "기본값 사용"
echo ""

echo "4️⃣ Backend Security 설정 활성화 확인"
echo "----------------------------------------"
echo "SecurityOidcConfig (JWT 검증) 활성화 여부:"
docker logs pms-dev-backend 2>&1 | grep -E "SecurityOidcConfig.*ACTIVATED" | tail -5
echo ""
echo "SecurityDevConfig (인증 없음) 활성화 여부:"
docker logs pms-dev-backend 2>&1 | grep -E "SecurityDevConfig.*ACTIVATED" | tail -5
echo ""

echo "5️⃣ Backend JWT 검증 오류 로그"
echo "----------------------------------------"
echo "최근 JWT 관련 오류:"
docker logs pms-dev-backend 2>&1 | grep -iE "jwt|token.*invalid|unauthorized|bearer.*error" | tail -20
echo ""
echo "최근 401 오류:"
docker logs pms-dev-backend 2>&1 | grep -i "401" | tail -10
echo ""

echo "6️⃣ Backend /api/projects 엔드포인트 테스트"
echo "----------------------------------------"
echo "JWT 없이 호출 (401 예상):"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8180/api/projects)
echo "Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "401" ]; then
  echo "✅ 정상: JWT 없이는 401 (인증 필요)"
elif [ "$HTTP_CODE" = "200" ]; then
  echo "⚠️ 주의: JWT 없이 200 (SecurityDevConfig 활성화됨)"
else
  echo "❌ 비정상: $HTTP_CODE (예상치 못한 응답)"
fi
echo ""

# ========================================
# Part 2: Keycloak 상태 확인
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Part 2: Keycloak 상태 확인"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "7️⃣ Keycloak 컨테이너 상태"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep pms-dev-keycloak
echo ""

echo "8️⃣ Keycloak Realm 엔드포인트 확인"
echo "----------------------------------------"
echo "Keycloak Realm 설정 확인:"
curl -s http://localhost:8280/realms/pms/.well-known/openid-configuration | jq -r '.issuer' 2>/dev/null || echo "❌ Realm 응답 없음 또는 jq 미설치"
echo ""

echo "9️⃣ Keycloak 환경 변수"
echo "----------------------------------------"
docker exec pms-dev-keycloak env 2>/dev/null | grep "KC_" | grep -E "HOSTNAME|PORT|HTTPS" || echo "확인 불가"
echo ""

# ========================================
# Part 3: Frontend 상태 확인
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Part 3: Frontend 상태 확인"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔟 Frontend 컨테이너 상태"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep pms-dev-frontend
echo ""

echo "1️⃣1️⃣ Frontend 이미지 생성 시간"
echo "----------------------------------------"
FRONTEND_CREATED=$(docker inspect pms-dev-frontend --format='{{.Created}}' 2>/dev/null)
echo "Frontend 이미지 생성: $FRONTEND_CREATED"
echo ""

echo "1️⃣2️⃣ Git 최신 커밋 시간"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms 2>/dev/null && git log --format="%ai %h %s" -1
echo ""

echo "1️⃣3️⃣ Frontend JS 파일 확인"
echo "----------------------------------------"
echo "현재 Frontend에 있는 index JS 파일:"
docker exec pms-dev-frontend ls -la /usr/share/nginx/html/assets/ 2>/dev/null | grep "index-.*\.js" | tail -3
echo ""

echo "1️⃣4️⃣ Nginx 프록시 설정 확인"
echo "----------------------------------------"
echo "Nginx /api/ 프록시 설정:"
docker exec pms-dev-frontend grep -A 10 "location /api/" /etc/nginx/conf.d/default.conf 2>/dev/null || echo "❌ 설정 확인 불가"
echo ""

echo "1️⃣5️⃣ Nginx를 통한 Backend 호출 테스트"
echo "----------------------------------------"
echo "Nginx → Backend 프록시 테스트 (/api/actuator/health):"
HTTP_CODE_NGINX=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8181/api/actuator/health)
echo "Status: $HTTP_CODE_NGINX"
if [ "$HTTP_CODE_NGINX" = "200" ]; then
  echo "✅ Nginx 프록시 정상 작동"
else
  echo "❌ Nginx 프록시 문제 ($HTTP_CODE_NGINX)"
fi
echo ""

# ========================================
# Part 4: API 클라이언트 코드 확인
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Part 4: API 클라이언트 코드 확인"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "1️⃣6️⃣ Git - client.ts baseURL 확인"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms 2>/dev/null || cd ~
if [ -f frontend/src/api/client.ts ]; then
  echo "baseURL 설정:"
  grep -E "baseURL.*:" frontend/src/api/client.ts | head -3
  echo ""
  echo "Interceptor 확인:"
  grep -A 3 "interceptors.request.use" frontend/src/api/client.ts | head -5
else
  echo "❌ client.ts 파일 없음"
fi
echo ""

echo "1️⃣7️⃣ Git - project.ts 경로 확인"
echo "----------------------------------------"
if [ -f frontend/src/api/project.ts ]; then
  echo "API 호출 경로:"
  grep -E "apiClient\.(get|post)" frontend/src/api/project.ts | head -5
else
  echo "❌ project.ts 파일 없음"
fi
echo ""

# ========================================
# Part 5: 종합 분석
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔹 Part 5: 종합 분석 및 권장 조치"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "1️⃣8️⃣ 문제 원인 자동 진단"
echo "----------------------------------------"

# Backend 상태 확인
if [ "$HTTP_CODE" = "401" ]; then
  echo "✅ Backend JWT 검증 활성화 (정상)"
else
  echo "⚠️ Backend SecurityDevConfig 활성화 (JWT 검증 안 함)"
fi

# Frontend 이미지 확인
LATEST_COMMIT_TIME=$(cd /mnt/c/intelliJ/git/pms 2>/dev/null && git log --format="%ai" -1)
if [[ "$FRONTEND_CREATED" > "$LATEST_COMMIT_TIME" ]]; then
  echo "✅ Frontend 이미지가 최신"
else
  echo "❌ Frontend 이미지가 구버전! (강제 Pull 필요)"
fi

# Nginx 프록시 확인
if [ "$HTTP_CODE_NGINX" = "200" ]; then
  echo "✅ Nginx 프록시 정상"
else
  echo "❌ Nginx 프록시 문제"
fi

echo ""

echo "1️⃣9️⃣ 가능한 원인 및 해결 방법"
echo "----------------------------------------"
echo ""
echo "📋 체크리스트:"
echo ""
echo "✓ 원인 1: Frontend 이미지가 구버전"
echo "  증상: client.ts baseURL이 여전히 'http://localhost:8180'"
echo "  확인: 1️⃣1️⃣ Frontend 이미지 시간 < 1️⃣2️⃣ Git 커밋 시간"
echo "  해결: cd /opt/pms/dev && docker compose pull frontend && docker compose up -d --force-recreate frontend"
echo ""
echo "✓ 원인 2: 브라우저 캐시 문제"
echo "  증상: 이전 JS 파일 (baseURL: 'http://localhost:8180') 사용 중"
echo "  확인: F12 → Network → /api/projects → Request Headers → Authorization 없음"
echo "  해결: Ctrl + Shift + R (강제 새로고침) 또는 시크릿 모드"
echo ""
echo "✓ 원인 3: JWT 토큰이 Keycloak에서 발급 안 됨"
echo "  증상: 로그인 성공했지만 window.keycloak.token이 없음"
echo "  확인: F12 → Console → window.keycloak.token 출력"
echo "  해결: Keycloak 클라이언트 설정 확인"
echo ""
echo "✓ 원인 4: Axios Interceptor가 토큰을 추가 안 함"
echo "  증상: window.keycloak.token은 있지만 Authorization 헤더 없음"
echo "  확인: F12 → Network → /api/projects → Request Headers"
echo "  해결: client.ts Interceptor 코드 확인"
echo ""
echo "✓ 원인 5: Backend JWT 검증 오류"
echo "  증상: Authorization 헤더는 있지만 Backend가 토큰 거부"
echo "  확인: 5️⃣ Backend 로그에 JWT 검증 오류"
echo "  해결: Keycloak Issuer URI 확인 (3️⃣, 8️⃣)"
echo ""

echo "2️⃣0️⃣ 즉시 실행할 명령어 (원인별)"
echo "----------------------------------------"
echo ""
echo "💡 원인 1 해결 (Frontend 구버전):"
echo "  cd /opt/pms/dev"
echo "  docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml pull frontend"
echo "  docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d --force-recreate frontend"
echo ""
echo "💡 원인 2 해결 (브라우저 캐시):"
echo "  Ctrl + Shift + R (Windows)"
echo "  Cmd + Shift + R (Mac)"
echo ""
echo "💡 원인 5 해결 (JWT 검증 오류):"
echo "  docker logs pms-dev-backend --tail 100 | grep -i error"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 진단 완료"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 진단 완료 시각: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "🔍 브라우저에서 추가 확인 필요:"
echo ""
echo "  1. F12 → Console 탭:"
echo "     window.keycloak.token"
echo "     → JWT 토큰 있는지 확인"
echo ""
echo "  2. F12 → Network 탭 → /api/projects 클릭:"
echo "     Request Headers:"
echo "     - Authorization: Bearer eyJhbGc... ← 있어야 함!"
echo ""
echo "  3. F12 → Network 탭 → Disable cache 체크"
echo "     → 새로고침"
echo ""
echo "📋 진단 결과를 캡처하여 공유하면 정확한 원인 파악 가능합니다."
echo ""
