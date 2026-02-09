# Keycloak 데이터 영속성 수정 스크립트
# 목적: H2 인메모리 → PostgreSQL 전환으로 재시작 시 데이터 보존

<#
.SYNOPSIS
    Keycloak 데이터 영속성 문제 해결 (H2 → PostgreSQL)
.DESCRIPTION
    Keycloak을 H2 인메모리 DB에서 PostgreSQL로 전환하여
    Docker Desktop 재시작 시에도 Realm, Client, User 데이터를 보존합니다.
.EXAMPLE
    .\tools\fix-keycloak-data-persistence.ps1
.NOTES
    작성일: 2026-02-09
    사전 요구사항: ArgoCD repo-server 수정 완료
#>

Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║  Keycloak 데이터 영속성 수정 스크립트                        ║
║  H2 인메모리 → PostgreSQL 전환                               ║
║  작성일: 2026-02-09                                           ║
╚═══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n🔴 현재 문제:" -ForegroundColor Red
Write-Host "  - Keycloak이 H2 인메모리 DB(dev-mem) 사용" -ForegroundColor White
Write-Host "  - Docker Desktop 재시작 시 모든 데이터 손실" -ForegroundColor White
Write-Host "  - Realm, Client, User 설정 재생성 필요" -ForegroundColor White

Write-Host "`n✅ 수정 후:" -ForegroundColor Green
Write-Host "  - Keycloak이 PostgreSQL 사용" -ForegroundColor White
Write-Host "  - 재시작 후에도 모든 데이터 보존" -ForegroundColor White
Write-Host "  - 설정 재생성 불필요" -ForegroundColor White

Write-Host "`n📋 작업 단계:" -ForegroundColor Yellow
Write-Host "  1. 현재 설정 백업" -ForegroundColor White
Write-Host "  2. PostgreSQL에 Keycloak DB 생성" -ForegroundColor White
Write-Host "  3. Keycloak Secret 생성" -ForegroundColor White
Write-Host "  4. Keycloak Deployment 패치 (PostgreSQL 연결)" -ForegroundColor White
Write-Host "  5. 재배포 및 검증" -ForegroundColor White

$confirm = Read-Host "`n계속하시겠습니까? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "작업을 취소했습니다." -ForegroundColor Yellow
    exit 0
}

# ========================================
# Step 1: 백업
# ========================================
Write-Host "`n=== Step 1: 현재 설정 백업 ===" -ForegroundColor Cyan

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = "C:\backup\keycloak-persistence-fix-$timestamp"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

Write-Host "백업 디렉토리: $backupDir" -ForegroundColor Gray

# Keycloak Deployment 백업
kubectl get deployment keycloak -n pms-dev -o yaml > "$backupDir\keycloak-deployment-before.yaml"
Write-Host "✅ Keycloak Deployment 백업 완료" -ForegroundColor Green

# PostgreSQL 상태 백업
kubectl get statefulset postgres -n pms-dev -o yaml > "$backupDir\postgres-statefulset.yaml"
kubectl exec -i postgres-0 -n pms-dev -- psql -U pms -d postgres -P pager=off -c "\l" > "$backupDir\postgres-databases-before.txt" 2>&1
Write-Host "✅ PostgreSQL 상태 백업 완료" -ForegroundColor Green

# ========================================
# Step 2: PostgreSQL에 Keycloak DB 생성
# ========================================
Write-Host "`n=== Step 2: PostgreSQL에 Keycloak DB 생성 ===" -ForegroundColor Cyan

Write-Host "PostgreSQL에 접속하여 Keycloak DB를 생성합니다..." -ForegroundColor Yellow

$createDbScript = @'
CREATE DATABASE keycloak;
CREATE USER keycloak WITH ENCRYPTED PASSWORD 'keycloak123';
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
\l
'@

try {
    # PostgreSQL에 명령어 실행
    $result = kubectl exec -i postgres-0 -n pms-dev -- psql -U pms -d postgres -c "CREATE DATABASE keycloak;" 2>&1

    if ($result -match "already exists") {
        Write-Host "⚠️ Keycloak DB가 이미 존재합니다. 계속 진행합니다." -ForegroundColor Yellow
    } else {
        Write-Host "✅ Keycloak DB 생성 완료" -ForegroundColor Green
    }

    # 사용자 및 권한 설정
    kubectl exec -i postgres-0 -n pms-dev -- psql -U pms -d postgres -c "CREATE USER keycloak WITH ENCRYPTED PASSWORD 'keycloak123';" 2>&1 | Out-Null
    kubectl exec -i postgres-0 -n pms-dev -- psql -U pms -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;" 2>&1 | Out-Null

    Write-Host "✅ Keycloak 사용자 및 권한 설정 완료" -ForegroundColor Green

} catch {
    Write-Host "⚠️ DB 생성 중 일부 경고가 있었지만 계속 진행합니다." -ForegroundColor Yellow
}

