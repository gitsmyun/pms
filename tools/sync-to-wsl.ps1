# WSL Ubuntu 개발 서버 동기화 스크립트
# 작성일: 2026-02-02
# 작업자: AI Assistant
# 설명: Git 레포의 파일을 WSL Ubuntu 개발 서버로 동기화

param(
    [switch]$Compose,
    [switch]$Env,
    [switch]$Scripts,
    [switch]$All,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# 경로 설정
$WSL_BASE = "\\wsl.localhost\Ubuntu-22.04\opt\pms\dev"
$REPO_BASE = Split-Path -Parent $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WSL 개발 서버 동기화 스크립트" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# WSL 경로 존재 확인
if (-not (Test-Path $WSL_BASE)) {
    Write-Host "❌ WSL 경로를 찾을 수 없습니다: $WSL_BASE" -ForegroundColor Red
    Write-Host ""
    Write-Host "확인 사항:" -ForegroundColor Yellow
    Write-Host "  1. WSL Ubuntu 22.04가 설치되어 있나요?" -ForegroundColor White
    Write-Host "  2. /opt/pms/dev 디렉터리가 생성되어 있나요?" -ForegroundColor White
    Write-Host ""
    exit 1
}

function Sync-Compose {
    $source = Join-Path $REPO_BASE "infra\docker-compose.dev.yml"
    $dest = Join-Path $WSL_BASE "compose\docker-compose.dev.yml"

    Write-Host "[1/3] docker-compose.dev.yml 동기화..." -ForegroundColor Cyan

    if (-not (Test-Path $source)) {
        Write-Host "  ❌ 소스 파일 없음: $source" -ForegroundColor Red
        return
    }

    if ($DryRun) {
        Write-Host "  [DRY-RUN] $source" -ForegroundColor Yellow
        Write-Host "         → $dest" -ForegroundColor Yellow
    } else {
        Copy-Item $source $dest -Force
        Write-Host "  ✅ 복사 완료" -ForegroundColor Green
    }
}

function Sync-Env {
    $source = Join-Path $REPO_BASE "infra\env\.env.dev"
    $dest = Join-Path $WSL_BASE "env\.env.dev"

    Write-Host "[2/3] .env.dev 동기화..." -ForegroundColor Cyan

    if (-not (Test-Path $source)) {
        Write-Host "  ⚠️  소스 파일 없음: $source" -ForegroundColor Yellow
        Write-Host "  → .env.dev는 Git에 커밋되지 않을 수 있습니다." -ForegroundColor Gray
        return
    }

    if ($DryRun) {
        Write-Host "  [DRY-RUN] $source" -ForegroundColor Yellow
        Write-Host "         → $dest" -ForegroundColor Yellow
    } else {
        Copy-Item $source $dest -Force
        Write-Host "  ✅ 복사 완료" -ForegroundColor Green
    }
}

function Sync-Scripts {
    $source = Join-Path $REPO_BASE "tools\deploy-dev.sh"
    $dest = Join-Path $WSL_BASE "scripts\deploy-dev.sh"

    Write-Host "[3/3] deploy-dev.sh 동기화..." -ForegroundColor Cyan

    if (-not (Test-Path $source)) {
        Write-Host "  ❌ 소스 파일 없음: $source" -ForegroundColor Red
        return
    }

    if ($DryRun) {
        Write-Host "  [DRY-RUN] $source" -ForegroundColor Yellow
        Write-Host "         → $dest" -ForegroundColor Yellow
    } else {
        Copy-Item $source $dest -Force
        Write-Host "  ✅ 복사 완료" -ForegroundColor Green
    }
}

# 파라미터 없으면 도움말 표시
if (-not ($Compose -or $Env -or $Scripts -or $All)) {
    Write-Host "사용법:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  .\sync-to-wsl.ps1 -Compose      # docker-compose.dev.yml만 동기화" -ForegroundColor White
    Write-Host "  .\sync-to-wsl.ps1 -Env          # .env.dev만 동기화" -ForegroundColor White
    Write-Host "  .\sync-to-wsl.ps1 -Scripts      # deploy-dev.sh만 동기화" -ForegroundColor White
    Write-Host "  .\sync-to-wsl.ps1 -All          # 모두 동기화" -ForegroundColor White
    Write-Host "  .\sync-to-wsl.ps1 -All -DryRun  # 실행 없이 확인만" -ForegroundColor White
    Write-Host ""
    Write-Host "예시:" -ForegroundColor Yellow
    Write-Host "  # docker-compose.dev.yml 수정 후" -ForegroundColor Gray
    Write-Host "  .\sync-to-wsl.ps1 -Compose" -ForegroundColor White
    Write-Host ""
    Write-Host "  # .env.dev 수정 후" -ForegroundColor Gray
    Write-Host "  .\sync-to-wsl.ps1 -Env" -ForegroundColor White
    Write-Host ""
    Write-Host "  # 여러 파일 수정 후" -ForegroundColor Gray
    Write-Host "  .\sync-to-wsl.ps1 -All" -ForegroundColor White
    Write-Host ""
    exit 0
}

# 동기화 실행
if ($DryRun) {
    Write-Host "⚠️  DRY-RUN 모드: 실제 복사하지 않고 확인만 합니다." -ForegroundColor Yellow
    Write-Host ""
}

if ($All) {
    Sync-Compose
    Sync-Env
    Sync-Scripts
} else {
    if ($Compose) { Sync-Compose }
    if ($Env) { Sync-Env }
    if ($Scripts) { Sync-Scripts }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "  DRY-RUN 완료" -ForegroundColor Yellow
} else {
    Write-Host "  동기화 완료!" -ForegroundColor Green
    Write-Host ""
    Write-Host "다음 단계:" -ForegroundColor Yellow
    Write-Host "  1. WSL Ubuntu 접속:" -ForegroundColor White
    Write-Host "     wsl -d Ubuntu-22.04" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. 컨테이너 재시작:" -ForegroundColor White
    Write-Host "     cd /opt/pms/dev/compose" -ForegroundColor Gray
    Write-Host "     docker compose --env-file ../env/.env.dev -f docker-compose.dev.yml restart" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. 상태 확인:" -ForegroundColor White
    Write-Host "     docker compose ps" -ForegroundColor Gray
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
