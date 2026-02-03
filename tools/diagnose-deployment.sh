#!/bin/bash
# 배포 상태 종합 진단 스크립트

echo "========================================"
echo "🔍 PMS 배포 상태 종합 진단"
echo "========================================"
echo ""

echo "1️⃣ Git 최신 커밋 확인"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms 2>/dev/null || cd ~/pms 2>/dev/null || echo "❌ Git 저장소 없음"
git log --oneline -1 2>/dev/null || echo "❌ Git 명령 실패"
echo ""

echo "2️⃣ 서버 docker-compose.dev.yml 상태"
echo "----------------------------------------"
if [ -f /opt/pms/dev/compose/docker-compose.dev.yml ]; then
    echo "✅ 파일 존재"
    echo ""
    echo "📋 KC_HOSTNAME 설정:"
    grep -n "KC_HOSTNAME" /opt/pms/dev/compose/docker-compose.dev.yml | head -5
else
    echo "❌ 파일 없음"
fi
echo ""

echo "3️⃣ Keycloak 컨테이너 환경 변수"
echo "----------------------------------------"
docker exec pms-dev-keycloak env 2>/dev/null | grep "KC_" | grep -E "HOSTNAME|PORT" || echo "❌ Keycloak 컨테이너 없음"
echo ""

echo "4️⃣ Frontend 이미지 정보"
echo "----------------------------------------"
docker inspect pms-dev-frontend --format='Image: {{.Config.Image}}' 2>/dev/null || echo "❌ Frontend 컨테이너 없음"
docker inspect pms-dev-frontend --format='Created: {{.Created}}' 2>/dev/null
echo ""

echo "5️⃣ 컨테이너 실행 시간"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | grep pms-dev || echo "❌ 컨테이너 없음"
echo ""

echo "6️⃣ systemd 타이머 상태"
echo "----------------------------------------"
sudo systemctl list-timers 2>/dev/null | grep pms-dev-deploy || echo "❌ 타이머 없음"
echo ""

echo "7️⃣ 최근 배포 로그 (마지막 10줄)"
echo "----------------------------------------"
sudo journalctl -u pms-dev-deploy.service -n 10 --no-pager 2>/dev/null || echo "❌ 배포 로그 없음"
echo ""

echo "8️⃣ Keycloak Valid Redirect URIs 확인 필요"
echo "----------------------------------------"
echo "수동 확인 필요:"
echo "  http://10.127.6.102:8280/admin"
echo "  Clients → pms-frontend → Settings → Valid Redirect URIs"
echo ""

echo "========================================"
echo "✅ 진단 완료"
echo "========================================"
echo ""
echo "📋 다음 단계:"
echo "  1. KC_HOSTNAME 확인 (주석 처리되어 있어야 함)"
echo "  2. Frontend 이미지가 최신인지 확인"
echo "  3. 문제 발견 시 docs/ERROR/260119/006_Deployment_Verification_Failed.md 참고"
