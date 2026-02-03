#!/bin/bash
# Backend 실시간 로그 (필터링)

echo "========================================"
echo "📺 Backend 실시간 로그 (필터링)"
echo "========================================"
echo ""
echo "보고 싶은 로그 유형을 선택하세요:"
echo ""
echo "1. 전체 로그 (필터 없음)"
echo "2. ERROR 로그만"
echo "3. WARN 로그만"
echo "4. JWT/인증 관련 로그"
echo "5. API 요청 로그"
echo "6. Security 설정 로그"
echo "7. Keycloak/OIDC 관련 로그"
echo ""
read -p "선택 (1-7): " choice

echo ""
echo "========================================"
echo "종료하려면 Ctrl+C를 누르세요"
echo "========================================"
echo ""

case $choice in
  1)
    echo "📺 Backend 전체 로그"
    docker logs -f pms-dev-backend
    ;;
  2)
    echo "📺 Backend ERROR 로그"
    docker logs -f pms-dev-backend 2>&1 | grep --line-buffered -E "ERROR|Exception|error"
    ;;
  3)
    echo "📺 Backend WARN 로그"
    docker logs -f pms-dev-backend 2>&1 | grep --line-buffered -E "WARN|warning"
    ;;
  4)
    echo "📺 Backend JWT/인증 로그"
    docker logs -f pms-dev-backend 2>&1 | grep --line-buffered -iE "jwt|token|auth|issuer|bearer"
    ;;
  5)
    echo "📺 Backend API 요청 로그"
    docker logs -f pms-dev-backend 2>&1 | grep --line-buffered -E "GET|POST|PUT|DELETE|PATCH|/api/"
    ;;
  6)
    echo "📺 Backend Security 설정 로그"
    docker logs -f pms-dev-backend 2>&1 | grep --line-buffered -E "Security|ACTIVATED|JwtDecoder|Issuer"
    ;;
  7)
    echo "📺 Backend Keycloak/OIDC 로그"
    docker logs -f pms-dev-backend 2>&1 | grep --line-buffered -iE "keycloak|oidc|oauth|realm"
    ;;
  *)
    echo "❌ 잘못된 선택입니다."
    exit 1
    ;;
esac
