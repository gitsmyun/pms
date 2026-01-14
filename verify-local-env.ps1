Write-Host "PMS2.0 Environment Verification" -ForegroundColor Cyan
Write-Host ""
$allOk = $true
Write-Host "[1/7] Docker..."
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "  Not Running" -ForegroundColor Red
        $allOk = $false
    }
} catch {
    Write-Host "  Not Found" -ForegroundColor Red
    $allOk = $false
}
Write-Host "[2/7] PostgreSQL..."
$pg = docker ps --filter "name=pms-postgres" --format "{{.Names}}" 2>$null
if ($pg) {
    Write-Host "  OK" -ForegroundColor Green
} else {
    Write-Host "  Not Running" -ForegroundColor Yellow
    Write-Host "       Start: cd infra; docker compose -f docker-compose.local.yml up -d" -ForegroundColor Gray
}
Write-Host "[3/7] Java..."
try {
    $v = java -version 2>&1 | Out-String
    if ($v -match "21") {
        Write-Host "  OK Java 21" -ForegroundColor Green
    } else {
        Write-Host "  Check Version" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Not Found" -ForegroundColor Red
    $allOk = $false
}
Write-Host "[4/7] Node.js..."
try {
    $v = node -v
    Write-Host "  OK $v" -ForegroundColor Green
} catch {
    Write-Host "  Not Found" -ForegroundColor Red
    $allOk = $false
}
Write-Host "[5/7] pnpm..."
try {
    $v = pnpm -v
    Write-Host "  OK v$v" -ForegroundColor Green
} catch {
    Write-Host "  Not Found (npm install -g pnpm)" -ForegroundColor Yellow
}
Write-Host "[6/7] Backend Build..."
Push-Location c:\intelliJ\git\pms\backend\pms-backend
try {
    Write-Host "  Building... (may take 1 minute)" -ForegroundColor Gray
    $out = .\gradlew build -x test --console=plain 2>&1 | Out-String
    if ($out -match "BUILD SUCCESSFUL") {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "  Failed" -ForegroundColor Red
        $allOk = $false
    }
} catch {
    Write-Host "  Error" -ForegroundColor Red
    $allOk = $false
} finally {
    Pop-Location
}
Write-Host "[7/7] Frontend..."
if (Test-Path "c:\intelliJ\git\pms\frontend\node_modules") {
    Write-Host "  OK" -ForegroundColor Green
} else {
    Write-Host "  Not Installed (cd frontend; pnpm install)" -ForegroundColor Yellow
}
Write-Host ""
if ($allOk) {
    Write-Host "SUCCESS: All checks passed!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Some checks failed" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. DB: cd infra; docker compose -f docker-compose.local.yml up -d"
Write-Host "2. Backend: Run PmsBackendApplication in IntelliJ"
Write-Host "3. Frontend: cd frontend; pnpm dev"
Write-Host ""
Write-Host "Guide: docs/021_LOCAL_DEVELOPMENT_GUIDE.md"