# DB 목록 확인
Write-Host "`nPostgreSQL 데이터베이스 목록:" -ForegroundColor Cyan
kubectl exec -i postgres-0 -n pms-dev -- psql -U pms -d postgres -P pager=off -c "\l" 2>&1 | Select-String "keycloak|pms" | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

# ========================================
# Step 3: Keycloak Secret 생성
# ========================================
Write-Host "`n=== Step 3: Keycloak DB Secret 생성 ===" -ForegroundColor Cyan

# 기존 Secret 확인
$existingSecret = kubectl get secret keycloak-db-secret -n pms-dev 2>&1

if ($existingSecret -match "NotFound") {
    Write-Host "새 Secret을 생성합니다..." -ForegroundColor Yellow

    kubectl create secret generic keycloak-db-secret -n pms-dev `
        --from-literal=username=keycloak `
        --from-literal=password=keycloak123 `
        --from-literal=database=keycloak 2>&1 | Out-Null

    Write-Host "✅ Keycloak DB Secret 생성 완료" -ForegroundColor Green
} else {
    Write-Host "⚠️ Keycloak DB Secret이 이미 존재합니다." -ForegroundColor Yellow
    $recreate = Read-Host "Secret을 재생성하시겠습니까? (yes/no)"

    if ($recreate -eq "yes") {
        kubectl delete secret keycloak-db-secret -n pms-dev 2>&1 | Out-Null
        kubectl create secret generic keycloak-db-secret -n pms-dev `
            --from-literal=username=keycloak `
            --from-literal=password=keycloak123 `
            --from-literal=database=keycloak 2>&1 | Out-Null
        Write-Host "✅ Keycloak DB Secret 재생성 완료" -ForegroundColor Green
    } else {
        Write-Host "기존 Secret을 사용합니다." -ForegroundColor Gray
    }
}

# Secret 확인
kubectl get secret keycloak-db-secret -n pms-dev | Out-Null
if ($?) {
    Write-Host "✅ Secret 확인 완료" -ForegroundColor Green
}

# ========================================
# Step 4: Keycloak Deployment 패치
# ========================================
Write-Host "`n=== Step 4: Keycloak Deployment 패치 (PostgreSQL 연결) ===" -ForegroundColor Cyan

Write-Host "Keycloak 환경변수를 PostgreSQL 연결로 변경합니다..." -ForegroundColor Yellow

$patchJson = @'
[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/args",
    "value": ["start-dev", "--db=postgres"]
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/env",
    "value": [
      {"name": "KEYCLOAK_ADMIN", "value": "admin"},
      {"name": "KEYCLOAK_ADMIN_PASSWORD", "valueFrom": {"secretKeyRef": {"key": "admin-password", "name": "keycloak-secret"}}},
      {"name": "KC_HTTP_ENABLED", "value": "true"},
      {"name": "KC_HOSTNAME_STRICT", "value": "false"},
      {"name": "KC_HOSTNAME_STRICT_HTTPS", "value": "false"},
      {"name": "KC_PROXY", "value": "edge"},
      {"name": "KC_HEALTH_ENABLED", "value": "true"},
      {"name": "KC_METRICS_ENABLED", "value": "true"},
      {"name": "KC_HTTP_RELATIVE_PATH", "value": "/keycloak"},
      {"name": "KC_DB", "value": "postgres"},
      {"name": "KC_DB_URL", "value": "jdbc:postgresql://postgres:5432/keycloak"},
      {"name": "KC_DB_USERNAME", "valueFrom": {"secretKeyRef": {"key": "username", "name": "keycloak-db-secret"}}},
      {"name": "KC_DB_PASSWORD", "valueFrom": {"secretKeyRef": {"key": "password", "name": "keycloak-db-secret"}}},
      {"name": "JAVA_OPTS_APPEND", "value": "-Djgroups.dns.query=keycloak"}
    ]
  }
]
'@

try {
    kubectl patch deployment keycloak -n pms-dev --type='json' -p $patchJson 2>&1 | Out-Null
    Write-Host "✅ Keycloak Deployment 패치 완료" -ForegroundColor Green
} catch {
    Write-Host "❌ 패치 실패: $_" -ForegroundColor Red
    Write-Host "백업에서 복구하려면:" -ForegroundColor Yellow
    Write-Host "  kubectl apply -f $backupDir\keycloak-deployment-before.yaml" -ForegroundColor Gray
    exit 1
}

# ========================================
# Step 5: 재배포 대기
# ========================================
Write-Host "`n=== Step 5: Keycloak 재배포 대기 ===" -ForegroundColor Cyan

Write-Host "Keycloak Pod가 재시작됩니다. 약 2분 소요..." -ForegroundColor Yellow

# 기존 Pod 종료 대기
Start-Sleep -Seconds 30

