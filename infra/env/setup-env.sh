#!/bin/bash
# PMS2.0 환경변수 파일 설정 스크립트

set -e

# UTF-8 인코딩 설정 (한글 깨짐 방지)
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

ENV=${1:-dev}

# 환경 검증
if [[ ! "$ENV" =~ ^(local|dev|test|prod)$ ]]; then
    echo -e "${RED}❌ 잘못된 환경: $ENV${NC}"
    echo "사용법: ./setup-env.sh [local|dev|test|prod]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/$ENV.env"
EXAMPLE_FILE="$SCRIPT_DIR/$ENV.env.example"

echo ""
echo -e "${CYAN}🔧 PMS2.0 환경변수 설정 스크립트${NC}"
echo -e "${CYAN}   환경: $ENV${NC}"
echo ""

# 예시 파일 존재 확인
if [ ! -f "$EXAMPLE_FILE" ]; then
    echo -e "${RED}❌ 템플릿 파일을 찾을 수 없습니다: $EXAMPLE_FILE${NC}"
    echo -e "${RED}   infra/env/ 디렉터리에 $ENV.env.example 파일이 필요합니다.${NC}"
    exit 1
fi

# 이미 존재하는 파일 처리
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  환경변수 파일이 이미 존재합니다:${NC}"
    echo -e "${YELLOW}   $ENV_FILE${NC}"
    echo ""

    read -p "   덮어쓰시겠습니까? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${GREEN}✅ 기존 파일을 유지합니다.${NC}"
        echo ""
        echo -e "${CYAN}📝 Docker Compose 실행:${NC}"
        echo -e "${YELLOW}   cd ..${NC}"
        echo -e "${YELLOW}   docker compose --env-file env/$ENV.env -f docker-compose.$ENV.yml up -d${NC}"
        echo ""
        exit 0
    fi

    # 백업 생성
    BACKUP="$ENV_FILE.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$ENV_FILE" "$BACKUP"
    echo ""
    echo -e "${GREEN}📦 기존 파일을 백업했습니다: $BACKUP${NC}"
fi

# 예시 파일 복사
cp "$EXAMPLE_FILE" "$ENV_FILE"
chmod 600 "$ENV_FILE"  # 보안: 소유자만 읽기/쓰기

echo ""
echo -e "${GREEN}✅ 환경변수 파일 생성 완료!${NC}"
echo -e "${GREEN}   파일: $ENV_FILE${NC}"
echo ""

# 다음 단계 안내
echo -e "${CYAN}📝 다음 단계:${NC}"
echo ""
echo -e "   ${NC}1️⃣  환경변수 파일 편집${NC}"
echo -e "${YELLOW}      vi \"$ENV_FILE\"${NC}"
echo -e "${GRAY}      또는${NC}"
echo -e "${YELLOW}      nano \"$ENV_FILE\"${NC}"
echo ""
echo -e "   ${NC}2️⃣  필수 설정 값 입력${NC}"
echo -e "${GRAY}      - OIDC_ISSUER_URI (SSO 사용 시)${NC}"
echo -e "${GRAY}      - CORS_ALLOWED_ORIGINS (운영 환경)${NC}"
echo -e "${GRAY}      - DB 비밀번호 변경 (운영 환경)${NC}"
echo ""
echo -e "   ${NC}3️⃣  Docker Compose 실행${NC}"
echo -e "${YELLOW}      cd ..${NC}"
echo -e "${YELLOW}      docker compose --env-file env/$ENV.env -f docker-compose.$ENV.yml up -d${NC}"
echo ""

# 환경별 추가 안내
if [ "$ENV" = "dev" ]; then
    echo -e "${CYAN}💡 Dev 환경 팁:${NC}"
    echo -e "${GRAY}   - SSO 준비 전: OIDC_ISSUER_URI를 비워두세요 (모든 요청 허용)${NC}"
    echo -e "${GRAY}   - Keycloak 사용: http://keycloak:8080/realms/pms${NC}"
    echo -e "${GRAY}   - Swagger: 기본 활성화 (SWAGGER_ENABLED_DEV=true)${NC}"
    echo ""
fi

if [ "$ENV" = "prod" ]; then
    echo -e "${RED}⚠️  운영 환경 필수 확인사항:${NC}"
    echo -e "${GRAY}   - OIDC_ISSUER_URI 설정 필수 (SSO 인증)${NC}"
    echo -e "${GRAY}   - CORS_ALLOWED_ORIGINS 명시적 설정 필수${NC}"
    echo -e "${GRAY}   - DB 비밀번호 강력한 값으로 변경 필수${NC}"
    echo -e "${GRAY}   - SWAGGER_ENABLED_DEV=false 설정 필수${NC}"
    echo ""
fi

