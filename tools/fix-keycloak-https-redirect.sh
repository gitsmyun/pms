#!/bin/bash
# Keycloak HTTPS 리다이렉트 완전 해결

echo "========================================"
echo "🚀 Keycloak HTTPS 리다이렉트 완전 해결"
echo "========================================"
echo ""

echo "1️⃣ Git 최신 버전 가져오기"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms
git pull origin develop
echo "✅ Pull 완료"
echo ""

echo "2️⃣ Git 코드 확인"
echo "----------------------------------------"
echo "KC_HTTPS_ENABLED 설정:"
grep "KC_HTTPS_ENABLED" infra/docker-compose.dev.yml
echo ""

echo "3️⃣ 개발 서버 compose 파일 백업"
echo "----------------------------------------"
sudo cp /opt/pms/dev/compose/docker-compose.dev.yml \
  /opt/pms/dev/compose/docker-compose.dev.yml.backup.$(date +%Y%m%d-%H%M%S)
echo "✅ 백업 완료"
echo ""

echo "4️⃣ Git 코드를 개발 서버로 복사"
echo "----------------------------------------"
sudo cp /mnt/c/intelliJ/git/pms/infra/docker-compose.dev.yml \
  /opt/pms/dev/compose/docker-compose.dev.yml
echo "✅ 복사 완료"
echo ""

echo "5️⃣ 복사 확인"
echo "----------------------------------------"
echo "개발 서버 compose 파일의 KC_HTTPS_ENABLED:"
grep "KC_HTTPS_ENABLED" /opt/pms/dev/compose/docker-compose.dev.yml
echo ""

echo "6️⃣ Keycloak 컨테이너 재생성"
echo "----------------------------------------"
cd /opt/pms/dev
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml stop keycloak
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml rm -f keycloak
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d keycloak
echo "✅ Keycloak 재시작 완료"
echo ""

echo "7️⃣ 40초 대기 (Keycloak 시작)"
for i in {40..1}; do
  if [ $((i % 10)) -eq 0 ]; then
    echo -n "$i..."
  fi
  sleep 1
done
echo ""
echo ""

echo "8️⃣ Keycloak 상태 확인"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep keycloak
echo ""

echo "9️⃣ Keycloak 환경 변수 확인"
echo "----------------------------------------"
echo "KC_HTTPS_ENABLED 값:"
docker exec pms-dev-keycloak env | grep "KC_HTTPS_ENABLED"
echo ""
echo "전체 KC_ 환경 변수:"
docker exec pms-dev-keycloak env | grep "KC_" | grep -E "HTTP|HOSTNAME"
echo ""

echo "🔟 Keycloak 로그 확인"
echo "----------------------------------------"
docker logs pms-dev-keycloak --tail 30 | grep -iE "http|hostname|start"
echo ""

echo "========================================"
echo "✅ 완전 해결 완료!"
echo "========================================"
echo ""
echo "🧪 브라우저 테스트:"
echo "  1. http://localhost:8181 접속"
echo "  2. Keycloak 로그인 (localhost:8280)"
echo "  3. localhost:8181로 돌아오는지 확인"
echo ""
echo "✅ 예상 결과:"
echo "  - localhost:8181 유지 ✅"
echo "  - 10.127.6.102로 리다이렉트 안 됨 ✅"
echo "  - 8543 포트로 리다이렉트 안 됨 ✅"
echo ""
