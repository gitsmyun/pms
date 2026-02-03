#!/bin/bash
# Backend OIDC 빠른 수정 스크립트

echo "========================================"
echo "🔧 Backend OIDC 설정 수정"
echo "========================================"
echo ""

echo "1️⃣ 현재 env 파일 확인"
echo "----------------------------------------"
cat /opt/pms/dev/env/.env.dev
echo ""

echo "2️⃣ OIDC_ISSUER_URI 추가"
echo "----------------------------------------"
if ! grep -q "OIDC_ISSUER_URI" /opt/pms/dev/env/.env.dev; then
    echo "OIDC_ISSUER_URI=http://keycloak:8080/realms/pms" | sudo tee -a /opt/pms/dev/env/.env.dev
    echo "✅ OIDC_ISSUER_URI 추가 완료"
else
    echo "⚠️ OIDC_ISSUER_URI 이미 존재"
    grep "OIDC_ISSUER_URI" /opt/pms/dev/env/.env.dev
fi
echo ""

echo "3️⃣ Backend 재시작"
echo "----------------------------------------"
cd /opt/pms/dev
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml restart backend
echo "✅ 재시작 완료"
echo ""

echo "4️⃣ 15초 대기..."
sleep 15
echo ""

echo "5️⃣ Backend 로그 확인"
echo "----------------------------------------"
docker logs pms-dev-backend --tail 40
echo ""

echo "6️⃣ Backend 환경 변수 확인"
echo "----------------------------------------"
docker exec pms-dev-backend env | grep -E "SPRING_SECURITY|OIDC"
echo ""

echo "7️⃣ 헬스 체크"
echo "----------------------------------------"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ Backend 여전히 실패"
echo ""

echo "========================================"
echo "✅ 수정 완료"
echo "========================================"
echo ""
echo "📋 확인 사항:"
echo "  - Backend 로그에 'Started PmsBackendApplication' 있어야 함"
echo "  - 헬스 체크 성공: {\"status\":\"UP\"}"
echo ""
