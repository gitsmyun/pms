# GitHub Actions 워크플로우 모니터링 및 배포 스크립트
# 작성일: 2026-01-16
# 설명: CI 빌드 완료 후 개발 서버에 자동 배포

param(
    [string]$RepoOwner = "gitsmyun",
    [string]$RepoName = "pms",
    [int]$WaitSeconds = 300  # 최대 5분 대기
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   GitHub Actions Workflow Monitor & Deploy" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

Write-Host "`n[Step 1] Checking latest commit..." -ForegroundColor Yellow
$latestCommit = git log --oneline -1
Write-Host "Latest commit: $latestCommit" -ForegroundColor Green

Write-Host "`n[Step 2] GitHub Actions URL:" -ForegroundColor Yellow
$actionsUrl = "https://github.com/$RepoOwner/$RepoName/actions"
Write-Host "$actionsUrl" -ForegroundColor Blue
Write-Host "`nPlease check the workflow status at the above URL" -ForegroundColor Magenta

Write-Host "`n[Step 3] Waiting for CI build to complete..." -ForegroundColor Yellow
Write-Host "This usually takes 3-5 minutes" -ForegroundColor Gray
Write-Host "You can skip this wait and deploy manually later" -ForegroundColor Gray

$choice = Read-Host "`nDo you want to wait for CI completion? (y/N)"

if ($choice -eq 'y' -or $choice -eq 'Y') {
    Write-Host "`nWaiting for up to $($WaitSeconds/60) minutes..." -ForegroundColor Cyan
    Write-Host "Tip: You can manually check: $actionsUrl" -ForegroundColor Gray

    # 간단한 대기 (실제 API 체크는 GitHub CLI 또는 API 토큰 필요)
    $elapsed = 0
    while ($elapsed -lt $WaitSeconds) {
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 10
        $elapsed += 10

        if ($elapsed % 60 -eq 0) {
            Write-Host " $($elapsed/60) min" -ForegroundColor Yellow
        }
    }

    Write-Host "`n`nTime's up! Please verify the workflow status manually." -ForegroundColor Yellow
} else {
    Write-Host "`nSkipping wait. Deploy when ready." -ForegroundColor Yellow
}

Write-Host "`n[Step 4] Ready to deploy?" -ForegroundColor Yellow
Write-Host "Before deploying, make sure:" -ForegroundColor Magenta
Write-Host "  1. GitHub Actions workflow completed successfully" -ForegroundColor White
Write-Host "  2. Docker images are pushed to GHCR with 'develop-latest' tag" -ForegroundColor White
Write-Host "  3. No errors in the workflow logs" -ForegroundColor White

$deploy = Read-Host "`nProceed with deployment? (y/N)"

if ($deploy -eq 'y' -or $deploy -eq 'Y') {
    Write-Host "`n=========================================================" -ForegroundColor Green
    Write-Host "   Starting Deployment" -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Green

    Set-Location C:\intelliJ\git\pms\infra

    Write-Host "`n[5.1] Pulling latest images from GHCR..." -ForegroundColor Yellow
    docker compose --env-file env\dev.env -f docker-compose.dev.yml pull backend frontend

    Write-Host "`n[5.2] Restarting backend and frontend containers..." -ForegroundColor Yellow
    docker compose --env-file env\dev.env -f docker-compose.dev.yml up -d --force-recreate backend frontend

    Write-Host "`n[5.3] Waiting for containers to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    Write-Host "`n[5.4] Checking container status..." -ForegroundColor Yellow
    docker ps --filter "name=pms-dev" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    Write-Host "`n[5.5] Checking backend logs..." -ForegroundColor Yellow
    docker logs pms-dev-backend --tail 20

    Write-Host "`n=========================================================" -ForegroundColor Green
    Write-Host "   Deployment Complete!" -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Green

    Write-Host "`nServices:" -ForegroundColor Cyan
    Write-Host "  - Backend:  http://localhost:8180" -ForegroundColor White
    Write-Host "  - Frontend: http://localhost:8181" -ForegroundColor White
    Write-Host "  - Keycloak: http://localhost:8280" -ForegroundColor White

    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "  1. Verify Backend SSO is activated:" -ForegroundColor Yellow
    Write-Host "     docker logs pms-dev-backend | Select-String 'SecurityOidcConfig'" -ForegroundColor Gray
    Write-Host "`n  2. Test API without token (should get 401):" -ForegroundColor Yellow
    Write-Host "     curl http://localhost:8180/api/projects" -ForegroundColor Gray
    Write-Host "`n  3. Get token and test API:" -ForegroundColor Yellow
    Write-Host "     See: docs/ARCH/260116/002_Keycloak_Setup_Step_By_Step.md" -ForegroundColor Gray

} else {
    Write-Host "`nDeployment skipped." -ForegroundColor Yellow
    Write-Host "`nTo deploy manually later, run:" -ForegroundColor Cyan
    Write-Host "  cd C:\intelliJ\git\pms\infra" -ForegroundColor Gray
    Write-Host "  docker compose --env-file env\dev.env -f docker-compose.dev.yml pull" -ForegroundColor Gray
    Write-Host "  docker compose --env-file env\dev.env -f docker-compose.dev.yml up -d --force-recreate backend frontend" -ForegroundColor Gray
}

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "   Script Complete" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

