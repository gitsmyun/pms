# 환경변수 관리 가이드

## 개요
이 디렉터리는 환경별 설정 파일을 관리합니다.

## 파일 구조
- `.env.example`: 템플릿 파일 (Git 추적)
- `.env.dev`: 개발 환경 설정 (Git 무시)
- `.env.staging`: 시험 환경 설정 (Git 무시)
- `.env.prod`: 운영 환경 설정 (Git 무시)

## 사용 방법
1. `.env.example`을 복사하여 `.env.{환경}` 파일 생성
2. 각 환경에 맞는 값으로 수정
3. Docker Compose 또는 Kubernetes Secret으로 주입

## 주의사항
- `.env.*` 파일은 절대 Git에 커밋하지 마세요
- 민감한 정보(비밀번호, Token 등)는 반드시 암호화하세요
