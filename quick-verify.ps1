Write-Host "PMS2.0 Quick Verify" -ForegroundColor Cyan
Write-Host ""
Write-Host "[1/5] Docker..."
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "  Not Running" -ForegroundColor Red
    }
} catch {
    Write-Host "  Not Found" -ForegroundColor Red
}
Write-Host "[2/5] PostgreSQL..."
$pg = docker ps --filter "name=pms-postgres" --format "{{.Names}}" 2>$null
if ($pg) {
    Write-Host "  OK" -ForegroundColor Green
} else {
    Write-Host "  Not Running" -ForegroundColor Yellow
}
Write-Host "[3/5] Java..."
try {
    $v = java -version 2>&1 | Out-String
    if ($v -match "21") {
        Write-Host "  OK Java 21" -ForegroundColor Green
    } else {
        Write-Host "  Check Version" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Not Found" -ForegroundColor Red
}
Write-Host "[4/5] Node.js..."
try {
    $v = node -v
    Write-Host "  OK $v" -ForegroundColor Green
} catch {
    Write-Host "  Not Found" -ForegroundColor Red
}
Write-Host "[5/5] pnpm..."
try {
    $v = pnpm -v
    Write-Host "  OK v$v" -ForegroundColor Green
} catch {
    Write-Host "  Not Found" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. DB: cd infra; docker compose -f docker-compose.local.yml up -d"
Write-Host "2. Backend: Run in IntelliJ"
Write-Host "3. Frontend: cd frontend; pnpm dev"

