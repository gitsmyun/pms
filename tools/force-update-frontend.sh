#!/bin/bash
# 401 오류 빠른 해결 - Frontend 강제 업데이트 및 캐시 우회

echo "========================================"
echo "🚀 401 오류 빠른 해결"
echo "========================================"
echo ""

echo "1️⃣ Frontend 이미지 강제 Pull"
echo "----------------------------------------"
cd /opt/pms/dev
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml pull frontend
echo "✅ Pull 완료"
echo ""

echo "2️⃣ Frontend 강제 재생성"
echo "----------------------------------------"
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d --force-recreate frontend
echo "✅ 재시작 완료"
echo ""

echo "3️⃣ 15초 대기..."
for i in {15..1}; do
  if [ $((i % 5)) -eq 0 ]; then
    echo -n "$i..."
  fi
  sleep 1
done
echo ""
echo ""

echo "4️⃣ Frontend 이미지 생성 시간"
echo "----------------------------------------"
docker inspect pms-dev-frontend --format='Created: {{.Created}}'
echo ""

echo "5️⃣ Frontend 컨테이너 로그"
echo "----------------------------------------"
docker logs pms-dev-frontend --tail 10
echo ""

echo "6️⃣ Nginx 프록시 테스트"
echo "----------------------------------------"
echo "Nginx를 통한 Backend 호출:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8181/api/actuator/health
echo ""

echo "7️⃣ Frontend에서 로드되는 JS 파일"
echo "----------------------------------------"
docker exec pms-dev-frontend ls -la /usr/share/nginx/html/assets/ | grep "index-" | tail -3
echo ""

echo "========================================"
echo "✅ 완료!"
echo "========================================"
echo ""
echo "📋 브라우저에서 해야 할 일:"
echo "  ⚠️ 반드시 브라우저 캐시를 무시해야 합니다!"
echo ""
echo "  방법 1: 강제 새로고침"
echo "    - Windows: Ctrl + Shift + R"
echo "    - Mac: Cmd + Shift + R"
echo ""
echo "  방법 2: 시크릿 모드"
echo "    - Chrome: Ctrl + Shift + N"
echo "    - Edge: Ctrl + Shift + P"
echo ""
echo "  방법 3: 개발자 도구 설정"
echo "    - F12 → Network 탭"
echo "    - 'Disable cache' 체크"
echo "    - 새로고침"
echo ""
echo "🔍 확인 사항 (F12 → Network 탭):"
echo "  - /api/projects 요청 URL이 'http://localhost:8181/api/projects'인지"
echo "  - 'http://localhost:8180'으로 시작하면 캐시 문제!"
echo ""
