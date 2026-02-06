#!/usr/bin/env pwsh
# 작성일: 2026-02-06
# 작업자: GitHub Copilot
# 설명: Windows docs/FILE의 수정된 파일들을 WSL Ubuntu 경로로 복사

$ErrorActionPreference = "Stop"

$SOURCE_DIR = "C:\intelliJ\git\pms\docs\FILE"
$WSL_BASE = "\\wsl.localhost\Ubuntu-22.04\opt\pms\dev"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Ubuntu 파일 업데이트 스크립트" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 파일 매핑 (Windows -> Ubuntu)
$fileMappings = @{
    "docker-compose.dev.yml" = "$WSL_BASE\compose\docker-compose.dev.yml"
    ".env.dev" = "$WSL_BASE\env\.env.dev"
    "deploy-dev.sh" = "$WSL_BASE\scripts\deploy-dev.sh"
}

foreach ($file in $fileMappings.Keys) {
    $source = Join-Path $SOURCE_DIR $file
    $dest = $fileMappings[$file]

    Write-Host "📋 복사 중: $file" -ForegroundColor Yellow
    Write-Host "   원본: $source" -ForegroundColor Gray
    Write-Host "   대상: $dest" -ForegroundColor Gray

    if (Test-Path $source) {
        try {
            Copy-Item -Path $source -Destination $dest -Force
            Write-Host "   ✅ 성공" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ 실패: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "   ⚠️  원본 파일 없음" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  완료!" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 명령어로 Docker Compose 컨테이너 정리:" -ForegroundColor Yellow
Write-Host "  docker stop pms-dev-keycloak 2>&1 | Out-Null" -ForegroundColor Cyan
Write-Host "  docker rm pms-dev-keycloak 2>&1 | Out-Null" -ForegroundColor Cyan
Write-Host ""
