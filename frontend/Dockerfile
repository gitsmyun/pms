# 작성일 2026 01 08
# 수정일 2026 01 15 - pnpm 기반으로 변경 (로컬 환경과 일치)
# 작업자 윤성민
# 설명 이 파일은 프론트엔드 정적 산출물을 빌드하고 Nginx로 서빙하는 컨테이너 이미지를 만들기 위한 도커파일이다
# 설명 빌드 단계는 노드 환경에서 의존성을 설치하고 정적 빌드를 생성한다
# 설명 런타임 단계는 Nginx 경량 이미지를 사용하여 쿠버네티스에서 안정적으로 정적 파일을 제공한다
# 설명 단일 이미지로 프론트 배포 단위를 고정하여 Ingress에서 루트 경로는 프론트로 API 경로는 백엔드로 라우팅하기 쉽다
# 설명 로컬 개발 환경과 일치시키기 위해 pnpm을 사용하며 pnpm-lock.yaml을 통해 정확한 의존성 재현성을 보장한다

# syntax=docker/dockerfile:1

FROM node:20-alpine AS build
WORKDIR /app

# ARG로 빌드 타임 환경변수 주입
ARG VITE_KEYCLOAK_URL
ENV VITE_KEYCLOAK_URL=${VITE_KEYCLOAK_URL}

# pnpm 활성화 (Node.js 16.13+ Corepack 포함)
RUN corepack enable && corepack prepare pnpm@10.27.0 --activate

# 의존성 파일 복사 (캐싱 최적화)
COPY package.json pnpm-lock.yaml ./

# 의존성 설치 (frozen-lockfile로 정확한 버전 보장)
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build

FROM nginx:1.27-alpine

# ARG로 Nginx 설정 선택 (기본값: K8s용)
ARG NGINX_CONF=nginx-k8s.conf

# 설정 파일 복사
COPY ${NGINX_CONF} /etc/nginx/conf.d/default.conf

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80 443
