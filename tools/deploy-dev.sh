#!/usr/bin/env bash
set -euo pipefail

# 작성일 2026 01 12
# 작업자 윤성민 책임
# 설명 이 스크립트는 PMS2 dev 서버에서 systemd timer 또는 운영자 수동 실행으로 배포를 수행하기 위한 배포 스크립트이다
# 설명 배포 방식은 pull 기반이며 GHCR에 올라간 이미지를 docker compose pull로 가져온 뒤 docker compose up -d로 재기동한다
# 설명 동일 이미지 승격 원칙을 위해 태그는 env 파일에서 주입되며 dev 환경에서는 develop latest 같은 고정 태그를 사용해 자동 배포 편의성을 높인다
# 설명 이 스크립트는 시스템 상태를 변경하며 성공 여부는 exit code로 판단할 수 있도록 설계한다

PROJECT_NAME="${PROJECT_NAME:-pms_dev}"
COMPOSE_FILE="${COMPOSE_FILE:-/opt/pms/dev/compose/docker-compose.dev.yml}"
ENV_FILE="${ENV_FILE:-/opt/pms/dev/env/.env.dev}"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "compose file not found: $COMPOSE_FILE" >&2
  exit 1
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "env file not found: $ENV_FILE" >&2
  exit 1
fi

docker compose -p "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull
docker compose -p "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

docker compose -p "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps

