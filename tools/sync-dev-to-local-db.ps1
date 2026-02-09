# 개발 서버 DB를 로컬로 동기화 스크립트
# 방안 B: DB Restore 전략

<#
.SYNOPSIS
    개발 서버 PostgreSQL DB를 로컬 환경으로 동기화
.DESCRIPTION
    개발 서버(Kubernetes)의 PMS DB를 덤프하여 로컬 PostgreSQL에 복원합니다.
    로컬 개발 시 개발 서버와 유사한 데이터로 테스트할 수 있습니다.
.PARAMETER IncludeKeycloak
    Keycloak DB도 함께 복원할지 여부 (선택)
.EXAMPLE
    .\tools\sync-dev-to-local-db.ps1
.EXAMPLE
    .\tools\sync-dev-to-local-db.ps1 -IncludeKeycloak
.NOTES
    작성일: 2026-02-09
    전략: 방안 B (DB Restore)
#>

param(
    [switch]$IncludeKeycloak = $false
)

Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║  개발 서버 DB → 로컬 동기화 스크립트                          ║
║  전략: 방안 B (DB Restore)                                    ║
╚═══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n📋 작업 내용:" -ForegroundColor Yellow
Write-Host "  1. 개발 서버 PostgreSQL에서 PMS DB 덤프" -ForegroundColor White
Write-Host "  2. 로컬 PostgreSQL에 복원" -ForegroundColor White
if ($IncludeKeycloak) {
    Write-Host "  3. Keycloak DB도 복원 (선택됨)" -ForegroundColor White
}

$confirm = Read-Host "`n계속하시겠습니까? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "작업을 취소했습니다." -ForegroundColor Yellow
    exit 0
}

# ========================================
# 준비: 백업 디렉토리 생성
# ========================================
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = "C:\backup\db-sync-$timestamp"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

Write-Host "`n백업 디렉토리: $backupDir" -ForegroundColor Gray

# ========================================
# Step 1: 개발 서버에서 PMS DB 덤프
# ========================================
Write-Host "`n=== Step 1: 개발 서버 PMS DB 덤프 ===" -ForegroundColor Cyan

$pmsDumpFile = "$backupDir\pms-dev-dump.sql"

Write-Host "개발 서버 PostgreSQL에서 PMS DB를 덤프합니다..." -ForegroundColor Yellow
Write-Host "  (시간이 걸릴 수 있습니다. 데이터 크기에 따라 1-5분)" -ForegroundColor Gray

