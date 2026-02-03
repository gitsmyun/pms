#!/bin/bash
# Backend JWT 설정 진단 및 수정

echo "========================================"
echo "🔍 Backend JWT 설정 진단"
echo "========================================"
echo ""

echo "1️⃣ Backend 환경 변수 확인"
echo "----------------------------------------"
docker exec pms-dev-backend env | grep -E "SPRING_SECURITY|OIDC|JWT"
echo ""

echo "2️⃣ docker-compose.dev.yml Backend 설정 확인"
echo "----------------------------------------"
grep -A 10 "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI" /opt/pms/dev/compose/docker-compose.dev.yml
echo ""

echo "3️⃣ env/.env.dev 파일 확인"
echo "----------------------------------------"
cat /opt/pms/dev/env/.env.dev | grep -E "OIDC|JWT"
echo ""

echo "========================================"
echo "✅ 진단 완료"
echo "========================================"
echo ""
echo "📋 예상 문제:"
echo "  - OIDC_ISSUER_URI가 비어있거나 잘못 설정됨"
echo "  - Backend가 JWT 설정 없이 시작하려고 함"
echo ""
echo "💡 해결 방법:"
echo "  1. env/.env.dev에 OIDC_ISSUER_URI 추가"
echo "  2. 또는 Backend SecurityDevConfig로 전환 (JWT 없이 동작)"
echo ""
