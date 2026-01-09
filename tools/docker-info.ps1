param(
  [string]$ComposeFile,
  [string]$ProjectName
)

# 작성일 2026 01 09
# 작업자 윤성민
# 설명 이 스크립트는 로컬 PC의 Docker Desktop 상태와 현재 실행 중인 컨테이너 포트 매핑을 빠르게 점검하기 위한 진단 도구이다
# 설명 docker 버전 정보 네트워크 볼륨 이미지 목록과 컨테이너 포트 공개 상태를 요약하여 배포 절차 검증 시 충돌 원인을 빠르게 찾는다
# 설명 Compose 파일과 프로젝트 이름을 입력하면 해당 스택의 서비스 상태와 포트도 함께 출력한다
# 설명 본 스크립트는 정보를 조회만 하며 시스템 상태를 변경하지 않는다
# 설명 표준 프로젝트 이름은 pms_local pms_dev pms_test pms_prod 를 권장한다

$ErrorActionPreference = 'Stop'

function Write-Section([string]$title) {
  Write-Host "\n==== $title ====" -ForegroundColor Cyan
}

try {
  $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
}

Write-Section "Docker version"
docker version

docker info | Out-Host

Write-Section "Containers (running)"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | Out-Host

Write-Section "Port map (all containers)"
$all = docker ps -a --format "{{.ID}} {{.Names}}"
foreach ($line in $all) {
  $parts = $line.Split(' ',2)
  if ($parts.Length -lt 2) { continue }
  $id = $parts[0]
  $name = $parts[1]
  $ports = docker port $id 2>$null
  if ($ports) {
    "$name" | Out-Host
    $ports | Out-Host
    "" | Out-Host
  }
}

Write-Section "Docker compose projects"
docker compose ls | Out-Host

if ($ComposeFile) {
  Write-Section "Compose status"
  if (-not (Test-Path $ComposeFile)) {
    throw "compose file not found: $ComposeFile"
  }

  $args = @('-f', $ComposeFile)
  if ($ProjectName) {
    $args += @('-p', $ProjectName)
  }
  docker compose @args ps | Out-Host
}
