param(
  [switch]$KeepVolumes,
  [switch]$RemoveVolumes
)

# IntelliJ Terminal/PowerShell 출력 인코딩 이슈 완화
# - docker/compose 출력은 콘솔 CodePage 영향을 많이 받아서, 가능하면 UTF-8(65001)로 고정합니다.
try {
  # 기존 CodePage 저장 후 복구할 수도 있지만(선택), dev 스크립트 특성상 단순 적용합니다.
  chcp 65001 | Out-Null
} catch {
  # ignore
}

try {
  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  $OutputEncoding = $utf8NoBom
  [Console]::OutputEncoding = $utf8NoBom
  [Console]::InputEncoding  = $utf8NoBom
} catch {
  # ignore
}

$ErrorActionPreference = 'Stop'

function Write-Step([string]$msg) {
  Write-Host "`n==> $msg" -ForegroundColor Cyan
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$infraDir = Join-Path $repoRoot 'infra'
$composeFile = Join-Path $infraDir 'docker-compose.local-db.yml'

if (-not (Test-Path $composeFile)) {
  throw "docker-compose.local-db.yml을 찾을 수 없습니다: $composeFile"
}

Write-Step "(DB) Postgres 컨테이너 중지"
Push-Location $infraDir
try {
  if ($RemoveVolumes) {
    docker compose -p localdb -f $composeFile down -v | Out-Host
  } else {
    # 설명 기본 동작은 로컬 개발 데이터 보존을 위해 볼륨을 유지한다
    docker compose -p localdb -f $composeFile down | Out-Host
  }
} finally {
  Pop-Location
}

Write-Step "완료 (Done)"
