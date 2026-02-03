#!/bin/bash
# 긴급 종합 진단 및 수정 스크립트

echo "========================================"
echo "🚨 긴급 종합 진단 및 수정"
echo "========================================"
echo ""

# 1. KC_HOSTNAME 문제 수정
echo "1️⃣ docker-compose.dev.yml 업데이트..."
cd /mnt/c/intelliJ/git/pms && git pull origin develop
sudo cp /mnt/c/intelliJ/git/pms/infra/docker-compose.dev.yml /opt/pms/dev/compose/docker-compose.dev.yml
echo "✅ 복사 완료"
echo ""

# 2. Keycloak 재시작
echo "2️⃣ Keycloak 재시작..."
cd /opt/pms/dev
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml restart keycloak
echo "✅ 재시작 완료"
echo ""

# 3. 대기
echo "3️⃣ 15초 대기..."
sleep 15
echo ""

# 4. Backend 상태 확인
echo "4️⃣ Backend 상태 확인"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep pms-dev-backend
echo ""

echo "Backend 로그 (최근 30줄):"
docker logs pms-dev-backend --tail 30
echo ""

echo "Backend 헬스 체크:"
curl -s http://localhost:8180/actuator/health || echo "❌ Backend 응답 없음!"
echo ""
echo ""

# 5. Keycloak 환경 변수 확인
echo "5️⃣ Keycloak 환경 변수 확인"
echo "----------------------------------------"
docker exec pms-dev-keycloak env 2>/dev/null | grep "KC_" | grep -E "HOSTNAME|PORT"
echo ""

# 6. Frontend 상태 확인
echo "6️⃣ Frontend 상태 확인"
echo "----------------------------------------"
docker inspect pms-dev-frontend --format='Image: {{.Config.Image}}'
docker inspect pms-dev-frontend --format='Created: {{.Created}}'
echo ""

echo "Nginx /api/ 프록시 설정:"
docker exec pms-dev-frontend grep -B 2 -A 8 "location /api/" /etc/nginx/conf.d/default.conf | head -15
echo ""

# 7. 컨테이너 상태
echo "7️⃣ 전체 컨테이너 상태"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep pms-dev
echo ""

# 8. 완료
echo "========================================"
echo "✅ 진단 완료!"
echo "========================================"
echo ""
echo "📋 확인 사항:"
echo "  - KC_HOSTNAME이 없어야 함 (5️⃣ 출력)"
echo "  - Backend가 Up 상태 (4️⃣ 출력)"
echo "  - Backend 헬스 체크 성공 (4️⃣ 출력)"
echo ""
echo "🧪 테스트:"
echo "  1. http://localhost:8181"
echo "  2. http://10.127.6.102:8181"
echo "  3. https://10.127.6.102:8444"
echo ""
