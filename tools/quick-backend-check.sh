#!/bin/bash
# Backend 시작 문제 빠른 진단

echo "========================================"
echo "🔍 Backend 빠른 진단"
echo "========================================"
echo ""

echo "1️⃣ 40초 추가 대기..."
for i in {40..1}; do
  if [ $((i % 10)) -eq 0 ]; then
    echo -n "$i..."
  fi
  sleep 1
done
echo ""
echo ""

echo "2️⃣ Backend 헬스 체크"
echo "----------------------------------------"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ 여전히 다운"
echo ""

echo "3️⃣ Backend 환경 변수 확인"
echo "----------------------------------------"
docker exec pms-dev-backend env 2>/dev/null | grep "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI" || echo "❌ Backend 다운 또는 환경 변수 없음"
echo ""

echo "4️⃣ Backend 로그 (시작 관련)"
echo "----------------------------------------"
docker logs pms-dev-backend 2>&1 | tail -50 | grep -E "Started|ERROR|JwtDecoder"
echo ""

echo "5️⃣ env 파일 확인"
echo "----------------------------------------"
cat /opt/pms/dev/env/.env.dev | grep OIDC_ISSUER_URI || echo "❌ OIDC_ISSUER_URI 없음!"
echo ""

echo "========================================"
echo "✅ 진단 완료"
echo "========================================"
echo ""
echo "📋 다음 조치:"
echo "  - Backend가 정상이면: 모든 URL 테스트"
echo "  - Backend가 다운이면: env 파일에 OIDC_ISSUER_URI 추가 후 재시작"
echo ""
