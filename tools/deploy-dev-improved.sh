#!/usr/bin/env bash
set -euo pipefail

# 작성일 2026 01 12
# 수정일 2026 01 21 - Git에서 docker-compose.dev.yml 자동 업데이트 추가
# 작업자 윤성민 책임
# 설명 이 스크립트는 PMS2 dev 서버에서 systemd timer 또는 운영자 수동 실행으로 배포를 수행하기 위한 배포 스크립트이다
# 설명 배포 방식은 pull 기반이며 GHCR에 올라간 이미지를 docker compose pull로 가져온 뒤 docker compose up -d로 재기동한다
# 설명 동일 이미지 승격 원칙을 위해 태그는 env 파일에서 주입되며 dev 환경에서는 develop latest 같은 고정 태그를 사용해 자동 배포 편의성을 높인다
# 설명 이 스크립트는 시스템 상태를 변경하며 성공 여부는 exit code로 판단할 수 있도록 설계한다
# 설명 정석 운영 모델에서는 전용 실행 계정 pms가 docker 그룹에 포함되어 docker를 직접 실행한다
# 설명 env 파일은 root 소유로 두되 group을 docker로 설정하고 640 권한을 부여해 pms가 읽을 수 있게 한다

PROJECT_NAME="${PROJECT_NAME:-pms_dev}"
COMPOSE_FILE="${COMPOSE_FILE:-/opt/pms/dev/compose/docker-compose.dev.yml}"
ENV_FILE="${ENV_FILE:-/opt/pms/dev/env/.env.dev}"
GIT_REPO="${GIT_REPO:-/mnt/c/intelliJ/git/pms}"
COMPOSE_SOURCE="${COMPOSE_SOURCE:-${GIT_REPO}/infra/docker-compose.dev.yml}"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "compose file not found: $COMPOSE_FILE" >&2
  exit 1
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "env file not found: $ENV_FILE" >&2
  exit 1
fi

# ========================================
# 1. Git에서 최신 docker-compose.dev.yml 가져오기 (신규 추가)
# ========================================
if [[ -d "$GIT_REPO/.git" ]]; then
  echo "[deploy-dev.sh] Git 저장소에서 최신 docker-compose.dev.yml 가져오기..."

  # Git pull
  cd "$GIT_REPO"
  git fetch origin develop 2>/dev/null || echo "[deploy-dev.sh] Warning: git fetch failed"
  git reset --hard origin/develop 2>/dev/null || echo "[deploy-dev.sh] Warning: git reset failed"

  # docker-compose.dev.yml 복사
  if [[ -f "$COMPOSE_SOURCE" ]]; then
    cp "$COMPOSE_SOURCE" "$COMPOSE_FILE"
    echo "[deploy-dev.sh] docker-compose.dev.yml 업데이트 완료"
  else
    echo "[deploy-dev.sh] Warning: $COMPOSE_SOURCE not found, 기존 파일 사용"
  fi
else
  echo "[deploy-dev.sh] Warning: Git 저장소 없음 ($GIT_REPO), 기존 compose 파일 사용"
fi

# ========================================
# 2. Docker 이미지 Pull 및 재시작 (기존 로직)
# ========================================
echo "[deploy-dev.sh] Docker 이미지 Pull..."
docker compose -p "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull

echo "[deploy-dev.sh] 컨테이너 재시작..."
docker compose -p "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

echo "[deploy-dev.sh] 컨테이너 상태 확인..."
docker compose -p "$PROJECT_NAME" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps

echo "[deploy-dev.sh] 배포 완료!"
