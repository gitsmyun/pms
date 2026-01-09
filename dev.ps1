param(
  [switch]$NoInstall,
  [switch]$NoDb,
  [switch]$NoFrontend
)

# IntelliJ Terminal/PowerShell 출력 인코딩 이슈 완화
try {
  $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
  # ignore
}

$ErrorActionPreference = 'Stop'

function Write-Step([string]$msg) {
  Write-Host "`n==> $msg" -ForegroundColor Cyan
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $NoDb) {
  Write-Step "(DB) Postgres 컨테이너 확인/실행"
  $infraDir = Join-Path $repoRoot 'infra'
  $composeFile = Join-Path $infraDir 'docker-compose.local.yml'

  if (-not (Test-Path $composeFile)) {
    throw "docker-compose.local.yml을 찾을 수 없습니다: $composeFile"
  }

  Push-Location $infraDir
  try {
    docker compose -p localdb -f $composeFile up -d
  } finally {
    Pop-Location
  }
}

if (-not $NoFrontend) {
  Write-Step "(FE) Vite dev 서버 실행 (pnpm dev)"
  $frontendDir = Join-Path $repoRoot 'frontend'

  if (-not (Test-Path (Join-Path $frontendDir 'package.json'))) {
    throw "frontend/package.json을 찾을 수 없습니다: $frontendDir"
  }

  Push-Location $frontendDir
  try {
    if (-not $NoInstall) {
      if (-not (Test-Path (Join-Path $frontendDir 'node_modules'))) {
        Write-Step "(FE) 의존성 설치 (pnpm install)"
        pnpm install
      }
    }

    Write-Step "(FE) 실행: http://localhost:5173 (종료: Ctrl+C)"
    pnpm dev
  } finally {
    Pop-Location
  }
}
