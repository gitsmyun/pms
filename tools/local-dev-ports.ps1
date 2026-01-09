param(
  [int]$BackendPort = 8080,
  [int]$VitePort = 5173,
  [int]$DbPort = 5432
)

# 작성일 2026 01 09
# 작업자 윤성민
# 설명 이 스크립트는 로컬 개발 시 IntelliJ 백엔드 포트와 Vite 개발 서버 포트 그리고 DB 포트의 충돌 여부를 빠르게 확인한다
# 설명 Docker Desktop 환경에서는 컨테이너 포트 점유도 호스트 포트 점유로 보이므로 netstat 기반으로 검사한다
# 설명 충돌이 있으면 어떤 PID가 점유 중인지 출력하여 어떤 컨테이너나 프로세스를 내려야 하는지 판단할 수 있게 한다

$ErrorActionPreference = 'Stop'

function CheckPort([int]$port, [string]$name) {
  Write-Host "\n==== $name port $port ====" -ForegroundColor Cyan
  $rows = netstat -ano | Select-String (":" + $port + "\s")
  if (-not $rows) {
    Write-Host "free" -ForegroundColor Green
    return
  }
  $rows | ForEach-Object { $_.Line } | Out-Host
  $procIds = @()
  foreach ($r in $rows) {
    $parts = ($r.Line -split "\s+") | Where-Object { $_ -ne '' }
    if ($parts.Length -gt 0) {
      $procIdStr = $parts[-1]
      if ($procIdStr -match '^\d+$') { $procIds += [int]$procIdStr }
    }
  }
  $procIds = $procIds | Sort-Object -Unique
  foreach ($procId in $procIds) {
    Write-Host "PID $procId" -ForegroundColor Yellow
    tasklist /fi "PID eq $procId" | Out-Host
  }
}

CheckPort -port $DbPort -name "Local DB"
CheckPort -port $BackendPort -name "IntelliJ backend"
CheckPort -port $VitePort -name "Vite dev"