try {
    kubectl exec -i postgres-0 -n pms-dev -- pg_dump -U pms -d pms --clean --if-exists > $pmsDumpFile 2>&1

    if (Test-Path $pmsDumpFile) {
        $fileSize = (Get-Item $pmsDumpFile).Length / 1KB
        Write-Host "✅ PMS DB 덤프 완료: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Green
    } else {
        Write-Host "❌ 덤프 파일 생성 실패" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ 덤프 실패: $_" -ForegroundColor Red
    exit 1
}

# ========================================
# Step 2: 로컬 PostgreSQL 컨테이너 확인
# ========================================
Write-Host "`n=== Step 2: 로컬 PostgreSQL 확인 ===" -ForegroundColor Cyan

$localPostgres = docker ps --filter "name=pms-local-postgres" --format "{{.Names}}" 2>$null

if (-not $localPostgres) {
    Write-Host "❌ 로컬 PostgreSQL 컨테이너가 실행 중이지 않습니다." -ForegroundColor Red
    Write-Host "다음 명령어로 시작하세요:" -ForegroundColor Yellow
    Write-Host "  cd infra" -ForegroundColor Cyan
    Write-Host "  docker compose -f docker-compose.local.yml up -d" -ForegroundColor Cyan
    exit 1
}

Write-Host "✅ 로컬 PostgreSQL 컨테이너 확인: $localPostgres" -ForegroundColor Green

# ========================================
# Step 3: 로컬 PMS DB 백업 (안전성)
# ========================================
Write-Host "`n=== Step 3: 로컬 PMS DB 백업 (안전성) ===" -ForegroundColor Cyan

$localBackupFile = "$backupDir\pms-local-backup.sql"

Write-Host "기존 로컬 DB를 백업합니다..." -ForegroundColor Yellow

try {
    docker exec -i pms-local-postgres pg_dump -U pms -d pms > $localBackupFile 2>&1

    if (Test-Path $localBackupFile) {
        $fileSize = (Get-Item $localBackupFile).Length / 1KB
        Write-Host "✅ 로컬 DB 백업 완료: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ 로컬 DB 백업 실패 (DB가 비어있을 수 있음)" -ForegroundColor Yellow
}

# ========================================
# Step 4: 로컬 PMS DB 삭제 및 재생성
# ========================================
Write-Host "`n=== Step 4: 로컬 PMS DB 초기화 ===" -ForegroundColor Cyan

Write-Host "로컬 PMS DB를 삭제하고 재생성합니다..." -ForegroundColor Yellow

try {
    # 기존 연결 종료
    docker exec -i pms-local-postgres psql -U pms -d postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'pms' AND pid <> pg_backend_pid();" 2>&1 | Out-Null

    # DB 삭제
    docker exec -i pms-local-postgres psql -U pms -d postgres -c "DROP DATABASE IF EXISTS pms;" 2>&1 | Out-Null

    # DB 재생성
    docker exec -i pms-local-postgres psql -U pms -d postgres -c "CREATE DATABASE pms OWNER pms;" 2>&1 | Out-Null

    Write-Host "✅ 로컬 PMS DB 초기화 완료" -ForegroundColor Green
} catch {
    Write-Host "❌ DB 초기화 실패: $_" -ForegroundColor Red
    Write-Host "롤백: 백업에서 복원하려면 다음 명령어 실행:" -ForegroundColor Yellow
    Write-Host "  Get-Content $localBackupFile | docker exec -i pms-local-postgres psql -U pms -d pms" -ForegroundColor Cyan
    exit 1
}

# ========================================
# Step 5: 개발 서버 덤프를 로컬에 복원
# ========================================
Write-Host "`n=== Step 5: 개발 서버 덤프를 로컬에 복원 ===" -ForegroundColor Cyan

Write-Host "개발 서버 데이터를 로컬 DB에 복원합니다..." -ForegroundColor Yellow
Write-Host "  (시간이 걸릴 수 있습니다. 데이터 크기에 따라 1-5분)" -ForegroundColor Gray

try {
    Get-Content $pmsDumpFile | docker exec -i pms-local-postgres psql -U pms -d pms 2>&1 | Out-Null

    Write-Host "✅ PMS DB 복원 완료" -ForegroundColor Green
} catch {
    Write-Host "❌ DB 복원 실패: $_" -ForegroundColor Red
    Write-Host "롤백: 백업에서 복원하려면 다음 명령어 실행:" -ForegroundColor Yellow
    Write-Host "  Get-Content $localBackupFile | docker exec -i pms-local-postgres psql -U pms -d pms" -ForegroundColor Cyan
    exit 1
}

# ========================================
# Step 6: 검증
# ========================================
Write-Host "`n=== Step 6: 복원 검증 ===" -ForegroundColor Cyan

Write-Host "`n6-1. 테이블 개수 확인:" -ForegroundColor Yellow
$devTableCount = kubectl exec -i postgres-0 -n pms-dev -- psql -U pms -d pms -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1
$localTableCount = docker exec -i pms-local-postgres psql -U pms -d pms -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1

Write-Host "  개발 서버: $($devTableCount.Trim()) 테이블" -ForegroundColor Gray
Write-Host "  로컬: $($localTableCount.Trim()) 테이블" -ForegroundColor Gray

if ($devTableCount.Trim() -eq $localTableCount.Trim()) {
    Write-Host "  ✅ 테이블 개수 일치!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ 테이블 개수 불일치 (확인 필요)" -ForegroundColor Yellow
}

Write-Host "`n6-2. 주요 테이블 레코드 수 확인:" -ForegroundColor Yellow

# Flyway 히스토리 확인
try {
    $devFlyway = kubectl exec -i postgres-0 -n pms-dev -- psql -U pms -d pms -t -c "SELECT COUNT(*) FROM flyway_schema_history;" 2>&1
    $localFlyway = docker exec -i pms-local-postgres psql -U pms -d pms -t -c "SELECT COUNT(*) FROM flyway_schema_history;" 2>&1

    Write-Host "  Flyway 마이그레이션:" -ForegroundColor Cyan
    Write-Host "    개발 서버: $($devFlyway.Trim())" -ForegroundColor Gray
    Write-Host "    로컬: $($localFlyway.Trim())" -ForegroundColor Gray
} catch {
    Write-Host "  ⚠️ Flyway 테이블 확인 불가" -ForegroundColor Yellow
}

# Project 테이블 확인
try {
    $devProjects = kubectl exec -i postgres-0 -n pms-dev -- psql -U pms -d pms -t -c "SELECT COUNT(*) FROM project;" 2>&1
    $localProjects = docker exec -i pms-local-postgres psql -U pms -d pms -t -c "SELECT COUNT(*) FROM project;" 2>&1

    Write-Host "  프로젝트:" -ForegroundColor Cyan
    Write-Host "    개발 서버: $($devProjects.Trim())" -ForegroundColor Gray
    Write-Host "    로컬: $($localProjects.Trim())" -ForegroundColor Gray
} catch {
    Write-Host "  ⚠️ Project 테이블 확인 불가" -ForegroundColor Yellow
}

# ========================================
# Step 7: Keycloak DB 동기화 (선택)
# ========================================
if ($IncludeKeycloak) {
    Write-Host "`n=== Step 7: Keycloak DB 동기화 (선택) ===" -ForegroundColor Cyan

    Write-Host "⚠️ 주의: 이 작업은 선택 사항입니다." -ForegroundColor Yellow
    Write-Host "  현재는 개발 서버 Keycloak을 사용하고 있으므로 대부분의 경우 불필요합니다." -ForegroundColor Gray

    $keycloakConfirm = Read-Host "계속하시겠습니까? (yes/no)"

    if ($keycloakConfirm -eq "yes") {
        # Keycloak DB 덤프
        $keycloakDumpFile = "$backupDir\keycloak-dev-dump.sql"

        Write-Host "개발 서버 Keycloak DB 덤프..." -ForegroundColor Yellow
        kubectl exec -i postgres-0 -n pms-dev -- pg_dump -U keycloak -d keycloak --clean --if-exists > $keycloakDumpFile 2>&1

        # 로컬에 Keycloak DB 생성 (없으면)
        docker exec -i pms-local-postgres psql -U pms -d postgres -c "CREATE DATABASE keycloak;" 2>&1 | Out-Null
        docker exec -i pms-local-postgres psql -U pms -d postgres -c "CREATE USER keycloak WITH ENCRYPTED PASSWORD 'keycloak123';" 2>&1 | Out-Null
        docker exec -i pms-local-postgres psql -U pms -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;" 2>&1 | Out-Null

        # 복원
        Write-Host "로컬에 Keycloak DB 복원..." -ForegroundColor Yellow
        Get-Content $keycloakDumpFile | docker exec -i pms-local-postgres psql -U keycloak -d keycloak 2>&1 | Out-Null

        Write-Host "✅ Keycloak DB 동기화 완료" -ForegroundColor Green
    }
}

# ========================================
# 완료
# ========================================
Write-Host "`n✅ 모든 작업이 완료되었습니다!" -ForegroundColor Green
Write-Host "백업 위치: $backupDir" -ForegroundColor Gray

Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║  다음 단계                                                    ║
╠═══════════════════════════════════════════════════════════════╣
║  1. 백엔드 재시작 (IntelliJ)                                  ║
║     - PmsBackendApplication 재실행                            ║
║     - 로컬 DB 연결 확인                                       ║
║                                                               ║
║  2. 프론트엔드 재시작                                         ║
║     cd frontend                                               ║
║     pnpm dev                                                  ║
║                                                               ║
║  3. 웹 접속 테스트                                            ║
║     http://localhost:5173                                     ║
║     - Keycloak: 개발 서버 (10.127.6.102) 사용                ║
║     - DB: 로컬 PostgreSQL 사용                                ║
║                                                               ║
║  4. 데이터 확인                                               ║
║     - 개발 서버와 동일한 프로젝트 목록 표시                   ║
║     - testuser로 로그인 가능                                  ║
║                                                               ║
║  5. 주기적 동기화 (필요 시)                                   ║
║     .\tools\sync-dev-to-local-db.ps1                          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n스크립트를 종료합니다." -ForegroundColor Cyan
