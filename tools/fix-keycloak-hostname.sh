#!/bin/bash
# 긴급 수정 스크립트 - docker-compose.dev.yml 업데이트 및 Keycloak 재시작

echo "========================================"
echo "🚀 긴급 수정: docker-compose.dev.yml 업데이트"
echo "========================================"
echo ""

# 1. Git 최신 버전 가져오기
echo "1️⃣ Git pull..."
cd /mnt/c/intelliJ/git/pms || exit 1
git pull origin develop
echo "✅ Git pull 완료"
echo ""

# 2. 파일 복사
echo "2️⃣ docker-compose.dev.yml 복사..."
sudo cp /mnt/c/intelliJ/git/pms/infra/docker-compose.dev.yml \
  /opt/pms/dev/compose/docker-compose.dev.yml
echo "✅ 복사 완료"
echo ""

# 3. 변경 사항 확인
echo "3️⃣ 변경 사항 확인:"
echo "----------------------------------------"
grep -B 2 -A 2 "KC_HOSTNAME" /opt/pms/dev/compose/docker-compose.dev.yml | head -15
echo ""

# 4. Keycloak 재시작
echo "4️⃣ Keycloak 재시작..."
cd /opt/pms/dev || exit 1
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml restart keycloak
echo "✅ 재시작 완료"
echo ""

# 5. 대기
echo "5️⃣ 10초 대기 중..."
sleep 10
echo ""

# 6. 환경 변수 확인
echo "6️⃣ Keycloak 환경 변수 확인:"
echo "----------------------------------------"
docker exec pms-dev-keycloak env 2>/dev/null | grep "KC_" | grep -E "HOSTNAME|PORT" || echo "❌ 확인 실패"
echo ""

# 7. 컨테이너 상태
echo "7️⃣ 컨테이너 상태:"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep pms-dev
echo ""

# 8. 완료
echo "========================================"
echo "✅ 수정 완료!"
echo "========================================"
echo ""
echo "🧪 테스트:"
echo "  1. http://localhost:8181"
echo "  2. http://10.127.6.102:8181"
echo "  3. https://10.127.6.102:8444"
echo ""
echo "📋 확인 사항:"
echo "  - KC_HOSTNAME이 주석 처리되었는지 확인 (3️⃣ 출력)"
echo "  - KC_HOSTNAME 환경 변수가 없는지 확인 (6️⃣ 출력)"
echo ""
