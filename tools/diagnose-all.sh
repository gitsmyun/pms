#!/bin/bash
# 전체 시스템 종합 진단 스크립트

echo "========================================"
echo "🔍 전체 시스템 종합 진단"
echo "========================================"
echo ""

echo "1️⃣ Backend 상태"
echo "----------------------------------------"
echo -n "헬스 체크: "
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ Backend 다운"
echo ""

echo "2️⃣ Frontend 컨테이너 상세 정보"
echo "----------------------------------------"
echo "컨테이너 이름 및 상태:"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -E "frontend|NAMES"
echo ""
echo "Frontend 이미지 생성 시간:"
docker inspect pms-dev-frontend --format='Created: {{.Created}}' 2>/dev/null || echo "❌ pms-dev-frontend 컨테이너 없음"
echo ""
echo "실행 중인 모든 컨테이너 (none 포함):"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "3️⃣ 최신 Git 커밋"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms 2>/dev/null || cd /opt/pms/dev 2>/dev/null
git log --oneline --format="%ai %H %s" -1 2>/dev/null || echo "Git 저장소 없음"
echo ""

echo "4️⃣ KC_HOSTNAME 확인 (없어야 정상)"
echo "----------------------------------------"
docker exec pms-dev-keycloak env 2>/dev/null | grep "KC_HOSTNAME=" || echo "✅ KC_HOSTNAME 없음 (정상)"
echo ""

echo "5️⃣ Backend OIDC_ISSUER_URI 확인"
echo "----------------------------------------"
docker exec pms-dev-backend env 2>/dev/null | grep "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI" || echo "❌ Backend 다운 또는 환경 변수 없음"
echo ""

echo "6️⃣ 컨테이너 상태"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep pms-dev
echo ""

echo "7️⃣ 포트 확인"
echo "----------------------------------------"
sudo ss -tlnp | grep -E "8181|8280|8444|8543|8180" | awk '{print $4}' | sort -u
echo ""

echo "========================================"
echo "✅ 진단 완료"
echo "========================================"
echo ""
echo "📋 체크리스트:"
echo "  1️⃣ Backend 헬스 체크: {\"status\":\"UP\"} 출력되어야 함"
echo "  4️⃣ KC_HOSTNAME: 없어야 함"
echo "  5️⃣ OIDC_ISSUER_URI: http://keycloak:8080/realms/pms"
echo ""
echo "⚠️ Backend가 다운이면 final-fix.sh 실행 필요!"
echo ""
