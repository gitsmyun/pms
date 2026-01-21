#!/bin/bash
# 최종 배포 - API 경로 수정 반영

echo "========================================"
echo "🚀 최종 배포 - API 경로 수정 반영"
echo "========================================"
echo ""

echo "1️⃣ systemd 배포 서비스 강제 실행"
echo "----------------------------------------"
sudo systemctl start pms-dev-deploy.service
echo "✅ 배포 시작됨"
echo ""

echo "2️⃣ 60초 대기 (GitHub Actions 빌드 + Pull 완료 대기)"
echo "----------------------------------------"
for i in {60..1}; do
  if [ $((i % 10)) -eq 0 ]; then
    echo -n "$i..."
  fi
  sleep 1
done
echo ""
echo ""

echo "3️⃣ Frontend 이미지 강제 Pull"
echo "----------------------------------------"
cd /opt/pms/dev
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml pull frontend
echo "✅ Pull 완료"
echo ""

echo "4️⃣ Frontend 강제 재생성"
echo "----------------------------------------"
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d --force-recreate frontend
echo "✅ 재시작 완료"
echo ""

echo "5️⃣ 15초 대기 (Frontend 시작)"
for i in {15..1}; do
  if [ $((i % 5)) -eq 0 ]; then
    echo -n "$i..."
  fi
  sleep 1
done
echo ""
echo ""

echo "6️⃣ 최종 확인"
echo "----------------------------------------"
echo "Frontend 이미지 생성 시간:"
docker inspect pms-dev-frontend --format='Created: {{.Created}}'
echo ""

echo "Backend 헬스 체크:"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ Backend 다운"
echo ""

echo "Nginx 프록시 테스트 (/api/actuator/health):"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8181/api/actuator/health
echo ""

echo "컨테이너 상태:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep pms-dev
echo ""

echo "========================================"
echo "✅ 배포 완료!"
echo "========================================"
echo ""
echo "🧪 브라우저에서 테스트:"
echo "  1. Ctrl + Shift + R (강제 새로고침)"
echo "  2. F12 → Network 탭 → Disable cache 체크"
echo "  3. http://localhost:8181 접속"
echo "  4. 로그인 후 DB 목록 확인"
echo ""
echo "✅ 예상: /api/projects 요청 → 200 OK"
echo ""
