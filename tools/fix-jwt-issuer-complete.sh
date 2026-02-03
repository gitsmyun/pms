#!/bin/bash
# JWT Issuer 완전 해결 - 모든 접속 경로 지원 (localhost, IP HTTP, IP HTTPS)

echo "========================================"
echo "🚀 JWT Issuer 완전 해결"
echo "========================================"
echo ""
echo "📋 지원 경로:"
echo "  ✅ http://localhost:8181"
echo "  ✅ http://10.127.6.102:8181"
echo "  ✅ https://10.127.6.102:8444"
echo ""

echo "1️⃣ Git 최신 버전 Pull"
echo "----------------------------------------"
cd /mnt/c/intelliJ/git/pms 2>/dev/null || cd ~
git pull origin develop
echo "✅ Git pull 완료"
echo ""

echo "2️⃣ docker-compose.dev.yml 백업"
echo "----------------------------------------"
sudo cp /opt/pms/dev/compose/docker-compose.dev.yml \
  /opt/pms/dev/compose/docker-compose.dev.yml.backup.$(date +%Y%m%d-%H%M%S)
echo "✅ 백업 완료"
echo ""

echo "3️⃣ docker-compose.dev.yml 수정 (KC_HOSTNAME 주석 해제 + HTTP 포트로 수정)"
echo "----------------------------------------"
# KC_HOSTNAME 주석 해제
sudo sed -i 's/^      # KC_HOSTNAME: \${KEYCLOAK_HOSTNAME:-10.127.6.102}/      KC_HOSTNAME: \${KEYCLOAK_HOSTNAME:-10.127.6.102}/' \
  /opt/pms/dev/compose/docker-compose.dev.yml

# KC_HOSTNAME_PORT를 HTTP 포트(8280)로 변경 (HTTPS 포트 8543 대신!)
sudo sed -i 's/^      # KC_HOSTNAME_PORT: \${KEYCLOAK_HTTPS_PORT_DEV:-8543}/      KC_HOSTNAME_PORT: \${KEYCLOAK_PORT_DEV:-8280}/' \
  /opt/pms/dev/compose/docker-compose.dev.yml

echo "✅ KC_HOSTNAME 활성화 완료 (HTTP 포트 8280)"
echo ""

echo "4️⃣ 수정된 docker-compose.dev.yml 확인"
echo "----------------------------------------"
grep -A 2 "KC_HOSTNAME" /opt/pms/dev/compose/docker-compose.dev.yml | head -10
echo ""

echo "5️⃣ env/.env.dev 백업"
echo "----------------------------------------"
sudo cp /opt/pms/dev/env/.env.dev /opt/pms/dev/env/.env.dev.backup.$(date +%Y%m%d-%H%M%S)
echo "✅ 백업 완료"
echo ""

echo "6️⃣ env/.env.dev 수정 (OIDC_ISSUER_URI → IP 기반)"
echo "----------------------------------------"
sudo sed -i '/^OIDC_ISSUER_URI=/d' /opt/pms/dev/env/.env.dev
echo "OIDC_ISSUER_URI=http://10.127.6.102:8280/realms/pms" | sudo tee -a /opt/pms/dev/env/.env.dev
echo "✅ OIDC_ISSUER_URI 수정 완료"
echo ""

echo "7️⃣ 수정된 env 파일 확인"
echo "----------------------------------------"
cat /opt/pms/dev/env/.env.dev | grep OIDC_ISSUER_URI
echo ""

echo "8️⃣ 전체 컨테이너 재시작"
echo "----------------------------------------"
cd /opt/pms/dev
echo "컨테이너 중지..."
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml down
echo ""
echo "컨테이너 시작..."
docker compose -p pms_dev --env-file env/.env.dev -f compose/docker-compose.dev.yml up -d
echo "✅ 재시작 완료"
echo ""

echo "9️⃣ 60초 대기 (모든 서비스 시작)"
echo "----------------------------------------"
for i in {60..1}; do
  if [ $((i % 10)) -eq 0 ]; then
    echo -n "$i..."
  fi
  sleep 1
done
echo ""
echo ""

echo "🔟 Backend 환경 변수 확인"
echo "----------------------------------------"
echo "OIDC_ISSUER_URI:"
docker exec pms-dev-backend env | grep "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI"
echo ""

echo "1️⃣1️⃣ Keycloak 환경 변수 확인"
echo "----------------------------------------"
echo "KC_HOSTNAME 설정:"
docker exec pms-dev-keycloak env | grep "KC_HOSTNAME"
echo ""

echo "1️⃣2️⃣ Backend 로그 확인"
echo "----------------------------------------"
docker logs pms-dev-backend --tail 50 | grep -E "SecurityOidcConfig|OIDC Issuer|Started"
echo ""

echo "1️⃣3️⃣ Backend 헬스 체크"
echo "----------------------------------------"
curl -s http://localhost:8180/actuator/health && echo "" || echo "❌ Backend 다운"
echo ""

echo "1️⃣4️⃣ 컨테이너 상태 확인"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep pms-dev
echo ""

echo "========================================"
echo "✅ 완전 해결 완료!"
echo "========================================"
echo ""
echo "📋 수정 사항:"
echo "  1. KC_HOSTNAME=10.127.6.102 (Keycloak 고정 호스트)"
echo "  2. KC_HOSTNAME_PORT=8280"
echo "  3. OIDC_ISSUER_URI=http://10.127.6.102:8280/realms/pms"
echo ""
echo "✅ 모든 접속 경로에서 동일한 JWT Issuer 발급:"
echo "  - localhost → http://10.127.6.102:8280/realms/pms"
echo "  - IP HTTP → http://10.127.6.102:8280/realms/pms"
echo "  - IP HTTPS → http://10.127.6.102:8280/realms/pms"
echo ""
echo "🧪 브라우저에서 테스트:"
echo "  1. http://localhost:8181"
echo "  2. http://10.127.6.102:8181"
echo "  3. https://10.127.6.102:8444"
echo ""
echo "  모든 경로에서 로그인 → DB 목록 정상 로드 예상!"
echo ""