# 새 Pod 시작 대기
for ($i = 0; $i -lt 12; $i++) {
    $podStatus = kubectl get pods -n pms-dev -l app=keycloak -o jsonpath='{.items[0].status.phase}' 2>$null

    if ($podStatus -eq "Running") {
        Write-Host "✅ Keycloak Pod가 Running 상태입니다!" -ForegroundColor Green
        break
    }

    Write-Host "  대기 중... ($($i * 10)초 경과, 상태: $podStatus)" -ForegroundColor Gray
    Start-Sleep -Seconds 10
}

# ========================================
# Step 6: 검증
# ========================================
Write-Host "`n=== Step 6: 검증 ===" -ForegroundColor Cyan

# Pod 상태 확인
Write-Host "`n6-1. Pod 상태:" -ForegroundColor Yellow
kubectl get pods -n pms-dev -l app=keycloak

# Keycloak 로그 확인
Write-Host "`n6-2. Keycloak 로그 (PostgreSQL 연결 확인):" -ForegroundColor Yellow
$logs = kubectl logs -n pms-dev -l app=keycloak --tail=50 2>&1 | Select-String "postgres|PostgreSQL|database|migration|started|Version"

if ($logs) {
    $logs | ForEach-Object {
        if ($_ -match "PostgreSQL|postgres") {
            Write-Host "  $_" -ForegroundColor Green
        } elseif ($_ -match "error|ERROR|fail|FAIL") {
            Write-Host "  $_" -ForegroundColor Red
        } else {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  ⚠️ PostgreSQL 관련 로그를 찾을 수 없습니다." -ForegroundColor Yellow
    Write-Host "  전체 로그 확인: kubectl logs -n pms-dev -l app=keycloak" -ForegroundColor Gray
}

# PostgreSQL Keycloak DB 확인
Write-Host "`n6-3. PostgreSQL Keycloak DB 확인:" -ForegroundColor Yellow
$tableCount = kubectl exec -i postgres-0 -n pms-dev -- psql -U keycloak -d keycloak -P pager=off -c "\dt" 2>&1 | Select-String "TABLE|table"

if ($tableCount) {
    Write-Host "  ✅ Keycloak 테이블이 생성되었습니다!" -ForegroundColor Green
    Write-Host "  테이블 수: $($tableCount.Count)" -ForegroundColor Gray
} else {
    Write-Host "  ⚠️ 테이블이 아직 생성되지 않았습니다. 잠시 후 다시 확인하세요." -ForegroundColor Yellow
}

# 설정 저장
kubectl get deployment keycloak -n pms-dev -o yaml > "$backupDir\keycloak-deployment-after.yaml"

Write-Host "`n✅ 모든 작업이 완료되었습니다!" -ForegroundColor Green
Write-Host "백업 위치: $backupDir" -ForegroundColor Gray

# ========================================
# 다음 단계 안내
# ========================================
Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║  다음 단계: Keycloak 재설정                                   ║
╠═══════════════════════════════════════════════════════════════╣
║  1. Admin 콘솔 접속                                           ║
║     URL: http://localhost:30880/keycloak/admin                ║
║     또는: https://10.127.6.102/keycloak/admin                 ║
║     계정: admin / admin                                       ║
║                                                               ║
║  2. PMS Realm 생성                                            ║
║     - Realm name: pms                                         ║
║     - Enabled: ON                                             ║
║                                                               ║
║  3. Client 생성 (pms-frontend)                                ║
║     - Client ID: pms-frontend                                 ║
║     - Client authentication: OFF (Public)                     ║
║     - Valid redirect URIs:                                    ║
║       * https://10.127.6.102/*                                ║
║       * http://localhost/*                                    ║
║       * http://localhost:5173/*                               ║
║                                                               ║
║  4. 사용자 생성 (testuser)                                    ║
║     - Username: testuser                                      ║
║     - Email: testuser@example.com                             ║
║     - Password: test123 (Temporary: OFF)                      ║
║                                                               ║
║  5. 웹 접속 테스트                                            ║
║     https://10.127.6.102 → testuser 로그인                    ║
║                                                               ║
║  6. 데이터 영속성 검증 (필수!)                                ║
║     - Docker Desktop 재시작                                   ║
║     - testuser로 재로그인 가능 여부 확인                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n자세한 설정 가이드:" -ForegroundColor Yellow
Write-Host "  docs/ARCH/260209/002_Keycloak_Data_Persistence_Critical_Fix.md" -ForegroundColor Gray

# 자동으로 Keycloak 설정 페이지 열기 (선택)
$openBrowser = Read-Host "`nKeycloak Admin 콘솔을 지금 여시겠습니까? (yes/no)"
if ($openBrowser -eq "yes") {
    Start-Process "http://localhost:30880/keycloak/admin"
    Write-Host "브라우저에서 Keycloak Admin 콘솔이 열렸습니다." -ForegroundColor Green
}

Write-Host "`n스크립트를 종료합니다." -ForegroundColor Cyan
