#!/bin/bash
# JWT 토큰 401 오류 및 Frontend 이미지 진단

echo "========================================"
echo "🔍 JWT & Frontend 이미지 종합 진단"
echo "========================================"
echo ""

echo "1️⃣ Frontend 이미지 생성 시간"
echo "----------------------------------------"
docker inspect pms-dev-frontend --format='Created: {{.Created}}'
echo ""

echo "2️⃣ Frontend Axios Interceptor 확인"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms 2>/dev/null || cd ~
echo "파일 경로: frontend/src/api/client.ts"
if [ -f frontend/src/api/client.ts ]; then
  echo "Interceptor 검색:"
  grep -A 15 "interceptors.request" frontend/src/api/client.ts || echo "❌ interceptor.request 없음!"
else
  echo "❌ client.ts 파일 없음!"
fi
echo ""

echo "3️⃣ Backend CORS 및 401 로그"
echo "----------------------------------------"
echo "CORS 설정:"
docker logs pms-dev-backend 2>&1 | grep -i "cors" | tail -5
echo ""
echo "401/Unauthorized:"
docker logs pms-dev-backend 2>&1 | grep -iE "401|unauthorized" | tail -10
echo ""

echo "4️⃣ 최신 Git 커밋"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms 2>/dev/null && git log --oneline --format="%ai %h %s" -1
echo ""

echo "5️⃣ Frontend 이미지 Pull 필요 여부"
echo "----------------------------------------"
echo "현재 이미지: develop-latest"
echo "확인 방법: Created 시간이 최신 커밋 이후인지"
echo ""

echo "========================================"
echo "✅ 진단 완료"
echo "========================================"
echo ""
echo "📋 다음 조치:"
echo "  1. Interceptor 없으면 → 코드 수정 필요"
echo "  2. Frontend 이미지 구버전 → 강제 배포"
echo "  3. Backend 로그에 401 있으면 → CORS 문제"
echo ""
