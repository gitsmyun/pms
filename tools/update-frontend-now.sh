#!/bin/bash
# Frontend 긴급 업데이트 - baseURL 수정 반영

echo "========================================"
echo "🚀 Frontend 긴급 업데이트"
echo "========================================"
echo ""

echo "1️⃣ systemd 배포 서비스 실행"
echo "----------------------------------------"
sudo systemctl start pms-dev-deploy.service
echo "✅ 배포 시작됨"
echo ""

echo "2️⃣ 40초 대기 (빌드 완료 대기)"
echo "----------------------------------------"
for i in {40..1}; do
  if [ $((i % 10)) -eq 0 ]; then
    echo -n "$i..."
  fi
  sleep 1
done
echo ""
echo ""

echo "3️⃣ 배포 로그 확인"
echo "----------------------------------------"
sudo journalctl -u pms-dev-deploy.service -n 20 --no-pager
echo ""

echo "4️⃣ Frontend 컨테이너 상태"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep pms-dev-frontend
echo ""

echo "5️⃣ Frontend 이미지 생성 시간"
echo "----------------------------------------"
docker inspect pms-dev-frontend --format='Created: {{.Created}}'
echo ""

echo "6️⃣ Backend 헬스 체크"
echo "----------------------------------------"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ Backend 다운"
echo ""

echo "========================================"
echo "✅ 업데이트 완료"
echo "========================================"
echo ""
echo "🧪 테스트:"
echo "  1. http://localhost:8181"
echo "  2. https://10.127.6.102:8444"
echo ""
echo "📋 확인 사항:"
echo "  - 로그인 후 DB 목록 정상 로드"
echo "  - 401 오류 없음"
echo ""
