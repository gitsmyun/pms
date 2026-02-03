#!/bin/bash
# 최종 수정: OIDC_ISSUER_URI 환경 변수 전달 문제 해결

echo "========================================"
echo "🚀 최종 수정: OIDC 환경 변수 전달"
echo "========================================"
echo ""

echo "1️⃣ Git 최신 버전 가져오기"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms
git pull origin develop
echo "✅ Pull 완료"
echo ""

echo "2️⃣ docker-compose.dev.yml 복사"
echo "----------------------------------------"
sudo cp /mnt/c/intelliJ/git/pms/infra/docker-compose.dev.yml \
  /opt/pms/dev/compose/docker-compose.dev.yml
echo "✅ 복사 완료"
echo ""

echo "3️⃣ 변경 사항 확인"
echo "----------------------------------------"
echo "수정 전: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI: \${OIDC_ISSUER_URI:-}"
echo "수정 후: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI: \${OIDC_ISSUER_URI}"
grep "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI" /opt/pms/dev/compose/docker-compose.dev.yml
echo ""

echo "4️⃣ Backend 완전 재시작 (down → up)"
echo "----------------------------------------"
cd /opt/pms/dev
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml down backend
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d backend
echo "✅ 재시작 완료"
echo ""

echo "5️⃣ 20초 대기 (Backend 시작 시간)"
sleep 20
echo ""

echo "6️⃣ Backend 환경 변수 확인"
echo "----------------------------------------"
echo "OIDC_ISSUER_URI 전달 확인:"
docker exec pms-dev-backend env | grep "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI"
echo ""

echo "7️⃣ Backend 로그 확인"
echo "----------------------------------------"
docker logs pms-dev-backend --tail 50 | grep -E "Started|SecurityOidcConfig|JwtDecoder|ERROR"
echo ""

echo "8️⃣ 헬스 체크"
echo "----------------------------------------"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ 여전히 실패"
echo ""

echo "9️⃣ 컨테이너 상태"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep pms-dev
echo ""

echo "========================================"
echo "✅ 최종 수정 완료!"
echo "========================================"
echo ""
echo "📋 확인 사항:"
echo "  6️⃣ SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI=http://keycloak:8080/realms/pms"
echo "  7️⃣ 'Started PmsBackendApplication' 로그 확인"
echo "  8️⃣ {\"status\":\"UP\"} 출력"
echo ""
echo "🧪 테스트:"
echo "  1. http://localhost:8181"
echo "  2. http://10.127.6.102:8181"
echo "  3. https://10.127.6.102:8444"
echo ""
