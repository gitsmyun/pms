param(
  [string]$ComposeFile = "infra/docker-compose.dev.yml",
  [string]$EnvFile = "infra/.env.dev",
  [string]$ProjectName = "pms_dev",
  [switch]$Pull,
  [switch]$Up,
  [switch]$Status
)

# 작성일 2026 01 12
# 작업자 윤성민 책임
# 설명 이 스크립트는 PMS2 dev 서버 배포를 위해 docker compose pull 및 up -d를 수행한다
# 설명 기본 동작은 현재 위치가 저장소 루트라고 가정하고 infra/docker-compose.dev.yml을 사용한다
# 설명 EnvFile로 이미지 태그와 포트 그리고 DB 초기값을 주입하여 동일 이미지 승격 원칙을 유지한다
# 설명 Pull Up Status 옵션을 조합하여 수동 강제 배포와 상태 점검을 반복 가능하게 한다
# 설명 이 스크립트는 로컬 PC 또는 Windows 상의 WSL 환경에서 dev 서버 절차를 검증할 때도 재사용할 수 있다

$ErrorActionPreference = 'Stop'

function Write-Step([string]$msg) {
  Write-Host "`n==> $msg" -ForegroundColor Cyan
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$composePath = (Join-Path $repoRoot $ComposeFile)
$envPath = (Join-Path $repoRoot $EnvFile)

if (-not (Test-Path $composePath)) {
  throw "compose file not found: $composePath"
}
if (-not (Test-Path $envPath)) {
  throw "env file not found: $envPath  예시 템플릿은 infra/.env.dev.example 이다"
}

Write-Step "Compose 파일과 env 파일 확인"
Write-Host "compose: $composePath"
Write-Host "env:     $envPath"
Write-Host "project: $ProjectName"

$commonArgs = @('-p', $ProjectName, '--env-file', $envPath, '-f', $composePath)

if ($Status) {
  Write-Step "상태 확인 docker compose ps"
  docker compose @commonArgs ps | Out-Host
}

if ($Pull) {
  Write-Step "이미지 pull"
  docker compose @commonArgs pull | Out-Host
}

if ($Up) {
  Write-Step "적용 docker compose up -d"
  docker compose @commonArgs up -d | Out-Host
}

if (-not ($Pull -or $Up -or $Status)) {
  Write-Step "기본 동작 Status Pull Up"
  docker compose @commonArgs ps | Out-Host
  docker compose @commonArgs pull | Out-Host
  docker compose @commonArgs up -d | Out-Host
  docker compose @commonArgs ps | Out-Host
}
