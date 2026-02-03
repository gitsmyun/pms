#!/bin/bash
# Frontend 컨테이너 이름 문제 긴급 수정

echo "========================================"
echo "🔧 Frontend 컨테이너 이름 문제 수정"
echo "========================================"
echo ""

echo "1️⃣ 현재 상태 확인"
echo "----------------------------------------"
echo "실행 중인 모든 컨테이너:"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "2️⃣ docker-compose.dev.yml 최신 버전 확인"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms
git pull origin develop
echo "✅ Git pull 완료"
echo ""

echo "3️⃣ docker-compose.dev.yml 복사"
echo "----------------------------------------"
sudo cp /mnt/c/intelliJ/git/pms/infra/docker-compose.dev.yml \
  /opt/pms/dev/compose/docker-compose.dev.yml
echo "✅ 복사 완료"
echo ""

echo "4️⃣ container_name 설정 확인"
echo "----------------------------------------"
grep -A 3 "frontend:" /opt/pms/dev/compose/docker-compose.dev.yml | grep "container_name"
echo ""

echo "5️⃣ 모든 PMS 컨테이너 완전 정리"
echo "----------------------------------------"
cd /opt/pms/dev
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml down
echo "✅ 컨테이너 정리 완료"
echo ""

echo "6️⃣ 중지된 컨테이너 제거"
echo "----------------------------------------"
echo "중지된 컨테이너 목록:"
docker ps -aq -f status=exited
docker ps -aq -f status=exited | xargs -r docker rm
echo "✅ 제거 완료"
echo ""

echo "7️⃣ 전체 재시작"
echo "----------------------------------------"
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d
echo "✅ 재시작 완료"
echo ""

echo "8️⃣ 20초 대기 (컨테이너 시작 시간)"
sleep 20
echo ""

echo "9️⃣ 최종 확인"
echo "----------------------------------------"
echo "컨테이너 상태:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep pms-dev
echo ""

echo "Frontend 컨테이너 상세:"
docker inspect pms-dev-frontend --format='Name: {{.Name}}, Status: {{.State.Status}}, Created: {{.Created}}' 2>/dev/null || echo "❌ pms-dev-frontend 없음!"
echo ""

echo "Backend 헬스 체크:"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ Backend 다운"
echo ""

echo "========================================"
echo "✅ 수정 완료!"
echo "========================================"
echo ""
echo "📋 확인 사항:"
echo "  - pms-dev-frontend 컨테이너가 Up 상태인지 확인"
echo "  - 포트 8181, 8444가 바인딩되었는지 확인"
echo "  - Backend 헬스 체크 성공"
echo ""
echo "🧪 테스트:"
echo "  http://localhost:8181"
echo "  http://10.127.6.102:8181"
echo "  https://10.127.6.102:8444"
echo ""
