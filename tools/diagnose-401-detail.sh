#!/bin/bash
# 401 오류 상세 진단 - Frontend 이미지 및 실제 요청 확인

echo "========================================"
echo "🔍 401 오류 상세 진단"
echo "========================================"
echo ""

echo "1️⃣ Frontend 이미지 확인"
echo "----------------------------------------"
echo "현재 이미지 생성 시간:"
docker inspect pms-dev-frontend --format='Created: {{.Created}}'
echo ""
echo "Git 최신 커밋 시간:"
cd /mnt/c/intelliJ/git/pms 2>/dev/null && git log --format="%ai %h %s" -1
echo ""

echo "2️⃣ Frontend 빌드 파일 확인"
echo "----------------------------------------"
echo "현재 실행 중인 Frontend의 JS 파일:"
docker exec pms-dev-frontend ls -la /usr/share/nginx/html/assets/ | grep "index-" | head -5
echo ""

echo "3️⃣ Backend JWT 검증 로그"
echo "----------------------------------------"
echo "최근 Backend 로그 (JWT 관련):"
docker logs pms-dev-backend --tail 100 | grep -iE "jwt|token|401|unauthorized|bearer" | tail -20
echo ""

echo "4️⃣ Nginx 프록시 설정 확인"
echo "----------------------------------------"
echo "Nginx /api/ 프록시 설정:"
docker exec pms-dev-frontend grep -A 10 "location /api/" /etc/nginx/conf.d/default.conf
echo ""

echo "5️⃣ Backend 헬스 체크"
echo "----------------------------------------"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ Backend 다운"
echo ""

echo "6️⃣ Frontend에서 Backend 직접 호출 테스트"
echo "----------------------------------------"
echo "Nginx를 통한 프록시 테스트:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8181/api/actuator/health
echo ""

echo "7️⃣ JWT 토큰 없이 API 호출 테스트 (401 예상)"
echo "----------------------------------------"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8181/api/projects
echo ""

echo "========================================"
echo "✅ 진단 완료"
echo "========================================"
echo ""
echo "📋 확인 사항:"
echo "  1️⃣ Frontend 이미지가 최신인지 (커밋 시간 이후)"
echo "  2️⃣ Nginx 프록시 설정이 올바른지"
echo "  3️⃣ Backend가 JWT 검증 중인지"
echo ""
echo "💡 브라우저 캐시 문제일 수도 있음!"
echo "  - Ctrl+Shift+R (강제 새로고침)"
echo "  - 또는 시크릿 모드로 테스트"
echo ""
