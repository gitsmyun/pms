#!/bin/bash
# 긴급 수정: docker-compose.dev.yml의 OIDC_ISSUER_URI 기본값 제거

echo "========================================"
echo "🔧 docker-compose.dev.yml OIDC 설정 수정"
echo "========================================"
echo ""

echo "1️⃣ 현재 설정 확인"
echo "----------------------------------------"
grep "OIDC_ISSUER_URI" /opt/pms/dev/compose/docker-compose.dev.yml
echo ""

echo "2️⃣ Git에서 최신 파일 확인"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms
git pull origin develop
grep "OIDC_ISSUER_URI" infra/docker-compose.dev.yml
echo ""

echo "3️⃣ 서버 파일 백업"
echo "----------------------------------------"
sudo cp /opt/pms/dev/compose/docker-compose.dev.yml \
  /opt/pms/dev/compose/docker-compose.dev.yml.backup.$(date +%Y%m%d-%H%M%S)
echo "✅ 백업 완료"
echo ""

echo "4️⃣ 수정된 파일 복사"
echo "----------------------------------------"
sudo cp /mnt/c/intelliJ/git/pms/infra/docker-compose.dev.yml \
  /opt/pms/dev/compose/docker-compose.dev.yml
echo "✅ 복사 완료"
echo ""

echo "5️⃣ Backend 재시작"
echo "----------------------------------------"
cd /opt/pms/dev
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml down backend
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d backend
echo "✅ 재시작 완료"
echo ""

echo "6️⃣ 15초 대기..."
sleep 15
echo ""

echo "7️⃣ Backend 환경 변수 확인"
echo "----------------------------------------"
docker exec pms-dev-backend env | grep "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI"
echo ""

echo "8️⃣ Backend 로그 확인"
echo "----------------------------------------"
docker logs pms-dev-backend --tail 40
echo ""

echo "9️⃣ 헬스 체크"
echo "----------------------------------------"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ 여전히 실패"
echo ""

echo "========================================"
echo "✅ 수정 완료"
echo "========================================"
