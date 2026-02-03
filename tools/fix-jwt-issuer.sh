#!/bin/bash
# JWT Issuer 불일치 긴급 수정

echo "========================================"
echo "🚨 JWT Issuer 불일치 긴급 수정"
echo "========================================"
echo ""

echo "📋 문제 요약:"
echo "  JWT 토큰 iss: http://localhost:8280/realms/pms"
echo "  Backend 설정: http://keycloak:8080/realms/pms"
echo "  → Issuer 불일치로 401 오류!"
echo ""

echo "1️⃣ 현재 Backend OIDC_ISSUER_URI 확인"
echo "----------------------------------------"
docker exec pms-dev-backend env | grep "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI"
echo ""

echo "2️⃣ env 파일 백업"
echo "----------------------------------------"
sudo cp /opt/pms/dev/env/.env.dev /opt/pms/dev/env/.env.dev.backup.$(date +%Y%m%d-%H%M%S)
echo "✅ 백업 완료"
echo ""

echo "3️⃣ env 파일 수정"
echo "----------------------------------------"
echo "기존 OIDC_ISSUER_URI 제거 및 새 값 추가..."
sudo sed -i '/^OIDC_ISSUER_URI=/d' /opt/pms/dev/env/.env.dev
echo "OIDC_ISSUER_URI=http://localhost:8280/realms/pms" | sudo tee -a /opt/pms/dev/env/.env.dev
echo "✅ 수정 완료"
echo ""

echo "4️⃣ 수정된 env 파일 확인"
echo "----------------------------------------"
cat /opt/pms/dev/env/.env.dev | grep OIDC_ISSUER_URI
echo ""

echo "5️⃣ Backend 재시작"
echo "----------------------------------------"
cd /opt/pms/dev
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml restart backend
echo "✅ 재시작 완료"
echo ""

echo "6️⃣ 40초 대기 (Backend 시작)"
for i in {40..1}; do
  if [ $((i % 10)) -eq 0 ]; then
    echo -n "$i..."
  fi
  sleep 1
done
echo ""
echo ""

echo "7️⃣ Backend 환경 변수 재확인"
echo "----------------------------------------"
docker exec pms-dev-backend env | grep "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI"
echo ""

echo "8️⃣ Backend 로그 확인"
echo "----------------------------------------"
docker logs pms-dev-backend --tail 50 | grep -E "SecurityOidcConfig|OIDC Issuer|Started"
echo ""

echo "9️⃣ Backend 헬스 체크"
echo "----------------------------------------"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ Backend 다운"
echo ""

echo "========================================"
echo "✅ 수정 완료!"
echo "========================================"
echo ""
echo "🧪 브라우저에서 테스트:"
echo "  1. http://localhost:8181 새로고침"
echo "  2. 로그인 (또는 이미 로그인됨)"
echo "  3. DB 목록 로드 확인"
echo ""
echo "✅ 예상: JWT Issuer가 일치하여 200 OK"
echo ""
