# PMS2.0 환경변수 파일 설정 스크립트
param(
    [ValidateSet('local', 'dev', 'test', 'prod')]
    [string]$Environment = 'dev'
)

# UTF-8 인코딩 설정 (한글 깨짐 방지)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

$envFile = Join-Path $PSScriptRoot "$Environment.env"
$exampleFile = Join-Path $PSScriptRoot "$Environment.env.example"

Write-Host ""
Write-Host "🔧 PMS2.0 환경변수 설정 스크립트" -ForegroundColor Cyan
Write-Host "   환경: $Environment" -ForegroundColor Cyan
Write-Host ""

# 예시 파일 존재 확인
if (!(Test-Path $exampleFile)) {
    Write-Host "❌ 템플릿 파일을 찾을 수 없습니다: $exampleFile" -ForegroundColor Red
    Write-Host "   infra/env/ 디렉터리에 $Environment.env.example 파일이 필요합니다." -ForegroundColor Red
    exit 1
}

# 이미 존재하는 파일 처리
if (Test-Path $envFile) {
    Write-Host "⚠️  환경변수 파일이 이미 존재합니다:" -ForegroundColor Yellow
    Write-Host "   $envFile" -ForegroundColor Yellow
    Write-Host ""

    $overwrite = Read-Host "   덮어쓰시겠습니까? (y/N)"
    if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
        Write-Host ""
        Write-Host "✅ 기존 파일을 유지합니다." -ForegroundColor Green
        Write-Host ""
        Write-Host "📝 Docker Compose 실행:" -ForegroundColor Cyan
        Write-Host "   cd .." -ForegroundColor Yellow
        Write-Host "   docker compose --env-file env\$Environment.env -f docker-compose.$Environment.yml up -d" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }

    # 백업 생성
    $backup = "$envFile.backup." + (Get-Date -Format "yyyyMMdd-HHmmss")
    Copy-Item $envFile $backup
    Write-Host ""
    Write-Host "📦 기존 파일을 백업했습니다: $backup" -ForegroundColor Green
}

# 예시 파일 복사
try {
    Copy-Item $exampleFile $envFile -Force
    Write-Host ""
    Write-Host "✅ 환경변수 파일 생성 완료!" -ForegroundColor Green
    Write-Host "   파일: $envFile" -ForegroundColor Green
    Write-Host ""

    # 다음 단계 안내
    Write-Host "📝 다음 단계:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   1️⃣  환경변수 파일 편집" -ForegroundColor White
    Write-Host "      notepad `"$envFile`"" -ForegroundColor Yellow
    Write-Host "      또는" -ForegroundColor Gray
    Write-Host "      code `"$envFile`"" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   2️⃣  필수 설정 값 입력" -ForegroundColor White
    Write-Host "      - OIDC_ISSUER_URI (SSO 사용 시)" -ForegroundColor Gray
    Write-Host "      - CORS_ALLOWED_ORIGINS (운영 환경)" -ForegroundColor Gray
    Write-Host "      - DB 비밀번호 변경 (운영 환경)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3️⃣  Docker Compose 실행" -ForegroundColor White
    Write-Host "      cd .." -ForegroundColor Yellow
    Write-Host "      docker compose --env-file env\$Environment.env -f docker-compose.$Environment.yml up -d" -ForegroundColor Yellow
    Write-Host ""

    # 환경별 추가 안내
    if ($Environment -eq 'dev') {
        Write-Host "💡 Dev 환경 팁:" -ForegroundColor Cyan
        Write-Host "   - SSO 준비 전: OIDC_ISSUER_URI를 비워두세요 (모든 요청 허용)" -ForegroundColor Gray
        Write-Host "   - Keycloak 사용: http://keycloak:8080/realms/pms" -ForegroundColor Gray
        Write-Host "   - Swagger: 기본 활성화 (SWAGGER_ENABLED_DEV=true)" -ForegroundColor Gray
        Write-Host ""
    }

    if ($Environment -eq 'prod') {
        Write-Host "⚠️  운영 환경 필수 확인사항:" -ForegroundColor Red
        Write-Host "   - OIDC_ISSUER_URI 설정 필수 (SSO 인증)" -ForegroundColor Gray
        Write-Host "   - CORS_ALLOWED_ORIGINS 명시적 설정 필수" -ForegroundColor Gray
        Write-Host "   - DB 비밀번호 강력한 값으로 변경 필수" -ForegroundColor Gray
        Write-Host "   - SWAGGER_ENABLED_DEV=false 설정 필수" -ForegroundColor Gray
        Write-Host ""
    }

} catch {
    Write-Host ""
    Write-Host "❌ 파일 생성 실패: $_" -ForegroundColor Red
    exit 1
}

