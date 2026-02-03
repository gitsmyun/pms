#!/bin/bash
# 개발 서버 실시간 로그 모니터링

echo "========================================"
echo "📺 개발 서버 실시간 로그 모니터링"
echo "========================================"
echo ""
echo "종료하려면 Ctrl+C를 누르세요"
echo ""

# 사용자 선택
echo "어떤 컨테이너의 로그를 보시겠습니까?"
echo ""
echo "1. Frontend (Nginx)"
echo "2. Backend (Spring Boot)"
echo "3. Keycloak (인증 서버)"
echo "4. Postgres (데이터베이스)"
echo "5. 전체 (모든 컨테이너)"
echo ""
read -p "선택 (1-5): " choice

echo ""
echo "========================================"

case $choice in
  1)
    echo "📺 Frontend 실시간 로그"
    echo "========================================"
    docker logs -f pms-dev-frontend
    ;;
  2)
    echo "📺 Backend 실시간 로그"
    echo "========================================"
    docker logs -f pms-dev-backend
    ;;
  3)
    echo "📺 Keycloak 실시간 로그"
    echo "========================================"
    docker logs -f pms-dev-keycloak
    ;;
  4)
    echo "📺 Postgres 실시간 로그"
    echo "========================================"
    docker logs -f pms-dev-postgres
    ;;
  5)
    echo "📺 전체 컨테이너 실시간 로그"
    echo "========================================"
    cd /opt/pms/dev
    docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml logs -f
    ;;
  *)
    echo "❌ 잘못된 선택입니다."
    exit 1
    ;;
esac
