#!/bin/bash
# 자동 배포 상태 확인 및 강제 실행 스크립트
#
# 사용법:
#   ./check-auto-deploy.sh        # 상태 확인만
#   ./check-auto-deploy.sh -f     # 강제 실행
#   ./check-auto-deploy.sh --force # 강제 실행

# 강제 실행 플래그 확인
FORCE_DEPLOY=false
if [[ "$1" == "-f" || "$1" == "--force" ]]; then
    FORCE_DEPLOY=true
fi

if [ "$FORCE_DEPLOY" = true ]; then
    echo "========================================"
    echo "🚀 PMS 강제 배포 실행"
    echo "========================================"
    echo ""

    echo "📦 배포 시작..."
    sudo systemctl start pms-dev-deploy.service

    echo ""
    echo "⏳ 5초 대기 중..."
    sleep 5

    echo ""
    echo "📋 배포 로그 (최근 30줄):"
    echo "----------------------------------------"
    sudo journalctl -u pms-dev-deploy.service -n 30 --no-pager

    echo ""
    echo "🐳 컨테이너 상태:"
    echo "----------------------------------------"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep pms-dev

    echo ""
    echo "========================================"
    echo "✅ 배포 완료!"
    echo "========================================"
    exit 0
fi

echo "========================================"
echo "PMS 자동 배포 상태 확인"
echo "========================================"
echo ""

echo "1️⃣ systemd 타이머 상태:"
echo "----------------------------------------"
sudo systemctl status pms-dev-deploy.timer 2>/dev/null || echo "❌ 타이머가 설치되어 있지 않습니다"
echo ""

echo "2️⃣ systemd 서비스 상태:"
echo "----------------------------------------"
sudo systemctl status pms-dev-deploy.service 2>/dev/null || echo "❌ 서비스가 설치되어 있지 않습니다"
echo ""

echo "3️⃣ 다음 실행 시간:"
echo "----------------------------------------"
sudo systemctl list-timers | grep pms-dev-deploy || echo "❌ 타이머가 활성화되어 있지 않습니다"
echo ""

echo "4️⃣ 최근 배포 로그 (최근 20줄):"
echo "----------------------------------------"
sudo journalctl -u pms-dev-deploy.service -n 20 --no-pager 2>/dev/null || echo "❌ 배포 로그가 없습니다"
echo ""

echo "========================================"
echo "✅ 확인 완료"
echo "========================================"
echo ""
echo "💡 강제 실행하려면:"
echo "   sudo ./check-auto-deploy.sh -f"
echo "   또는"
echo "   sudo ./check-auto-deploy.sh --force"
echo ""
