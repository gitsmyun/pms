#!/bin/bash
# Frontend 컨테이너 이름 불일치 문제 긴급 진단

echo "========================================"
echo "🚨 Frontend 컨테이너 이름 문제 진단"
echo "========================================"
echo ""

echo "1️⃣ 모든 컨테이너 확인 (중지된 것 포함)"
echo "----------------------------------------"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "2️⃣ Frontend 관련 컨테이너 필터링"
echo "----------------------------------------"
docker ps -a | grep -E "frontend|pms.*front"
echo ""

echo "3️⃣ 'none' 이름 컨테이너 확인"
echo "----------------------------------------"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -E "none|<none>"
echo ""

echo "4️⃣ docker-compose.dev.yml 컨테이너 이름 확인"
echo "----------------------------------------"
grep -A 2 "container_name.*frontend" /opt/pms/dev/compose/docker-compose.dev.yml
echo ""

echo "5️⃣ 실행 중인 프로세스 포트 확인"
echo "----------------------------------------"
sudo ss -tlnp | grep -E "8181|8444" | awk '{print $4, $NF}'
echo ""

echo "6️⃣ Docker Compose 프로젝트 컨테이너 확인"
echo "----------------------------------------"
docker compose -p pms_dev ps -a 2>/dev/null || echo "Docker Compose 명령 실패"
echo ""

echo "========================================"
echo "✅ 진단 완료"
echo "========================================"
echo ""
echo "📋 예상 문제:"
echo "  - pms-dev-frontend 컨테이너가 없고 'none' 또는 다른 이름 사용 중"
echo "  - docker-compose.dev.yml의 container_name 설정 오류"
echo "  - 이전 컨테이너가 제대로 삭제되지 않음"
echo ""
echo "💡 해결 방법:"
echo "  1. 모든 컨테이너 정리: docker compose -p pms_dev down"
echo "  2. 재시작: docker compose -p pms_dev up -d"
echo ""
